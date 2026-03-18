extends CharacterBody2D

const SPEED = 35.0
const FOLLOW_DISTANCE = 32.0
const MIN_DISTANCE = 17.0
const FOLLOW_SPEED_MULTIPLIER = 1.2
const TELEPORT_DISTANCE = 150.0
const TELEPORT_OFFSET = 40.0

var player: CharacterBody2D
var is_following: bool = true
var canMove: bool = true
var is_teleporting: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

const ANIM_IDLE_OFF := "off-idle"
const ANIM_IDLE_ON := "on-idle"
const ANIM_WALK_DOWN_OFF := "off-marche - bas"
const ANIM_WALK_LEFT_OFF := "off-marche - gauche"
const ANIM_WALK_RIGHT_OFF := "off-marche - droit"
const ANIM_WALK_DOWN_ON := "on-marche - bas"
const ANIM_WALK_LEFT_ON := "on-marche - gauche"
const ANIM_WALK_RIGHT_ON := "on-marche - droit"
const ANIM_WALK_UP := "marche - dos"

@export var isOn: bool = true:
	set(value):
		isOn = value
		_update_animation(velocity)

func _ready() -> void:
	find_player()
	_update_animation(Vector2.ZERO)

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
		_update_animation(Vector2.ZERO)
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
	_update_animation(velocity)
	update_depth()

func update_depth() -> void:
	const BASE_OFFSET := 1000
	z_index = BASE_OFFSET + int(global_position.y) + 10

func teleport_to_player() -> void:
	if is_teleporting or player == null:
		return
	
	is_teleporting = true
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

func _update_animation(current_velocity: Vector2) -> void:
	if sprite == null:
		return
	if is_teleporting:
		return

	var is_moving := current_velocity.length_squared() > 0.001
	if not is_moving:
		_play_if_changed(ANIM_IDLE_ON if isOn else ANIM_IDLE_OFF)
		return

	# Pick a direction based on the dominant axis.
	var abs_x := absf(current_velocity.x)
	var abs_y := absf(current_velocity.y)
	if abs_y >= abs_x:
		if current_velocity.y < 0.0:
			_play_if_changed(ANIM_WALK_UP)
		else:
			_play_if_changed(ANIM_WALK_DOWN_ON if isOn else ANIM_WALK_DOWN_OFF)
	else:
		if current_velocity.x < 0.0:
			_play_if_changed(ANIM_WALK_LEFT_ON if isOn else ANIM_WALK_LEFT_OFF)
		else:
			_play_if_changed(ANIM_WALK_RIGHT_ON if isOn else ANIM_WALK_RIGHT_OFF)

func _play_if_changed(animation_name: String) -> void:
	if sprite.animation == animation_name and sprite.is_playing():
		return
	if sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(animation_name):
		push_warning("Chat: animation manquante: %s" % animation_name)
		return
	sprite.play(animation_name)
