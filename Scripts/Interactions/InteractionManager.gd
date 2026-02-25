extends Node

const Vase = preload("res://Scripts/Interactions/Vase.gd")


const VASE_TILE_COORDS = Vector2i(2, 0)
const INTERACTION_DISTANCE = 32.0

var last_targeted_item : Node2D = null

const CELLS_TO_CHECK := [
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

func _get_tilemap() -> TileMapLayer:
	var rooms := get_tree().current_scene.get_node_or_null("Room")
	if rooms == null:
		return null
	return rooms.find_child("TileMapLayer", true, false)

func _find_vase_cell(player_position: Vector2) -> Vector2i:
	var tilemap := _get_tilemap()
	if tilemap == null:
		return Vector2i(-1, -1)
	
	var player_cell: Vector2i = tilemap.local_to_map(tilemap.to_local(player_position))
	
	for offset: Vector2i in CELLS_TO_CHECK:
		var cell: Vector2i = player_cell + offset
		if tilemap.get_cell_source_id(cell) == -1:
			continue
		
		if tilemap.get_cell_atlas_coords(cell) == VASE_TILE_COORDS:
			return cell
	
	return Vector2i(-1, -1)

func _find_nearby_node_interactions(player_position: Vector2, group_name: String) -> Node:
	var nodes: Array[Node] = get_tree().get_nodes_in_group(group_name)
	
	for node: Node in nodes:
		if node.has_method("interact"):
			var distance: float = player_position.distance_to(node.global_position)
			if distance <= INTERACTION_DISTANCE:
				return node
	
	return null

func handle_interaction(player_position: Vector2) -> bool:
	# Vérifier d'abord les interactions basées sur tiles (vases)
	var vase_cell := _find_vase_cell(player_position)
	if vase_cell != Vector2i(-1, -1):
		Vase.interact(vase_cell)
		return true
	
	# Vérifier les interactions basées sur nodes (PNJ)
	var pnj := _find_nearby_node_interactions(player_position, "PNJ")
	if pnj != null:
		pnj.interact()
		return true  # Les PNJ bloquent le mouvement pendant le dialogue
	
	# Vérifier les interactions basées sur nodes (coffres)
	var coffre := _find_nearby_node_interactions(player_position, "Coffres")
	if coffre != null:
		coffre.interact()
	
	# Vérifier les interactions basées sur nodes (portes)
	var door := _find_nearby_node_interactions(player_position, "Doors")
	if door != null:
		door.interact()
	
	# Vérifier les items collectables proches
	var item_collected : bool = check_collectable_items(player_position)
	if item_collected:
		return true  # Les items collectables bloquent le mouvement pendant la collecte
	
	# Les coffres ne bloquent pas le mouvement
	return false

func check_vase_collision(player_position: Vector2) -> void:
	var vase_cell := _find_vase_cell(player_position)
	if vase_cell == Vector2i(-1, -1):
		return
	
	var tilemap := _get_tilemap()
	if tilemap == null:
		return
	
	# Casser le vase en supprimant le tile
	tilemap.erase_cell(vase_cell)

func get_nearest_collectable(player_position: Vector2) -> Node2D:
	"""Retourne l'objet collectable le plus proche du joueur, ou null si aucun"""
	var collectables : Array = get_tree().get_nodes_in_group("CollectableItems")
	var nearest : Node2D = null
	const COLLECTION_DISTANCE = 32.0
	var nearest_distance : float = COLLECTION_DISTANCE
	
	for collectable : Node in collectables:
		if collectable.has_method("can_be_collected") and collectable.can_be_collected():
			var distance : float = player_position.distance_to(collectable.global_position)
			if distance <= COLLECTION_DISTANCE and distance < nearest_distance:
				nearest = collectable as Node2D
				nearest_distance = distance
	
	return nearest

func update_collectable_indicators(player_position: Vector2) -> void:
	"""Met à jour les indicateurs visuels des objets collectables proches"""
	var nearest = get_nearest_collectable(player_position)
	
	# Cacher l'indicateur de l'item précédent
	if last_targeted_item != null and last_targeted_item != nearest:
		if last_targeted_item.has_method("hide_indicator"):
			last_targeted_item.hide_indicator()
	
	# Afficher l'indicateur du nouvel item
	if nearest != null:
		if nearest.has_method("show_indicator"):
			nearest.show_indicator()
		last_targeted_item = nearest
	else:
		if last_targeted_item != null:
			if last_targeted_item.has_method("hide_indicator"):
				last_targeted_item.hide_indicator()
			last_targeted_item = null

func check_collectable_items(player_position: Vector2) -> bool:
	"""Vérifie et collecte les items collectables proches. Retourne true si un item a été collecté"""
	# Mettre à jour les indicateurs
	update_collectable_indicators(player_position)
	
	# Si l'utilisateur appuie sur F, collecter l'item le plus proche
	if last_targeted_item != null:
		if last_targeted_item.has_method("collect") and last_targeted_item.has_method("can_be_collected"):
			if last_targeted_item.can_be_collected():
				return last_targeted_item.collect()
	
	return false
