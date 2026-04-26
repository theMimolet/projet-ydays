extends "res://Scripts/Interactions/DialogueInteractable.gd"

const BASE_OFFSET := 1000
const DEFAULT_PNJ_TIMELINE := "timeline-test"

func _ready() -> void:
	if default_timeline == "":
		default_timeline = DEFAULT_PNJ_TIMELINE
	super._ready()

func _physics_process(_delta: float) -> void:
	update_depth()

func update_depth() -> void:
	z_index = BASE_OFFSET + int(global_position.y)
