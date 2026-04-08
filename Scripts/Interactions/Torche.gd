extends Sprite2D

signal torch_lit

@export var required_item: String = "briqué"

var is_lit: bool = false

func _ready() -> void:
	add_to_group("Torches")
	if Global.get_flag("couloir_torches_allumees"):
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
	is_lit = true
	visible = false

	var anim_sprite := AnimatedSprite2D.new()
	anim_sprite.sprite_frames = _build_torch_frames()
	anim_sprite.animation = &"default"
	anim_sprite.autoplay = "default"
	get_parent().add_child(anim_sprite)
	anim_sprite.global_position = global_position
	anim_sprite.play()

	if emit:
		torch_lit.emit()


func _build_torch_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(&"default")
	frames.set_animation_speed(&"default", 5.0)
	frames.set_animation_loop(&"default", true)
	for i: int in range(5):
		var tex: Texture2D = load("res://Spritesheet/Torche/sprite_torche%d.png" % i)
		if tex != null:
			frames.add_frame(&"default", tex)
	return frames
