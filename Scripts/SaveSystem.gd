extends Node

# Viens de https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html

var tempSave: Dictionary
@export var defaultName: String = "quicksave"

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Debug_Save"):
		SaveToFile()
	if event.is_action_pressed("Debug_Load"):
		LoadFromFile("quicksave")
	if event.is_action_pressed("Debug_List"):
		print("Fichiers de sauvegarde:")
		for save in ListSaves():
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

func DeleteSave(requestedSave: String) -> void:
	var filePath := "user://" + requestedSave + ".save"
	if FileAccess.file_exists(filePath):
		var access: FileAccess = FileAccess.open(filePath, FileAccess.WRITE)
		var err: int = access.remove(filePath)
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
		"current_inventory": joueur.inventory.slots,
		"current_scene": Global.currentRoom
	}
	return saveDict

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
	var jsonString := saveFile.get_line()
	var json := JSON.new()

	# Check if there is any error while parsing the JSON string, skip in case of failure.
	var parseResult := json.parse(jsonString)
	if not parseResult == OK:
		print("JSON Parse Error: ", json.get_error_message(), " in ", jsonString, " at line ", json.get_error_line())
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
	joueur.inventory.slots = nodeData["current_inventory"]
	if RoomManager.AreRoomsLoaded():
		RoomManager.RoomChangeCoords(nodeData["current_scene"], nodeData["player_pos_x"], nodeData["player_pos_y"])
	else:
		RoomManager.RoomLoadToCoords(nodeData["current_scene"], nodeData["player_pos_x"], nodeData["player_pos_y"])
	print("Chargement effectué")
