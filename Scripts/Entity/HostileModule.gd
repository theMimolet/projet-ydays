extends Node2D

@onready var nav : NavigationAgent2D = $NavigationAgent2D
@onready var joueur : CharacterBody2D = get_tree().get_first_node_in_group("Joueur")
@onready var roomManager : Node = get_tree().get_first_node_in_group("RoomManager")

## Stats de combat (modifiables dans l'inspecteur)
@export_category("Combat")
@export var monster_id: String = ""
@export var monster_hp: int = 50
@export var monster_attack: int = 10
@export var monster_name: String = "Monstre"

## Stats de mouvement
@export_category("Mouvement")
@export var baseSpeed: float = 40.0
@export var maxSpeed: float = 200.0
var speed: float = baseSpeed

var joueurProche: bool
var niveauAlerte: int

enum etat {COMA, IDLE, ALERTE, POURSUITE} 
var etatActuel: etat


func _ready() -> void:
	# Générer un ID unique stable basé sur le chemin du nœud si non défini
	if monster_id == "":
		# Utiliser le chemin complet du parent comme ID stable
		monster_id = str(get_parent().get_path())
	
	# Vérifier si ce monstre a été tué - supprimer immédiatement
	if Global.is_monster_dead(monster_id):
		get_parent().queue_free()
		return
	
	niveauAlerte = 0
	joueurProche = false
	etatActuel = etat.COMA
	
	if roomManager:
		roomManager.loaded.connect(Callable(_on_room_loaded))
		roomManager.unloading.connect(Callable(_on_room_unloading))
	
	nav.velocity_computed.connect(Callable(_on_velocity_computed))


func _physics_process(_delta: float) -> void:
	match etatActuel: 
		etat.POURSUITE:
			if joueur: 
				nav.target_position = joueur.position
				nav.get_next_path_position()
				
				if NavigationServer2D.map_get_iteration_id(nav.get_navigation_map()) == 0:
					return
				
				if speed < maxSpeed: 
					speed += 0.5
				
				var next_path_position: Vector2 = nav.get_next_path_position()
				var new_velocity: Vector2 = global_position.direction_to(next_path_position) * speed
				if nav.avoidance_enabled:
					nav.set_velocity(new_velocity)
				else:
					_on_velocity_computed(new_velocity)
		etat.ALERTE: 
			if $TPoursuite.is_stopped(): 
				$Triggered.play()
				$TPoursuite.start()
		etat.IDLE: 
			if $TAlerte.is_stopped(): 
				if joueurProche:
					majNiveauAlerte(true)
				else: 
					majNiveauAlerte(false)
				$TAlerte.start()
		etat.COMA: 
			get_parent().velocity = Vector2(0, 0)


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
	get_parent().velocity = safe_velocity
	get_parent().move_and_slide()


func _on_detection_body_entered(body: Node2D) -> void:
	if body == joueur: 
		joueurProche = true
		$TAlerte.start()


func _on_detection_body_exited(body: Node2D) -> void:
	if body == joueur: 
		joueurProche = false


func _on_touche_body_entered(body: Node2D) -> void:
	if body == joueur:
		# Préparer les données de combat
		var combat_data: Dictionary = {
			"monster_id": monster_id,
			"monster_hp": monster_hp,
			"monster_max_hp": monster_hp,
			"monster_attack": monster_attack,
			"monster_name": monster_name,
		}
		
		# Récupérer le sprite du monstre si disponible
		var parent_node := get_parent()
		if parent_node.has_node("Sprite"):
			var sprite: Sprite2D = parent_node.get_node("Sprite")
			if sprite.texture:
				combat_data["monster_texture"] = sprite.texture
		
		# Lancer le combat via Global
		etatActuel = etat.COMA
		Global.start_combat(combat_data)


func _on_t_poursuite_timeout() -> void:
	etatActuel = etat.POURSUITE
	$TPoursuite.stop()


func _on_t_alerte_timeout() -> void:
	$TAlerte.stop()
