extends Node2D

@export var timeline: String = ""
@export var dialogue_timeline: String = ""
const DEFAULT_TIMELINE: String = "default"
@export var lock_player_during_dialogue: bool = true

var has_interacted: bool = false
var _player: CharacterBody2D = null

func _ready() -> void:
	add_to_group("PNJ")

func interact(dialogue_override: String = "") -> void:
	if not has_interacted:
		has_interacted = true

	var timeline_to_use := _resolve_timeline(dialogue_override)
	if timeline_to_use != "":
		Dialogic.start(timeline_to_use)

	if lock_player_during_dialogue:
		_lock_player_movement()

func _resolve_timeline(dialogue_override: String) -> String:
	if dialogue_override != "":
		return dialogue_override
	if dialogue_timeline != "":
		return dialogue_timeline
	if timeline != "":
		return timeline
	return DEFAULT_TIMELINE

func _find_player() -> CharacterBody2D:
	var player := get_tree().get_first_node_in_group("Joueur") as CharacterBody2D
	if player == null:
		player = get_tree().current_scene.get_node_or_null("Joueur") as CharacterBody2D
	return player

func _lock_player_movement() -> void:
	if _player == null or not is_instance_valid(_player):
		_player = _find_player()
	if _player != null and "canMove" in _player:
		_player.canMove = false
