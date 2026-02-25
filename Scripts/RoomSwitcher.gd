extends Area2D

@export_file("*.tscn") var roomToLoad: String
@export var spawnPointName : String

@onready var RoomManager : Node = get_tree().get_first_node_in_group("RoomManager")

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Joueur": 
		RoomManager.RoomChangeSpawnPoint(roomToLoad , spawnPointName)
