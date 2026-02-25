extends Node

@export var currentRoom : String

# Données de combat (remplies avant transition vers CombatView)
var combat_data: Dictionary = {}
# Liste des monstres tués (par leur ID unique)
var dead_monsters: Array[String] = []
# Position du joueur avant le combat (pour le retour)
var player_return_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	pass


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R and (event.ctrl_pressed or event.meta_pressed):
			reset_scene()


func reset_scene() -> void:
	get_tree().reload_current_scene()


## Démarre un combat avec les données du monstre
## Appelé par HostileModule quand le monstre touche le joueur
func start_combat(data: Dictionary) -> void:
	combat_data = data
	# Sauvegarder la scène actuelle et la position du joueur
	combat_data["scene_origine"] = get_tree().current_scene.scene_file_path
	
	var joueur := get_tree().get_first_node_in_group("Joueur")
	if joueur:
		player_return_position = joueur.global_position
		combat_data["joueur_hp"] = joueur.currentHP
		combat_data["joueur_max_hp"] = joueur.MAX_HP
	
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
