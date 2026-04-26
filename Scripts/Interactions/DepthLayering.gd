extends RefCounted
class_name DepthLayering

func setup_sprite_relative(owner: Node, sprite_name: String) -> void:
	var sprite := owner.get_node_or_null(sprite_name)
	if sprite is Sprite2D:
		sprite.z_as_relative = true
		sprite.z_index = 0


func update_depth(owner: Node2D, depth_y: float, base_offset: int = 1000) -> void:
	owner.z_index = base_offset + int(depth_y)


func get_depth_y_from_collision_shapes(owner: Node2D, shape_height_factor: float = 0.5) -> float:
	var best_y := owner.global_position.y
	var found := false

	for child in owner.get_children():
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
			half_height = (shape as RectangleShape2D).size.y * shape_height_factor
		elif shape is CapsuleShape2D:
			var cap := shape as CapsuleShape2D
			half_height = cap.height * shape_height_factor + cap.radius
		elif shape is CircleShape2D:
			half_height = (shape as CircleShape2D).radius

		var scale_y: float = abs(cs.global_scale.y)
		var bottom_y: float = cs.global_position.y + (half_height * scale_y)

		if not found or bottom_y > best_y:
			best_y = bottom_y
			found = true

	return best_y
