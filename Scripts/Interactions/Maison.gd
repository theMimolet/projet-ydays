extends "res://Scripts/Interactions/PNJ.gd"

@export var log_message: String = "Interaction avec la maison"
@export var depth_marker_path: NodePath = NodePath("DepthPoint")
@export var depth_y_offset: float = -50.0

@export_file("*.tscn") var interior_room_path: String = ""
@export var return_spawn_point_name: String = ""

func _ready() -> void:
	super._ready()
	add_to_group("Maisons")
	
	for child in get_children():
		if child is Sprite2D:
			var sprite := child as Sprite2D
			sprite.z_as_relative = true
			sprite.z_index = 0
			break

func interact(dialogue_override: String = "") -> void:
	if interior_room_path != "":
		Global.set_pending_maison(interior_room_path, return_spawn_point_name)
	super.interact(dialogue_override)

func update_depth() -> void:
	const BASE_OFFSET := 1000
	z_index = BASE_OFFSET + int(_get_depth_y())

func _get_depth_y() -> float:
	var marker := get_node_or_null(depth_marker_path)
	if marker is Node2D:
		return (marker as Node2D).global_position.y + depth_y_offset
	
	var best_y := global_position.y
	var found := false
	
	for child in get_children():
		if child is CollisionPolygon2D:
			var poly := child as CollisionPolygon2D
			if poly.disabled:
				continue
			
			for p in poly.polygon:
				var gp := poly.to_global(p)
				if not found or gp.y > best_y:
					best_y = gp.y
					found = true
			continue
		
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
			half_height = (shape as RectangleShape2D).size.y * 0.1
		elif shape is CapsuleShape2D:
			var cap := shape as CapsuleShape2D
			half_height = cap.height * 0.1 + cap.radius
		elif shape is CircleShape2D:
			half_height = (shape as CircleShape2D).radius
		
		var scale_y: float = abs(cs.global_scale.y)
		var bottom_y: float = cs.global_position.y + (half_height * scale_y)
		
		if not found or bottom_y > best_y:
			best_y = bottom_y
			found = true
	
	return best_y
