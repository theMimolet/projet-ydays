extends CanvasLayer

signal unloadFinished
signal unloading
signal loaded

var isLoading : bool = false

@onready var rooms : Node = $"../Room" 
@onready var joueur : Node = $"../Joueur"
@onready var chat : Node2D = $"../Chat" 

func _ready() -> void:
	RoomLoadToSpawnPoint("res://Scenes/Rooms/Zone1/Couloir.tscn", "InitialSpawn")
	# SaveSystem.LoadFromFile()

func AreRoomsLoaded() -> bool:
	print(rooms.get_child_count() > 0)
	return rooms.get_child_count() > 0

func RoomChangeSpawnPoint(newRoom: String, spawnPoint: String) -> void:
	if isLoading : return
	print("Salle : "+newRoom+"\nPoint d'apparition : " + spawnPoint)
	RoomUnload()
	await unloadFinished
	RoomLoadToSpawnPoint(newRoom, spawnPoint)

func RoomChangeCoords(newRoom: String, targetX: float, targetY: float) -> void:
	if isLoading : return
	print("Salle : "+ newRoom +"\nX:" + str(targetX) + "\nY:" + str(targetY))
	RoomUnload()
	await unloadFinished
	RoomLoadToCoords(newRoom, targetX, targetY)

func RoomUnload() -> void:
	isLoading = true
	emit_signal("unloading")
	joueur.paralysePlayer(true)
	$Animateur.play("fade-out")
	if chat != null:
		chat.canMove = false

func RoomToLoad(room: String) -> bool: 
	$Animateur.play("RESET") # Écran noir
	isLoading = true
	
	# Charger la scène et vérifier qu'elle existe
	
	var roomScene: PackedScene = load(room)
	if roomScene == null:
		push_error("Impossible de charger la scène: %s" % room)
		isLoading = false
		return false
	
	# Instancier la scène et vérifier qu'elle est valide
	var roomInstance: Node = roomScene.instantiate()
	if roomInstance == null:
		push_error("Impossible d'instancier la scène: %s" % room)
		isLoading = false
		return false
	
	rooms.add_child(roomInstance) # Ajoute la nouvelle room en tant qu'enfant de "Rooms"
	Global.currentRoom = room
	
	await get_tree().process_frame
	
	return true

func FinishRoomLoad() -> void:
	await get_tree().process_frame
	if chat != null:
		chat.teleport_to_player()
	$Animateur.play("fade-in")

func RoomLoadToSpawnPoint(room: String, spawnPoint: String) -> void :
	if not await RoomToLoad(room): return
	
	# Système qui détermine si le spawnpoint visé existe ou non - sinon le joueur spawne à 0,0
	
	var spawnNode : Node2D = null
	spawnNode = rooms.find_child(spawnPoint, true, false) # Cherche récursivement si un node avec le nom recherché existe
	if spawnNode != null : 
		# IMPORTANT: spawnNode.position est local à la room, alors que le joueur n'est pas enfant de la room.
		# On utilise les coordonnées globales pour être sûr d'arriver au bon endroit.
		joueur.global_position = spawnNode.global_position
	else :
		push_warning("Spawn point '%s' non trouvé, utilisation d'un spawn par défaut" % spawnPoint)
		joueur.global_position = Vector2(0,0)
	
	FinishRoomLoad()

func RoomLoadToCoords(room: String, targetX: float, targetY: float) -> void :
	if not await RoomToLoad(room): return
	# Interpréter les coords comme des coordonnées globales (cohérent avec les spawnpoints)
	joueur.global_position = Vector2(targetX, targetY)
	FinishRoomLoad()

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
			if chat != null :
				chat.canMove = true
			isLoading = false


# ============== ALIAS / COMPAT ==============
# Certaines scènes/scripts (portes, console) appellent encore roomChange(...).
# On redirige vers les méthodes actuelles pour éviter des comportements différents "dans l'autre sens".

func roomChange(newRoom: String, spawnPoint: String = "InitialSpawn") -> void:
	RoomChangeSpawnPoint(newRoom, spawnPoint)

func roomChangeCoords(newRoom: String, targetX: float, targetY: float) -> void:
	RoomChangeCoords(newRoom, targetX, targetY)
