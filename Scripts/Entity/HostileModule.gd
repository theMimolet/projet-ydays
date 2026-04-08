extends Node2D

@onready var nav: NavigationAgent2D = get_node_or_null("NavigationAgent2D")
@onready var joueur: CharacterBody2D = get_tree().get_first_node_in_group("Joueur")
@onready var roomManager: Node = get_tree().get_first_node_in_group("RoomManager")
@onready var tAlerte: Timer = get_node_or_null("TAlerte")
@onready var tPoursuite: Timer = get_node_or_null("TPoursuite")
@onready var triggeredAudio: Node = get_node_or_null("Triggered")

## Stats de combat (modifiables dans l'inspecteur)
@export_category("Combat")
@export var monster_id: String = ""
@export var monster_name: String = "Monstre"
@export var monster_hp: int = 50
@export_subgroup("Dégâts par tour")
@export var monster_damage_min: int = 5
@export var monster_damage_max: int = 10

## Dialogue d'introduction au combat (optionnel, laisser vide pour aucun dialogue)
@export_category("Dialogue")
@export var combat_intro_dialogue: String = ""

## Stats de mouvement
@export_category("Mouvement")
@export var baseSpeed: float = 40.0
@export var maxSpeed: float = 200.0
var speed: float = baseSpeed

var joueurProche: bool
var niveauAlerte: int
var _combat_triggered: bool = false

enum etat {COMA, IDLE, ALERTE, POURSUITE}
var etatActuel: etat


func _ready() -> void:
	if monster_id == "":
		monster_id = str(get_parent().name) + "@" + str(get_parent().position)
	
	if Global.is_monster_dead(monster_id):
		get_parent().queue_free()
		return
	
	niveauAlerte = 0
	joueurProche = false
	
	if roomManager:
		roomManager.loaded.connect(Callable(_on_room_loaded))
		roomManager.unloading.connect(Callable(_on_room_unloading))
		etatActuel = etat.COMA
	else:
		etatActuel = etat.IDLE
	
	if nav != null:
		nav.velocity_computed.connect(Callable(_on_velocity_computed))


func _physics_process(_delta: float) -> void:
	if joueur == null:
		joueur = get_tree().get_first_node_in_group("Joueur")

	match etatActuel:
		etat.POURSUITE:
			_do_poursuite()
		etat.ALERTE:
			if tPoursuite != null and tPoursuite.is_stopped():
				if triggeredAudio != null and triggeredAudio.has_method("play"):
					triggeredAudio.play()
				tPoursuite.start()
		etat.IDLE:
			if tAlerte != null and tAlerte.is_stopped():
				if joueurProche:
					majNiveauAlerte(true)
				else:
					majNiveauAlerte(false)
				tAlerte.start()
		etat.COMA:
			var host := get_parent() as CharacterBody2D
			if host != null:
				host.velocity = Vector2.ZERO


func _do_poursuite() -> void:
	var host := get_parent() as CharacterBody2D
	if host == null or joueur == null:
		return

	if speed < maxSpeed:
		speed += 0.5

	var has_usable_nav: bool = (
		nav != null
		and NavigationServer2D.map_get_iteration_id(nav.get_navigation_map()) != 0
		and not nav.is_navigation_finished()
	)

	if has_usable_nav:
		nav.target_position = joueur.global_position
		var next_pos: Vector2 = nav.get_next_path_position()
		var diff: Vector2 = next_pos - host.global_position
		if diff.length_squared() < 1.0:
			return
		var new_velocity: Vector2 = diff.normalized() * speed
		if nav.avoidance_enabled:
			nav.set_velocity(new_velocity)
		else:
			_on_velocity_computed(new_velocity)
	else:
		var direction: Vector2 = host.global_position.direction_to(joueur.global_position)
		host.velocity = direction * speed
		host.move_and_slide()


func majNiveauAlerte(ajout: bool) -> void: 
	if ajout: 
		niveauAlerte += 1
	else: 
		if niveauAlerte > 0:
			niveauAlerte -= 1
	if niveauAlerte >= 5: 
		etatActuel = etat.ALERTE

func set_movement_target(movement_target: Vector2) -> void:
	nav.set_target_position(movement_target)


func _on_room_loaded() -> void:
	etatActuel = etat.IDLE


func _on_room_unloading() -> void:
	etatActuel = etat.COMA


func _on_velocity_computed(safe_velocity: Vector2) -> void:
	var host := get_parent() as CharacterBody2D
	if host == null:
		return
	host.velocity = safe_velocity
	host.move_and_slide()


func _on_detection_body_entered(body: Node2D) -> void:
	if body == joueur: 
		joueurProche = true
		if tAlerte != null:
			tAlerte.start()


func _on_detection_body_exited(body: Node2D) -> void:
	if body == joueur: 
		joueurProche = false


func _on_touche_body_entered(body: Node2D) -> void:
	if _combat_triggered:
		return
	if body != joueur:
		return
	
	_combat_triggered = true
	etatActuel = etat.COMA

	var combat_data_dict: Dictionary = {
		"monster_id": monster_id,
		"monster_hp": monster_hp,
		"monster_max_hp": monster_hp,
		"monster_attack": monster_damage_min,
		"monster_attack_min": monster_damage_min,
		"monster_attack_max": monster_damage_max,
		"monster_name": monster_name,
		"combat_intro_dialogue": combat_intro_dialogue,
	}

	var parent_node := get_parent()
	_collect_monster_visuals(parent_node, combat_data_dict)

	Global.start_combat(combat_data_dict)


func _collect_monster_visuals(node: Node, data: Dictionary) -> void:
	"""Récupère les données visuelles du monstre (SpriteFrames ou texture statique)"""
	for child in node.get_children():
		if child is AnimatedSprite2D:
			var anim_sprite := child as AnimatedSprite2D
			if anim_sprite.sprite_frames != null:
				data["monster_sprite_frames"] = anim_sprite.sprite_frames
				data["monster_animation"] = anim_sprite.animation
				var frames := anim_sprite.sprite_frames
				var anim_name := anim_sprite.animation
				if frames.get_frame_count(anim_name) > 0:
					data["monster_texture"] = frames.get_frame_texture(anim_name, 0)
				return
		if child is Sprite2D and child.texture != null:
			data["monster_texture"] = child.texture
			return


func _on_t_poursuite_timeout() -> void:
	etatActuel = etat.POURSUITE
	if tPoursuite != null:
		tPoursuite.stop()


func _on_t_alerte_timeout() -> void:
	if tAlerte != null:
		tAlerte.stop()
