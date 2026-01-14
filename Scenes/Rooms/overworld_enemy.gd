extends CharacterBody2D


const SPEED = 300.0
@export var Origine : Node2D 

@onready var nav : NavigationAgent2D = $NavigationAgent2D
@onready var joueur : CharacterBody2D = get_tree().get_first_node_in_group("Joueur")

enum etat {RETOUR, STATIQUE, POURSUITE} 

var etatActuel : etat

func _ready() -> void:
	etatActuel = etat.STATIQUE
	print(joueur)
	nav.velocity_computed.connect(Callable(_on_velocity_computed))

func _physics_process(delta: float) -> void:
	
	match etatActuel : 
		etat.POURSUITE :
			if joueur : 
				nav.target_position = joueur.position
				nav.get_next_path_position()
				
				if NavigationServer2D.map_get_iteration_id(nav.get_navigation_map()) == 0:
					return
				if nav.is_navigation_finished():
					etatActuel = etat.STATIQUE
					return
				
				var next_path_position: Vector2 = nav.get_next_path_position()
				var new_velocity: Vector2 = global_position.direction_to(next_path_position) * SPEED
				if nav.avoidance_enabled:
					nav.set_velocity(new_velocity)
				else:
					_on_velocity_computed(new_velocity)
			# Poursuit le joueur
			pass
		etat.RETOUR : 
			# Retourne à son emplacement d'origine
			pass
		etat.STATIQUE : 
			# Idle
			pass

func set_movement_target(movement_target: Vector2) -> void:
	nav.set_target_position(movement_target)

func getPlayer() -> void :
	joueur = get_tree().get_first_node_in_group("Joueur")
	
func _on_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()

func _on_detection_body_entered(body: Node2D) -> void:
	if body.name == "Joueur":
		etatActuel = etat.POURSUITE
		print("Je te vois !")

func _on_touche_body_entered(body: Node2D) -> void:
	if body.name == "Joueur":
		etatActuel = etat.STATIQUE
		print("Je t'ai eu !")

func _on_navigation_agent_2d_target_reached() -> void:
	etatActuel = etat.POURSUITE
