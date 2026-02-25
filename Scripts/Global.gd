extends Node

@export var currentRoom : String

var pending_door : Node = null

func _ready() -> void:
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R and (event.ctrl_pressed or event.meta_pressed):
			reset_scene()

func reset_scene() -> void:
	get_tree().reload_current_scene()

func set_pending_door(door: Node) -> void:
	pending_door = door

func use_key_on_pending_door() -> void:
	if pending_door != null and pending_door.is_inside_tree() and pending_door.has_method("use_key_and_open"):
		pending_door.use_key_and_open()
	pending_door = null
