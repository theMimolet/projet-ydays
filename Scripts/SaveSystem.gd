extends Node

# Viens de https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html

var tempSave: Dictionary
@export var defaultName: String = "quicksave"

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("DebugSave"):
		SaveToFile()
	if event.is_action_pressed("DebugLoad"):
		LoadFromFile("quicksave")
	if event.is_action_pressed("DebugList"):
		print("Fichiers de sauvegarde:")
		for save: String in ListSaves():
			print(" - ", save)

func ListSaves() -> Array:
	var saves := []
	var dir := DirAccess.open("user://")
	if dir == null:
		push_error("Impossible d'ouvrir le répertoire de sauvegarde!")
		return saves
	dir.list_dir_begin()
	var fileName := dir.get_next()
	while fileName != "":
		if fileName.ends_with(".save"):
			saves.append(fileName.substr(0, fileName.length() - 5)) # Remove .save extension
		fileName = dir.get_next()
	dir.list_dir_end()
	return saves

func GetNextGenericSaveName(prefix: String = "Partie") -> String:
	var index: int = 1
	var saveName: String = "%s %d" % [prefix, index]

	while FileAccess.file_exists("user://%s.save" % saveName):
		index += 1
		saveName = "%s %d" % [prefix, index]

	return saveName

func GetNextRoomSaveName(room_path: String = "") -> String:
	var room_name: String = room_path
	if room_name == "":
		room_name = Global.currentRoom
	if room_name == "":
		var current_scene := get_tree().current_scene
		if current_scene != null:
			room_name = current_scene.scene_file_path

	if room_name == "":
		room_name = "Save"
	elif room_name.contains("://"):
		room_name = room_name.get_file().get_basename()

	return GetNextGenericSaveName(room_name)

func ListSavesMostRecentFirst() -> Array:
	var saves := ListSaves()
	var enriched: Array = []
	for save_name: String in saves:
		var file_path := "user://%s.save" % save_name
		enriched.append({
			"name": save_name,
			"mtime": FileAccess.get_modified_time(file_path)
		})

	enriched.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("mtime", 0)) > int(b.get("mtime", 0))
	)

	var ordered: Array = []
	for entry: Dictionary in enriched:
		ordered.append(entry.get("name", ""))

	return ordered

func DeleteSave(requestedSave: String) -> void:
	var fileName := requestedSave + ".save"
	var filePath := "user://" + fileName
	if FileAccess.file_exists(filePath):
		var dir := DirAccess.open("user://")
		if dir == null:
			push_error("Impossible d'ouvrir le répertoire de sauvegarde!")
			return
		var err: int = dir.remove(fileName)
		if err != OK:
			push_error("Erreur lors de la suppression du fichier de sauvegarde: %s" % filePath)
		else:
			print("Fichier de sauvegarde supprimé: ", requestedSave)
	else:
		print("Aucun fichier de sauvegarde trouvé avec le nom: ", requestedSave)

func getSave() -> Dictionary:
	var joueur: CharacterBody2D = get_tree().get_first_node_in_group("Joueur")
	var saveDict := {
		"player_pos_x": joueur.position.x,
		"player_pos_y": joueur.position.y,
		"current_health": joueur.currentHP,
		"current_inventory" : _serialize_inventory(joueur.inventory),
		"current_scene": Global.currentRoom
    "progress": Global.progress
	}
	return saveDict

func _serialize_inventory(inventaire: Node) -> Array:
	"""Sérialise le contenu des slots (pas les nodes eux-mêmes)"""
	var data: Array = []
	if inventaire == null or not "slots" in inventaire:
		return data
	for slot in inventaire.slots:
		if slot is Object and slot.has_method("is_empty") and not slot.is_empty():
			data.append({
				"item_name": slot.item.item_name if "item_name" in slot.item else "",
				"quantity": slot.quantity,
				"slot_index": slot.slot_index if "slot_index" in slot else -1,
			})
		else:
			data.append(null)
	return data
    
func SaveToFile(requestedSave: String = "") -> void:
	if requestedSave == "":
		requestedSave = defaultName
	var saveFile := FileAccess.open("user://" + requestedSave + ".save", FileAccess.WRITE)
	if saveFile == null:
		push_error("N'a pas pu ouvrir le fichier de sauvegarde!")
		return
	var data: Dictionary = getSave()
	print("Données récupérées")
	var jsonString := JSON.stringify(data)
	saveFile.store_line(jsonString)
	saveFile.close()
	print("Fichier de sauvegarde créé")

func SaveLite() -> void:
	tempSave = getSave()
	print("Sauvegarde légère effectuée")

func LoadFromFile(requestedSave: String = "") -> void:
	print("Chargement en cours...")
	if requestedSave == "":
		requestedSave = defaultName
	if not FileAccess.file_exists("user://" + requestedSave + ".save"):
		print("Aucun fichier de sauvegarde trouvé avec le nom: ", requestedSave)
		return

	var saveFile := FileAccess.open("user://" + requestedSave + ".save", FileAccess.READ)
	if saveFile == null:
		push_error("N'a pas pu ouvrir le fichier de sauvegarde!")
		return
	var jsonString := saveFile.get_line()
	var json := JSON.new()

	# Check if there is any error while parsing the JSON string, skip in case of failure.
	var parseResult := json.parse(jsonString)
	if not parseResult == OK:
		print("JSON Parse Error: ", json.get_error_message(), " in ", jsonString, " at line ", json.get_error_line())
		saveFile.close()
		return

	saveFile.close()
	print("Fichier de sauvegarde récupéré")

	var nodeData: Dictionary = json.data

	ApplyData(nodeData)

func LoadLite() -> void:
	ApplyData(tempSave)

func ApplyData(nodeData: Dictionary) -> void:
	var joueur: Node = get_tree().get_first_node_in_group("Joueur")
	var RoomManager: Node = get_tree().get_first_node_in_group("RoomManager")
	joueur.currentHP = nodeData["current_health"]
	if nodeData.has("progress") and nodeData["progress"] is Dictionary:
		for key: String in Global.progress.keys():
			Global.progress[key] = nodeData["progress"].get(key, Global.progress[key])

	# Ne plus écraser slots — la restauration d'inventaire complet nécessite
	# un système de sérialisation des ressources Item (à implémenter plus tard).
	# Pour l'instant on ne restaure pas l'inventaire depuis le fichier de sauvegarde
	# afin de ne pas corrompre le tableau de slots.

  # joueur.inventory.slots = nodeData["current_inventory"]

  if RoomManager.AreRoomsLoaded():
		RoomManager.RoomChangeCoords(nodeData["current_scene"], nodeData["player_pos_x"], nodeData["player_pos_y"])
	else:
		RoomManager.RoomLoadToCoords(nodeData["current_scene"], nodeData["player_pos_x"], nodeData["player_pos_y"])
	print("Chargement effectué")
