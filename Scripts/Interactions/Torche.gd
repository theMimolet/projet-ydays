extends Sprite2D

signal torch_lit

const FLAME_NODE_PREFIX := "TorchFlame_"

@export var required_item: String = "briqué"

var is_lit: bool = false


func _ready() -> void:
	add_to_group("Torches")
	if Global.get_flag("couloir_torches_allumees"):
		_allumer(false)


func ensure_lit_visual() -> void:
	if not Global.get_flag("couloir_torches_allumees") and not is_lit:
		return
	_allumer(false)


func interact() -> void:
	if is_lit:
		return

	var inventaire: Node = get_tree().get_first_node_in_group("Inventaire")
	if inventaire == null:
		return
	if not inventaire.has_method("has_item") or not inventaire.has_item(required_item, 1):
		return

	_allumer(true)


func _allumer(emit: bool) -> void:
	if is_lit and _get_flame_node() != null:
		if emit:
			torch_lit.emit()
		return

	is_lit = true
	visible = false
	_remove_flame_if_any()

	var anim_sprite := AnimatedSprite2D.new()
	anim_sprite.name = _get_flame_node_name()
	anim_sprite.sprite_frames = _build_torch_frames()
	anim_sprite.animation = &"default"
	anim_sprite.autoplay = "default"
	anim_sprite.z_index = z_index + 1
	get_parent().add_child(anim_sprite)
	anim_sprite.global_position = global_position
	anim_sprite.play()

	if emit:
		torch_lit.emit()


func _remove_flame_if_any() -> void:
	var existing: Node = _get_flame_node()
	if existing != null:
		existing.queue_free()


func _get_flame_node() -> Node:
	var parent := get_parent()
	if parent == null:
		return null
	return parent.get_node_or_null(_get_flame_node_name())


func _get_flame_node_name() -> String:
	return FLAME_NODE_PREFIX + str(get_instance_id())


func _build_torch_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(&"default")
	frames.set_animation_speed(&"default", 5.0)
	frames.set_animation_loop(&"default", true)
	for i: int in range(5):
		var tex: Texture2D = load("res://Sprites/Torche/sprite_torche%d.png" % i)
		if tex != null:
			frames.add_frame(&"default", tex)
	return frames
