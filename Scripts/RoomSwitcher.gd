extends Area2D

@export_file("*.tscn") var roomToLoad: String
@export var playerSpawn : Vector2

func _ready() -> void:
	pass # Replace with function body.

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Joueur": 
		$"../../../RoomManager".roomChange(roomToLoad, playerSpawn)
