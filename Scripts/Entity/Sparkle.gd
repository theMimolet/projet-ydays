extends "res://Scripts/Interactions/DialogueInteractable.gd"

@export var save_prompt_timeline: String = "timeline_sparkle_save"
@export var save_only_once: bool = false

var _already_saved: bool = false

func _ready() -> void:
	super._ready()
	$AnimatedSprite2D.play("default")

func interact(dialogue_override: String = "") -> void:
	if save_only_once and _already_saved:
		return

	Global.current_sparkle = self
	var timeline_to_use := dialogue_override if dialogue_override != "" else save_prompt_timeline
	super.interact(timeline_to_use)


func save_game() -> void:
	if save_only_once and _already_saved:
		return

	SaveSystem.SaveToFile(SaveSystem.GetNextRoomSaveName())

	_already_saved = true
	if Global.current_sparkle == self:
		Global.current_sparkle = null
