extends Node

# Viens de https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html

func save() -> Dictionary:
	
	var joueur: Node = get_tree().get_first_node_in_group("Joueur")
	
	var save_dict := {
		"player_pos_x" : joueur.position.x,
		"player_pos_y" : joueur.position.y,
		"current_health" : joueur.currentHP,
		"currentScene" : Global.currentRoom
	}
	return save_dict

func save_game() -> void:
	var save_file := FileAccess.open("user://savegame.save", FileAccess.WRITE)
	if save_file == null:
		push_error("Could not open save file!")
		return
	var data : Dictionary = save()
	var json_string := JSON.stringify(data)
	save_file.store_line(json_string)
	save_file.close()

func load_game() -> void:
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

	var node_data : Dictionary = json.data
	
	var joueur: Node = get_tree().get_first_node_in_group("Joueur")
	if joueur == null:
		push_error("Player node not found!")
		return

	joueur.position.x   = node_data["player_pos_x"]
	joueur.position.y   = node_data["player_pos_y"]
	joueur.currentHP    = node_data["current_health"]
	Global.currentRoom  = node_data["currentScene"]
	save_file.close()
