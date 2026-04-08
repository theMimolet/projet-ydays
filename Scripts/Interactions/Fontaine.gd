extends "res://Scripts/Interactions/PNJ.gd"

@export var log_message: String = "Interaction avec la fontaine"
@export var dialog_timeline: String = "timeline_save"

func _ready() -> void:
	super._ready()
	add_to_group("Fontaines")
	
	var sprite := get_node_or_null("Fontaine")
	if sprite is Sprite2D:
		sprite.z_as_relative = true
		sprite.z_index = 0

func interact(_timeline: String = "") -> void:
	print(log_message)
	super.interact(dialog_timeline)

func update_depth() -> void:
	const BASE_OFFSET := 1000
	z_index = BASE_OFFSET + int(_get_depth_y())

func _get_depth_y() -> float:
	var best_y := global_position.y
	var found := false
	
	for child in get_children():
		if not (child is CollisionShape2D):
			continue
		
		var cs := child as CollisionShape2D
		if cs.disabled:
			continue
		
		var shape := cs.shape
		if shape == null:
			continue
		
		var half_height := 0.0
		if shape is RectangleShape2D:
			half_height = (shape as RectangleShape2D).size.y * 0.5
		elif shape is CapsuleShape2D:
			var cap := shape as CapsuleShape2D
			half_height = cap.height * 0.5 + cap.radius
		elif shape is CircleShape2D:
			half_height = (shape as CircleShape2D).radius
		
		var scale_y: float = abs(cs.global_scale.y)
		var bottom_y: float = cs.global_position.y + (half_height * scale_y)
		
		if not found or bottom_y > best_y:
			best_y = bottom_y
			found = true
	
	return best_y
