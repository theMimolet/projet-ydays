extends Node

# Viens de https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html

var tempSave : Dictionary

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Debug_Save"):
		SaveToFile()
	if event.is_action_pressed("Debug_Load"):
		LoadLite()

func getSave() -> Dictionary:
	
	var joueur: CharacterBody2D = get_tree().get_first_node_in_group("Joueur")
	
	var save_dict := {
		"player_pos_x" : joueur.position.x,
		"player_pos_y" : joueur.position.y,
		"current_health" : joueur.currentHP,
		"current_inventory" : _serialize_inventory(joueur.inventory),
		"current_scene" : Global.currentRoom
	}
	return save_dict


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

func SaveToFile() -> void:
	var save_file := FileAccess.open("user://savegame.save", FileAccess.WRITE)
	if save_file == null:
		push_error("Could not open save file!")
		return
	var data : Dictionary = getSave()
	print("Données récupérées")
	var json_string := JSON.stringify(data)
	save_file.store_line(json_string)
	save_file.close()
	print("Fichier de sauvegarde créé")

func SaveLite() -> void: 
	tempSave = getSave()
	print("Sauvegarde légère effectuée")

func LoadFromFile() -> void:
	print("Chargement en cours")
	if not FileAccess.file_exists("user://savegame.save"):
		return

	var save_file := FileAccess.open("user://savegame.save", FileAccess.READ)
	var json_string := save_file.get_line()
	var json := JSON.new()

	# Check if there is any error while parsing the JSON string, skip in case of failure.
	var parse_result := json.parse(json_string)
	if not parse_result == OK:
		print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
		return

	save_file.close()
	print("Fichier de sauvegarde récupéré")

	var node_data : Dictionary = json.data
	
	ApplyData(node_data)

func LoadLite() -> void : 
	ApplyData(tempSave)

func ApplyData(node_data : Dictionary) -> void : 
	var joueur: Node = get_tree().get_first_node_in_group("Joueur")
	var RoomManager: Node = get_tree().get_first_node_in_group("RoomManager")
	joueur.currentHP = node_data["current_health"]
	# Ne plus écraser slots — la restauration d'inventaire complet nécessite
	# un système de sérialisation des ressources Item (à implémenter plus tard).
	# Pour l'instant on ne restaure pas l'inventaire depuis le fichier de sauvegarde
	# afin de ne pas corrompre le tableau de slots.
	if RoomManager.AreRoomsLoaded() : 
		RoomManager.RoomChangeCoords(node_data["current_scene"], node_data["player_pos_x"], node_data["player_pos_y"])
	else : 
		RoomManager.RoomLoadToCoords(node_data["current_scene"], node_data["player_pos_x"], node_data["player_pos_y"])
	print("Chargement effectué")
