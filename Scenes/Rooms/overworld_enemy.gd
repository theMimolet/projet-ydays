extends CharacterBody2D


@export var speed : float = 75.0

@onready var nav : NavigationAgent2D = $NavigationAgent2D
@onready var joueur : CharacterBody2D = get_tree().get_first_node_in_group("Joueur")
@onready var roomManager := get_tree().get_first_node_in_group("RoomManager")

enum etat {COMA, IDLE, ALERTE, POURSUITE} 
var etatActuel : etat

func _ready() -> void:
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
				
				var next_path_position: Vector2 = nav.get_next_path_position()
				var new_velocity: Vector2 = global_position.direction_to(next_path_position) * speed
				if nav.avoidance_enabled:
					nav.set_velocity(new_velocity)
				else:
					_on_velocity_computed(new_velocity)
		etat.ALERTE : 
			if $Timer.is_stopped() : 
				$OverworldEnemyTriggered.play()
				$Timer.start()
		etat.COMA : 
			pass

func set_movement_target(movement_target: Vector2) -> void:
	nav.set_target_position(movement_target)

func _on_room_loaded() -> void :
	etatActuel = etat.IDLE

func _on_room_unloading() -> void :
	etatActuel = etat.COMA

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()

func _on_detection_body_entered(body: Node2D) -> void:
	if body.name == "Joueur":
		if etatActuel == etat.IDLE :
			etatActuel = etat.ALERTE
		print("Je te vois !")

func _on_touche_body_entered(body: Node2D) -> void:
	if body == joueur: 
		joueur.paralysePlayer(true)
		print("Je t'ai eu !")
		etatActuel = etat.COMA

func _on_timer_timeout() -> void:
	print("RUN")
	etatActuel = etat.POURSUITE
	$Timer.stop()
