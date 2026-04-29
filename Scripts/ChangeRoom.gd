extends CanvasLayer

signal unloadFinished
signal unloading
signal loaded

var isLoading: bool = false

@onready var rooms: Node = $"../Room"
@onready var joueur: Node = $"../Joueur"
@onready var chat: Node2D = $"../Chat"

func _ready() -> void:
	# Retour de combat : charger la room où le joueur était + sa position exacte
	
		RoomLoadToCoords("res://Scenes/Rooms/Zone1/Jardin.tscn", 0.0, 0.0)

func AreRoomsLoaded() -> bool:
	return rooms.get_child_count() > 0

func RoomChangeSpawnPoint(newRoom: String, spawnPoint: String) -> void:
	if isLoading: return
	print("Salle : " + newRoom + "\nPoint d'apparition : " + spawnPoint)
	RoomUnload()
	await unloadFinished
	RoomLoadToSpawnPoint(newRoom, spawnPoint)

func RoomChangeCoords(newRoom: String, targetX: float, targetY: float) -> void:
	if isLoading: return
	print("Salle : " + newRoom + "\nX:" + str(targetX) + "\nY:" + str(targetY))
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
	# Arrêter les timers et signaux des anciennes rooms
	_cleanup_old_rooms()

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

func RoomLoadToSpawnPoint(room: String, spawnPoint: String) -> void:
	if not await RoomToLoad(room): return

	# Système qui détermine si le spawnpoint visé existe ou non - sinon le joueur spawne à 0,0

	var spawnNode: Node2D = null
	spawnNode = rooms.find_child(spawnPoint, true, false) # Cherche récursivement si un node avec le nom recherché existe
	# Note de Samuel : il n'y a pas de positions locales aux rooms, on a toujours utilisé des positions globales
	if spawnNode != null:
		joueur.position = spawnNode.position
	else:
		push_warning("Spawn point '%s' non trouvé, utilisation d'un spawn par défaut" % spawnPoint)
		joueur.position = Vector2(0, 0)

	FinishRoomLoad()

func RoomLoadToCoords(room: String, targetX: float, targetY: float) -> void:
	if not await RoomToLoad(room): return
	# Interpréter les coords comme des coordonnées globales (cohérent avec les spawnpoints)
	joueur.global_position = Vector2(targetX, targetY)
	FinishRoomLoad()

func _on_animateur_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		"fade-out":
			$Animateur.play("RESET")
			# Décharger complètement les anciennes rooms
			for child in rooms.get_children():
				_free_node_recursive(child)
			# S'assurer que tout est bien nettoyé
			await get_tree().process_frame
			emit_signal("unloadFinished")
		"fade-in":
			joueur.paralysePlayer(false)
			if Global.pending_new_game_save != "":
				var new_game_save: String = Global.pending_new_game_save
				Global.pending_new_game_save = ""
				SaveSystem.SaveToFile(new_game_save)
			emit_signal("loaded")
			if chat != null:
				chat.canMove = true
			isLoading = false

# ============== UTILITAIRES DE NETTOYAGE ==============

func _cleanup_old_rooms() -> void:
	"""Arrête les timers et déconnecte les signaux des nodes en attente de suppression"""
	for child in rooms.get_children():
		_disconnect_node_signals(child)

func _disconnect_node_signals(node: Node) -> void:
	"""Arrête les processus actifs d'un node (timers, animations, etc.)"""
	if not is_instance_valid(node):
		return

	# Arrêter les timers
	if node is Timer:
		node.stop()

	# Arrêter les animations
	if node is AnimatedSprite2D:
		node.stop()

	# Récursif pour les enfants
	for child in node.get_children():
		_disconnect_node_signals(child)

func _free_node_recursive(node: Node) -> void:
	"""Supprime complètement un node et tous ses enfants"""
	if not is_instance_valid(node):
		return

	# Nettoyer les signaux d'abord
	_disconnect_node_signals(node)

	# Supprimer les enfants d'abord
	for child in node.get_children():
		_free_node_recursive(child)

	# Enfin, libérer le node lui-même
	node.queue_free()
