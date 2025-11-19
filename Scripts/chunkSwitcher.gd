extends Area2D

@export_file("*.tscn") var chunkToLoad: String
@export var playerSpawn : Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Joueur": 
		$"../../../ChunkManager".chunkChange(chunkToLoad, playerSpawn)
