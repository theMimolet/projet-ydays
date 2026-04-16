extends Node2D

const DEFAULT_TIMELINE: String = "timeline-test"
@export var timeline: String = ""
var has_interacted: bool = false
var player: CharacterBody2D

func _ready() -> void:
	add_to_group("PNJ")

	find_player()

func find_player() -> void:
	player = get_tree().get_first_node_in_group("Joueur")
	if player == null:
		player = get_tree().current_scene.get_node_or_null("Joueur")
	if player == null:
		push_warning("PNJ: Impossible de trouver le joueur. Le z_index ne pourra pas être mis à jour.")

func _physics_process(_delta: float) -> void:
	update_depth()

func update_depth() -> void:
	const BASE_OFFSET := 1000
	z_index = BASE_OFFSET + int(global_position.y)

func interact(dialogue_override: String = "") -> void:
	if not has_interacted:
		has_interacted = true

	# Utiliser la timeline passée en paramètre, ou celle par défaut du PNJ
	var timeline_to_use: String = dialogue_override if dialogue_override != "" else timeline
	if timeline_to_use == "":
		timeline_to_use = DEFAULT_TIMELINE

	# Lancer le dialogue Dialogic
	Dialogic.start(timeline_to_use)
