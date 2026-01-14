extends CanvasLayer

signal unloadFinished

@onready var rooms : Node = $"../Room" 
@onready var joueur : Node = $"../Joueur"
@onready var chat : Node2D = $"../Chat" 

func _ready() -> void:
	roomLoad("res://Scenes/Rooms/Test1.tscn", "InitialSpawn")

func roomChange(newRoom: String) -> void:
	var previousRoomName : String = rooms.get_child(0).name
	print(previousRoomName)
	roomUnload()
	await unloadFinished
	roomLoad(newRoom, previousRoomName)

func roomUnload() -> void:
	$Animateur.play("fade-out")
	joueur.canMove = false
	if chat != null and chat.has_method("set") and chat.get("canMove") != null:
		chat.canMove = false

func roomLoad(room: String, spawnPoint: String) -> void: 
	$Animateur.play("RESET") # Écran noir
	
	rooms.add_child(load(room).instantiate()) # Charge la nouvelle room et l'instantie en tant qu'enfant de "Rooms"
	Global.currentRoom = room
	
	await get_tree().process_frame
	
	# Système qui détermine si le spawnpoint visé existe ou non - sinon le joueur spawne à 0,0
	
	var spawnNode : Node2D = null
	spawnNode = rooms.find_child(spawnPoint, true, false) # Cherche récursivement si un node avec le nom recherché existe
	if spawnNode != null : 
		joueur.position = spawnNode.position
		if chat != null:
			chat.position = spawnNode.position
	else :
		push_warning("Spawn point '%s' non trouvé, utilisation d'un spawn par défaut" % spawnPoint)
		joueur.position = Vector2(0,0)
		if chat != null:
			chat.position = Vector2(0,0)
	
	$Animateur.play("fade-in")

func _on_animateur_animation_finished(anim_name: StringName) -> void:
	match anim_name :
		"fade-out" :
			$Animateur.play("RESET")
			for child in rooms.get_children() :
				child.queue_free()
				child = null
			emit_signal("unloadFinished")
		"fade-in" :
			joueur.canMove = true
			if chat != null and chat.has_method("set") and chat.get("canMove") != null:
				chat.canMove = true