extends CharacterBody2D

const SPEED = 40.0
const DASH_SPEED = 200.0
const DASH_DURATION = 0.2
const DASH_COOLDOWN = 0.5

@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D
var canMove : bool = true
var canDash : bool = true

var isMoving : bool
var isDashing : bool = false
var dashTimer : float = 0.0
var dashCooldownTimer : float = 0.0
var dashDirection : Vector2 = Vector2.ZERO
enum playerDirections {BAS, HAUT, GAUCHE, DROITE}
var currentPlayerDirections : playerDirections

func _ready() -> void:
	add_to_group("Joueur")
	if Dialogic.timeline_ended.connect(_on_timeline_ended) != OK:
		print("Erreur : impossible de se connecter au signal timeline_ended de Dialogic")

func Mouvement() -> void :
	if isDashing:
		velocity = dashDirection * DASH_SPEED
		return
	
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
		var interaction_found = InteractionManager.handle_interaction(global_position)
		if interaction_found:
			canMove = false
	
	if event is InputEventKey and event.keycode == KEY_SHIFT and event.pressed and canMove and not isDashing and dashCooldownTimer <= 0.0 and canDash:
		var input_direction : Vector2 = Input.get_vector("Gauche", "Droite", "Haut", "Bas")
		if input_direction != Vector2.ZERO:
			isDashing = true
			dashDirection = input_direction.normalized()
			dashTimer = DASH_DURATION
			dashCooldownTimer = DASH_COOLDOWN

func _physics_process(_delta: float) -> void:

	# ============== MOUVEMENTS ==============
	
	# Gestion du dash
	if isDashing:
		dashTimer -= _delta
		InteractionManager.check_vase_collision(global_position)
		if dashTimer <= 0.0:
			isDashing = false
			dashDirection = Vector2.ZERO
	
	# Gestion du cooldown du dash
	if dashCooldownTimer > 0.0:
		dashCooldownTimer -= _delta
	
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
