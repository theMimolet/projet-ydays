extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print(ResourceLoader.exists("res://Scenes/ck-test-1.tscn"))
