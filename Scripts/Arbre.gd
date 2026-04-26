extends "res://Scripts/Interactions/PNJ.gd"

const DepthLayeringClass := preload("res://Scripts/Interactions/DepthLayering.gd")
var depth_layering := DepthLayeringClass.new()

@export var log_message: String = "Interaction avec l'arbre"

func _ready() -> void:
	super._ready()
	add_to_group("Arbres")
	depth_layering.setup_sprite_relative(self , "Arbre")


func update_depth() -> void:
	depth_layering.update_depth(self , _get_depth_y())

func _get_depth_y() -> float:
	return depth_layering.get_depth_y_from_collision_shapes(self , 0.5)
