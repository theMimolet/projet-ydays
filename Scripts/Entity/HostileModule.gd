extends Node2D

@export var baseSpeed : float = 40.0
@export var maxSpeed : float = 200.0
var speed : float = baseSpeed

@onready var nav : NavigationAgent2D = $NavigationAgent2D
@onready var joueur : CharacterBody2D = get_tree().get_first_node_in_group("Joueur")
@onready var roomManager := get_tree().get_first_node_in_group("RoomManager")

var joueurProche : bool
var niveauAlerte : int

enum etat {COMA, IDLE, ALERTE, POURSUITE} 
var etatActuel : etat

func _ready() -> void:
	niveauAlerte = 0
	joueurProche = false
	etatActuel = etat.COMA
	roomManager.loaded.connect(Callable(_on_room_loaded))
	roomManager.unloading.connect(Callable(_on_room_unloading))
	nav.velocity_computed.connect(Callable(_on_velocity_computed))

func _physics_process(_delta: float) -> void:
	match etatActuel : 
		etat.POURSUITE :
			if joueur : 
				nav.target_position = joueur.position
				nav.get_next_path_position()
				
				if NavigationServer2D.map_get_iteration_id(nav.get_navigation_map()) == 0:
					return
				
				if speed < maxSpeed : 
					speed += 0.5
				print(speed)
				
				var next_path_position: Vector2 = nav.get_next_path_position()
				var new_velocity: Vector2 = global_position.direction_to(next_path_position) * speed
				if nav.avoidance_enabled:
					nav.set_velocity(new_velocity)
				else:
					_on_velocity_computed(new_velocity)
		etat.ALERTE : 
			if $TPoursuite.is_stopped() : 
				$Triggered.play()
				$TPoursuite.start()
		etat.IDLE : 
			if $TAlerte.is_stopped() : 
				print(joueurProche)
				if joueurProche :
					majNiveauAlerte(true)
				else : 
					majNiveauAlerte(false)
				$TAlerte.start()
		etat.COMA : 
			$"..".velocity = Vector2(0, 0)

func majNiveauAlerte(ajout : bool) -> void : 
	if ajout : 
		niveauAlerte += 1
	else : 
		if niveauAlerte > 0 :
			niveauAlerte -= 1
	if niveauAlerte >= 5: 
		etatActuel = etat.ALERTE
	print(niveauAlerte)

func set_movement_target(movement_target: Vector2) -> void:
	nav.set_target_position(movement_target)

func _on_room_loaded() -> void :
	etatActuel = etat.IDLE

func _on_room_unloading() -> void :
	etatActuel = etat.COMA

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	$"..".velocity = safe_velocity
	$"..".move_and_slide()

func _on_detection_body_entered(body: Node2D) -> void:
	if body == joueur: 
		joueurProche = true
		print("Je ressens quelqu'un...")
		$TAlerte.start()

func _on_detection_body_exited(body: Node2D) -> void:
	if body == joueur: 
		joueurProche = false
		print("En fait non.")

func _on_touche_body_entered(body: Node2D) -> void:
	if body == joueur: 
		joueur.paralysePlayer(true)
		print("Je t'ai eu !")
		etatActuel = etat.COMA

func _on_t_poursuite_timeout() -> void:
	print("RUN")
	etatActuel = etat.POURSUITE
	$TPoursuite.stop()

func _on_t_alerte_timeout() -> void:
	$TAlerte.stop()
