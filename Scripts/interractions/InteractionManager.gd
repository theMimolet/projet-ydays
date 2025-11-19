extends Node

const Vase = preload("res://Scripts/interractions/Vase.gd")

func handle_interaction(player_position: Vector2) -> void:
	var rooms = get_tree().current_scene.get_node_or_null("Room")
	if rooms == null:
		print("Erreur : node Niveau introuvable !")
		return
	
	var tilemap = rooms.find_child("TileMapLayer", true, false)
	if tilemap == null:
		print("Erreur : node TileMapLayer introuvable !")
		return
	
	var player_cell = tilemap.local_to_map(tilemap.to_local(player_position))
	
	# Liste des cases à vérifier (joueur + 8 cases adjacentes)
	var cells_to_check := [
		Vector2i(0, 0),   # Case du joueur
		Vector2i(-1, -1), # Haut-Gauche
		Vector2i(0, -1),  # Haut
		Vector2i(1, -1), # Haut-Droite
		Vector2i(-1, 0),  # Gauche
		Vector2i(1, 0),   # Droite
		Vector2i(-1, 1),  # Bas-Gauche
		Vector2i(0, 1),   # Bas
		Vector2i(1, 1),   # Bas-Droite
	]
	
	for offset in cells_to_check:
		var cell = player_cell + offset
		if tilemap.get_cell_source_id(cell) == -1:
			continue
		
		if tilemap.get_cell_atlas_coords(cell) == Vector2i(2, 0):
			Vase.interact(cell)
			return
