extends CanvasLayer

signal unloadFinished
signal unloading
signal loaded

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
	emit_signal("unloading")
	joueur.paralysePlayer(true)
	$Animateur.play("fade-out")
	if chat != null and chat.has_method("set") and chat.get("canMove") != null:
		chat.canMove = false

func roomLoad(room: String, spawnPoint: String) -> void: 
	$Animateur.play("RESET") # Écran noir
	
		# Charger la scène et vérifier qu'elle existe
	var room_resource = load(room)
	if room_resource == null:
		push_error("Impossible de charger la scène: %s" % room)
		return
	
	# Vérifier que c'est bien une PackedScene
	if not room_resource is PackedScene:
		push_error("La ressource chargée n'est pas une PackedScene: %s" % room)
		return
	
	var room_scene: PackedScene = room_resource as PackedScene
	
	# Instancier la scène et vérifier qu'elle est valide
	var room_instance: Node = room_scene.instantiate()
	if room_instance == null:
		push_error("Impossible d'instancier la scène: %s" % room)
		return
	
	rooms.add_child(room_instance) # Ajoute la nouvelle room en tant qu'enfant de "Rooms"
	Global.currentRoom = room
	
	await get_tree().process_frame
	
	# Système qui détermine si le spawnpoint visé existe ou non - sinon le joueur spawne à 0,0
	
	var spawnNode : Node2D = null
	spawnNode = rooms.find_child(spawnPoint, true, false) # Cherche récursivement si un node avec le nom recherché existe
	if spawnNode != null : 
		joueur.position = spawnNode.position
	else :
		push_warning("Spawn point '%s' non trouvé, utilisation d'un spawn par défaut" % spawnPoint)
		joueur.position = Vector2(0,0)
	
	await get_tree().process_frame
	
	if chat != null:
		chat.teleport_to_player()
	
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
			joueur.paralysePlayer(false)
			emit_signal("loaded")
			if chat != null and chat.has_method("set") and chat.get("canMove") != null:
				chat.canMove = true
