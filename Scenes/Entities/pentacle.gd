extends Node2D

@export var dialogue_timeline: String = "timeline_symbole"

func _ready() -> void:
	add_to_group("PNJ")

func interact() -> void:
	if dialogue_timeline != "":
		Dialogic.start(dialogue_timeline)
	
	var joueur: Node = get_tree().get_first_node_in_group("Joueur")
	if joueur != null and "canMove" in joueur:
		joueur.canMove = false
