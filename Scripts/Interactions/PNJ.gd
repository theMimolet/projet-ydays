extends "res://Scripts/Interactions/DialogueInteractable.gd"

const BASE_OFFSET := 1000

func _ready() -> void:
	add_to_group("PNJ")
	super._ready()

func _physics_process(_delta: float) -> void:
	update_depth()

func update_depth() -> void:
	z_index = BASE_OFFSET + int(global_position.y)
