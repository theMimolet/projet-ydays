extends Node

@export var currentRoom : String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _input(event: InputEvent) -> void:
	# Détecter Ctrl+R pour reset rapide de la scène
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R and (event.ctrl_pressed or event.meta_pressed):
			# Meta = Cmd sur Mac, Ctrl sur Windows/Linux
			reset_scene()

func reset_scene() -> void:
	# Recharger la scène actuelle
	get_tree().reload_current_scene()
