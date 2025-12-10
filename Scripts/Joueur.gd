extends CharacterBody2D

const SPEED = 40.0

@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D
var canMove : bool = true

var isMoving : bool
enum playerDirections {BAS, HAUT, GAUCHE, DROITE}
var currentPlayerDirections : playerDirections

func _ready() -> void:
	if Dialogic.timeline_ended.connect(_on_timeline_ended) != OK:
		print("Erreur : impossible de se connecter au signal timeline_ended de Dialogic")

func Mouvement() -> void :
	var input_direction : Vector2 = Input.get_vector("Gauche", "Droite", "Haut", "Bas")
	if input_direction != Vector2(0,0) : 
		isMoving = true
	else :
		isMoving = false
	if input_direction.x > 0:
		currentPlayerDirections = playerDirections.DROITE
	elif  input_direction.x < 0 :
		currentPlayerDirections = playerDirections.GAUCHE
	elif  input_direction.y > 0:
		currentPlayerDirections = playerDirections.BAS
	elif  input_direction.y < 0:
		currentPlayerDirections = playerDirections.HAUT
	velocity = input_direction * SPEED

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Interract"):
		canMove = false
		InteractionManager.handle_interaction(global_position)

func _physics_process(_delta: float) -> void:

	# ============== MOUVEMENTS ==============
	
	if canMove :
		Mouvement()
		Animate()
	else :
		velocity = Vector2(0, 0)
		sprite.stop()

	move_and_slide()

func Animate() -> void : 
	var currentAnimation : String
	var currentFace : String
	if isMoving :
		currentAnimation = "marche"
	else : 
		currentAnimation = "idle"
	match currentPlayerDirections :
		0 : 
			currentFace = "bas"
		1 : 
			currentFace = "haut"
		2 : 
			currentFace = "gauche"
		3 : 
			currentFace = "droite"
	sprite.play(currentAnimation + "-" + currentFace)
	

func _on_timeline_ended() -> void:
	canMove = true
