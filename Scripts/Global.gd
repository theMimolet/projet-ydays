extends Node

@export var currentRoom : String

var pending_door : Node = null

# Données de combat (remplies avant transition vers CombatView)
var combat_data: Dictionary = {}
# Liste des monstres tués (par leur ID unique)
var dead_monsters: Array[String] = []
# Position du joueur avant le combat (pour le retour)
var player_return_position: Vector2 = Vector2.ZERO

# Persistence de l'inventaire entre les scènes
var inventory_data: Array = []  # Array de dictionnaires {item: Resource, quantity: int}
var equipped_weapon: Resource = null
var player_hp_saved: int = -1  # -1 = pas sauvegardé

func _ready() -> void:
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R and (event.ctrl_pressed or event.meta_pressed):
			reset_scene()


func reset_scene() -> void:
	get_tree().reload_current_scene()

func set_pending_door(door: Node) -> void:
	pending_door = door

func use_key_on_pending_door() -> void:
	if pending_door != null and pending_door.is_inside_tree() and pending_door.has_method("use_key_and_open"):
		pending_door.use_key_and_open()
	pending_door = null


## Démarre un combat avec les données du monstre
## Appelé par HostileModule quand le monstre touche le joueur
func start_combat(data: Dictionary) -> void:
	combat_data = data
	# Sauvegarder la scène actuelle et la position du joueur
	combat_data["scene_origine"] = get_tree().current_scene.scene_file_path
	
	# Sauvegarder l'inventaire AVANT de changer de scène
	save_inventory()
	
	var joueur := get_tree().get_first_node_in_group("Joueur")
	if joueur:
		player_return_position = joueur.global_position
		combat_data["joueur_hp"] = joueur.currentHP
		combat_data["joueur_max_hp"] = joueur.MAX_HP
		
		# Récupérer l'arme équipée du joueur
		if joueur.has_method("get_arme_equipee"):
			combat_data["arme_equipee"] = joueur.get_arme_equipee()
		elif "arme_equipee" in joueur:
			combat_data["arme_equipee"] = joueur.arme_equipee
		
		# Récupérer les armes de l'inventaire (depuis les données sauvegardées)
		combat_data["armes_inventaire"] = _get_armes_from_inventaire()
	
	# Lancer la transition vers CombatView (fondu classique rapide)
	if has_node("/root/SceneTransition"):
		get_node("/root/SceneTransition").transition_to_scene("res://Scenes/Fights/CombatView.tscn", 0.5, 0.5, 0.0)
	else:
		get_tree().change_scene_to_file("res://Scenes/Fights/CombatView.tscn")


## Termine le combat
## victoire = true si le joueur a gagné, false si game over
func end_combat(victoire: bool) -> void:
	if victoire:
		# Marquer le monstre comme tué
		if combat_data.has("monster_id"):
			var monster_id: String = combat_data["monster_id"]
			if monster_id not in dead_monsters:
				dead_monsters.append(monster_id)
		
		# Retourner à la scène d'origine (ne pas effacer player_return_position ici)
		var scene_origine: String = combat_data.get("scene_origine", "")
		combat_data.clear()
		
		if scene_origine != "":
			if has_node("/root/SceneTransition"):
				# Fondu avec 3 secondes d'écran noir pour masquer le repositionnement
				get_node("/root/SceneTransition").transition_to_scene(scene_origine, 0.5, 0.5, 3.0)
			else:
				get_tree().change_scene_to_file(scene_origine)
	else:
		combat_data.clear()
		# Game over
		get_tree().change_scene_to_file("res://Scenes/gameover.tscn")


## Vérifie si un monstre est mort
func is_monster_dead(monster_id: String) -> bool:
	return monster_id in dead_monsters


## Appelé après le retour dans la scène d'origine pour repositionner le joueur
func restore_player_position() -> void:
	if player_return_position != Vector2.ZERO:
		var joueur := get_tree().get_first_node_in_group("Joueur")
		if joueur:
			joueur.global_position = player_return_position
		player_return_position = Vector2.ZERO


## Récupère toutes les armes de type "weapon" depuis l'inventaire du joueur
func _get_armes_from_inventaire() -> Array:
	var armes: Array = []
	var inventaire := get_tree().get_first_node_in_group("Inventaire")
	
	if inventaire == null or not "slots" in inventaire:
		return armes
	
	for slot in inventaire.slots:
		if slot is Object and slot.has_method("is_empty") and not slot.is_empty():
			var item = slot.item
			if item != null and "item_type" in item and item.item_type == "weapon":
				if item not in armes:
					armes.append(item)
	
	return armes


## Sauvegarde l'inventaire et l'arme équipée avant un changement de scène
func save_inventory() -> void:
	var inventaire := get_tree().get_first_node_in_group("Inventaire")
	if inventaire == null:
		return
	
	inventory_data.clear()
	
	if "slots" in inventaire:
		for slot in inventaire.slots:
			if slot is Object and slot.has_method("is_empty") and not slot.is_empty():
				inventory_data.append({
					"item": slot.item,
					"quantity": slot.quantity
				})
	
	var joueur := get_tree().get_first_node_in_group("Joueur")
	if joueur:
		if "arme_equipee" in joueur:
			equipped_weapon = joueur.arme_equipee
		if "currentHP" in joueur:
			player_hp_saved = joueur.currentHP


## Restaure l'inventaire et l'arme équipée après un changement de scène
func restore_inventory() -> void:
	var inventaire := get_tree().get_first_node_in_group("Inventaire")
	if inventaire == null:
		return
	
	if inventory_data.is_empty():
		return
	
	# Vider les slots actuels
	if "slots" in inventaire:
		for slot in inventaire.slots:
			if slot is Object and slot.has_method("clear_slot"):
				slot.clear_slot()
	
	# Restaurer les items
	for item_data in inventory_data:
		if inventaire.has_method("add_item"):
			inventaire.add_item(item_data["item"], item_data["quantity"])
	
	# Restaurer l'arme équipée
	var joueur := get_tree().get_first_node_in_group("Joueur")
	if joueur and equipped_weapon != null:
		if joueur.has_method("equiper_arme"):
			joueur.equiper_arme(equipped_weapon)
	
	# Restaurer les HP du joueur
	if joueur and player_hp_saved > 0:
		if joueur.has_method("set_hp"):
			joueur.set_hp(player_hp_saved)
		elif "currentHP" in joueur:
			joueur.currentHP = player_hp_saved


## Vérifie si des données d'inventaire sont sauvegardées
func has_saved_inventory() -> bool:
	return not inventory_data.is_empty()
