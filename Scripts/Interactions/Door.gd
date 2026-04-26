extends Node2D

@export var required_item_name: String = "key_zone1"
@export_file("*.tscn") var room_to_load: String
@export var spawn_point_name: String = "InitialSpawn"
@export var is_open: bool = false

@export_category("Visuel")
@export var closed_texture: Texture2D = null
@export var open_texture: Texture2D = null

@export var dialog_no_key_timeline: String = "porte_sans_clef"
@export var dialog_with_key_timeline: String = "porte_avec_clef"

@export var open_animation_name: String = "idle"
@export var open_colliders_root_path: NodePath = NodePath(".")
@export var open_colliders_names: Array[String] = ["Opened1", "Opened2"]

var _has_played_open_animation := false

@export var progress_key: String = "zone1_porte_ouverte"

func _ready() -> void:
	add_to_group("Doors")
	if Global.progress.get(progress_key, false):
		is_open = true
	update_visual_state()

func update_visual_state(play_open_animation := false) -> void:
	var visual_node := _get_door_visual_node()
	if visual_node == null:
		return

	_update_texture_if_sprite2d(visual_node)
	_update_room_switcher_state()

	if play_open_animation and is_open and not _has_played_open_animation:
		_play_open_animation_once(visual_node)

func _update_texture_if_sprite2d(visual_node: Node) -> void:
	var sprite := visual_node as Sprite2D
	if sprite == null:
		return

	if is_open:
		if open_texture != null:
			sprite.texture = open_texture
	else:
		# If no "closed" texture is provided, keep current texture.
		if closed_texture != null:
			sprite.texture = closed_texture

func _update_room_switcher_state() -> void:
	# If the door has a child Area2D (RoomSwitcher), enable it only when open.
	var rs := get_node_or_null("RoomSwitcher")
	if rs is Area2D:
		(rs as Area2D).monitoring = is_open
		(rs as Area2D).monitorable = is_open
		for c in (rs as Area2D).get_children():
			if c is CollisionShape2D:
				(c as CollisionShape2D).disabled = not is_open

func interact() -> void:
	if is_open:
		_perform_room_change()
		return

	var inventaire: Node = get_tree().get_first_node_in_group("Inventaire")
	if inventaire == null:
		return

	var joueur: Node = get_tree().get_first_node_in_group("Joueur")

	# Cas 1 : le joueur n'a pas la clé -> simple description de la porte
	if not inventaire.has_item(required_item_name, 1):
		if dialog_no_key_timeline != "":
			Dialogic.start(dialog_no_key_timeline)
			if joueur != null and "canMove" in joueur:
				joueur.canMove = false
		return

	# Cas 2 : le joueur a la clé -> dialogue \"voulez-vous utiliser la clef ?\"
	# La logique réelle d'utilisation de la clé se fait dans use_key_and_open(),
	# appelée depuis le timeline via Global.use_key_on_pending_door().
	Global.set_pending_door(self )
	if dialog_with_key_timeline != "":
		Dialogic.start(dialog_with_key_timeline)
		if joueur != null and "canMove" in joueur:
			joueur.canMove = false

func use_key_and_open() -> void:
	if is_open:
		return

	var inventaire: Node = get_tree().get_first_node_in_group("Inventaire")
	if inventaire == null:
		return

	if not inventaire.has_item(required_item_name, 1):
		return

	inventaire.remove_item(required_item_name, 1)
	is_open = true
	update_visual_state(true)

	var static_body := get_node_or_null("StaticBody2D_Door")
	if static_body is StaticBody2D:
		static_body.queue_free()

	Global.progress[progress_key] = true

	_perform_room_change()

func _perform_room_change() -> void:
	if room_to_load == "":
		return

	# Tenter de récupérer le gestionnaire de rooms
	var room_manager := get_tree().current_scene.get_node_or_null("RoomManager")
	if room_manager == null:
		room_manager = get_tree().get_first_node_in_group("RoomManager")

	if room_manager != null and room_manager.has_method("RoomChangeSpawnPoint"):
		room_manager.RoomChangeSpawnPoint(room_to_load, spawn_point_name)

func _get_door_visual_node() -> Node:
	# Prefer AnimatedSprite2D when present (open animation support).
	var animated := get_node_or_null("AnimatedSprite2D")
	if animated is AnimatedSprite2D:
		return animated

	# Fallback: most scenes use Sprite2D named "DoorSprite".
	return get_node_or_null("DoorSprite")

func _play_open_animation_once(visual_node: Node) -> void:
	var animated := visual_node as AnimatedSprite2D
	if animated == null:
		return

	_has_played_open_animation = true
	_enable_open_colliders()

	if animated.sprite_frames == null:
		return
	if not animated.sprite_frames.has_animation(open_animation_name):
		return

	animated.sprite_frames.set_animation_loop(open_animation_name, false)
	animated.play(open_animation_name)

	if not animated.animation_finished.is_connected(_on_open_animation_finished):
		animated.animation_finished.connect(_on_open_animation_finished)

func _on_open_animation_finished() -> void:
	var animated := _get_door_visual_node() as AnimatedSprite2D
	if animated == null:
		return
	if animated.sprite_frames == null:
		return
	if not animated.sprite_frames.has_animation(open_animation_name):
		return

	call_deferred("_freeze_open_last_frame")

func _freeze_open_last_frame() -> void:
	var animated := _get_door_visual_node() as AnimatedSprite2D
	if animated == null:
		return
	if animated.sprite_frames == null:
		return
	if not animated.sprite_frames.has_animation(open_animation_name):
		return

	var frame_count := animated.sprite_frames.get_frame_count(open_animation_name)
	if frame_count <= 0:
		return

	animated.stop()
	animated.set_frame_and_progress(frame_count - 1, 1.0)

func _enable_open_colliders() -> void:
	var root := get_node_or_null(open_colliders_root_path)
	if root == null:
		root = self

	for collider_name in open_colliders_names:
		var body := root.get_node_or_null(collider_name)
		if body == null:
			continue

		for child in body.get_children():
			var shape := child as CollisionShape2D
			if shape != null:
				shape.disabled = false
