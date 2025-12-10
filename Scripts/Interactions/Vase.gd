extends RefCounted

static func interact(cell_position: Vector2i) -> void:
	print("Interaction avec le vase à la position: ", cell_position)
	Dialogic.start("timeline-test")
