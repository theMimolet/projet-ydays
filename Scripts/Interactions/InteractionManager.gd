extends Node

const Vase = preload("res://Scripts/Interactions/Vase.gd")

func handle_interaction(player_position: Vector2) -> bool:
	# Retourne true si une interaction a été trouvée, false sinon
	var rooms := get_tree().current_scene.get_node_or_null("Room")
	if rooms == null:
		print("Erreur : node Niveau introuvable !")
		return false
	
	var tilemap := rooms.find_child("TileMapLayer", true, false)
	if tilemap == null:
		print("Erreur : node TileMapLayer introuvable !")
		return false
	
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
			return true
	
	# Vérifier les coffres proches
	if check_coffre_interaction(player_position):
		return true
	
	return false

func check_vase_collision(player_position: Vector2) -> void:
	var rooms := get_tree().current_scene.get_node_or_null("Room")
	if rooms == null:
		return
	
	var tilemap := rooms.find_child("TileMapLayer", true, false)
	if tilemap == null:
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
			# Casser le vase en supprimant le tile
			tilemap.erase_cell(cell)
			return

func check_coffre_interaction(player_position: Vector2) -> bool:
	# Chercher tous les coffres dans le groupe "Coffres"
	var coffres = get_tree().get_nodes_in_group("Coffres")
	
	# Distance maximale pour l'interaction (en pixels)
	const INTERACTION_DISTANCE = 32.0
	
	for coffre in coffres:
		if coffre.has_method("interact"):
			var distance = player_position.distance_to(coffre.global_position)
			if distance <= INTERACTION_DISTANCE:
				coffre.interact()
				return true
	
	return false
