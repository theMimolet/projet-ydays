extends "res://Scripts/Interactions/Door.gd"

@export_category("Room1")
@export var exit_switcher_path: NodePath = NodePath("../ChunkSwitcher")

const OPEN_POSE_TEXTURE := preload("res://Sprites/Porte/Vue arriere/sprite_5.webp")

var _open_pose_frame_index: int = -1
var _is_opening_anim: bool = false

func _ready() -> void:
	super._ready()
	if not is_open:
		return

	_has_played_open_animation = true
	_apply_open_pose()
	_set_exit_switcher_enabled(true)

func _process(_delta: float) -> void:
	# Keep the door visually open at all times once unlocked.
	if not is_open:
		return
	if _is_opening_anim:
		return
	_ensure_open_pose()

func interact() -> void:
	# In Room1, the door should not switch rooms via the interaction key (F).
	# The room change is handled by the room/zone switcher when the player walks through.
	if is_open:
		return
	super.interact()

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
	_is_opening_anim = true
	update_visual_state(true)
	_set_exit_switcher_enabled(false)

	var static_body := get_node_or_null("StaticBody2D_Door")
	if static_body is StaticBody2D:
		static_body.queue_free()

	Global.progress[progress_key] = true

	var animated := _get_door_visual_node() as AnimatedSprite2D
	if animated == null:
		return

	# Wait for the open animation to end, then freeze on the last frame.
	if animated.sprite_frames != null and animated.sprite_frames.has_animation(open_animation_name):
		if animated.animation != open_animation_name or not animated.is_playing():
			animated.play(open_animation_name)
		# Fallback: if the signal doesn't fire for any reason, do not leave the exit locked.
		var did_finish := false
		var on_finish := func() -> void:
			did_finish = true
		if not animated.animation_finished.is_connected(on_finish):
			animated.animation_finished.connect(on_finish, CONNECT_ONE_SHOT)

		var timeout_timer := get_tree().create_timer(1.5)
		while not did_finish and timeout_timer.time_left > 0.0:
			await get_tree().process_frame
	_apply_open_pose()
	_is_opening_anim = false
	_set_exit_switcher_enabled(true)
	# Do NOT change rooms here; walking through the exit trigger handles it in Room1.

func _apply_open_pose() -> void:
	_enable_open_colliders()
	_open_pose_frame_index = -1
	_ensure_open_pose()

func _set_exit_switcher_enabled(is_enabled: bool) -> void:
	var switcher := get_node_or_null(exit_switcher_path)
	if not (switcher is Area2D):
		return

	(switcher as Area2D).monitoring = is_enabled
	(switcher as Area2D).monitorable = is_enabled
	for c in (switcher as Area2D).get_children():
		if c is CollisionShape2D:
			(c as CollisionShape2D).disabled = not is_enabled

func _find_frame_index_for_texture(frames: SpriteFrames, anim: StringName, texture: Texture2D) -> int:
	if frames == null or texture == null:
		return -1

	var target_path := texture.resource_path
	var frame_count := frames.get_frame_count(anim)
	for i in frame_count:
		var frame_tex := frames.get_frame_texture(anim, i)
		if frame_tex == null:
			continue
		if frame_tex == texture:
			return i
		if target_path != "" and frame_tex.resource_path == target_path:
			return i

	return -1

func _ensure_open_pose() -> void:
	var animated := _get_door_visual_node() as AnimatedSprite2D
	if animated == null:
		return
	if animated.sprite_frames == null:
		return
	if not animated.sprite_frames.has_animation(open_animation_name):
		return

	# Make sure the animation won't loop/restart later.
	animated.sprite_frames.set_animation_loop(open_animation_name, false)

	if _open_pose_frame_index < 0:
		var idx := _find_frame_index_for_texture(animated.sprite_frames, open_animation_name, OPEN_POSE_TEXTURE)
		if idx < 0:
			var frame_count := animated.sprite_frames.get_frame_count(open_animation_name)
			if frame_count <= 0:
				return
			idx = frame_count - 1
		_open_pose_frame_index = idx

	if animated.is_playing() or animated.animation != open_animation_name or animated.frame != _open_pose_frame_index:
		animated.stop()
		animated.animation = open_animation_name
		animated.set_frame_and_progress(_open_pose_frame_index, 1.0)

