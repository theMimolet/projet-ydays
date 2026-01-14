extends CharacterBody2D

const SPEED = 35.0
const FOLLOW_DISTANCE = 32.0
const MIN_DISTANCE = 16.0
const FOLLOW_SPEED_MULTIPLIER = 1.2
const TELEPORT_DISTANCE = 150.0
const TELEPORT_OFFSET = 40.0

var player: CharacterBody2D
var is_following: bool = true
var canMove: bool = true
var is_teleporting: bool = false

func _ready() -> void:
	find_player()

func find_player() -> void:
	player = get_tree().get_first_node_in_group("player")
	if player == null:
		player = get_node_or_null("../Joueur")
	if player == null:
		player = get_tree().current_scene.get_node_or_null("Joueur")
	if player == null:
		push_warning("Chat: Impossible de trouver le joueur. Le chat ne pourra pas suivre.")
		is_following = false

func _physics_process(delta: float) -> void:
	if not is_following or player == null or not canMove:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	var direction_to_player := (player.global_position - global_position)
	var distance_to_player := direction_to_player.length()
	
	if distance_to_player > TELEPORT_DISTANCE and not is_teleporting:
		teleport_to_player()
		return
	
	if distance_to_player > FOLLOW_DISTANCE:
		var normalized_direction := direction_to_player.normalized()
		velocity = normalized_direction * SPEED * FOLLOW_SPEED_MULTIPLIER
	elif distance_to_player < MIN_DISTANCE:
		var normalized_direction := -direction_to_player.normalized()
		velocity = normalized_direction * SPEED * 0.5
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED * delta)
	
	move_and_slide()
	update_depth()

func update_depth() -> void:
	if player == null:
		return
	
	const BASE_Z_INDEX := 10
	
	if player.z_index == 0:
		player.z_index = BASE_Z_INDEX
	
	if global_position.y < player.global_position.y:
		z_index = BASE_Z_INDEX - 1
	else:
		z_index = BASE_Z_INDEX + 1
	
	z_index = max(z_index, 1)

func teleport_to_player() -> void:
	if is_teleporting or player == null:
		return
	
	is_teleporting = true
	var sprite := get_node_or_null("AnimatedSprite2D")
	var direction := (player.global_position - global_position).normalized()
	var teleport_pos := player.global_position - direction * TELEPORT_OFFSET
	
	if sprite != null:
		var tween := create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.1)
		await tween.finished
	
	global_position = teleport_pos
	
	if sprite != null:
		sprite.scale = Vector2(1.3, 1.3)
		var tween := create_tween()
		tween.tween_property(sprite, "modulate:a", 1.0, 0.15)
		tween.parallel().tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.15)
	
	is_teleporting = false