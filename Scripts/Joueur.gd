extends CharacterBody2D

const SPEED = 40.0
const DASH_SPEED = 200.0
const DASH_DURATION = 0.2
const DASH_COOLDOWN = 0.5
const STAMINA_MAX = 3
const STAMINA_REGEN_RATE = 0.5
const DASH_STAMINA_COST = 1

@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D
var canMove : bool = true
var canDash : bool = true

var isMoving : bool
var isDashing : bool = false
var dashTimer : float = 0.0
var dashCooldownTimer : float = 0.0
var dashDirection : Vector2 = Vector2.ZERO
var stamina : int = STAMINA_MAX
var staminaRegenTimer : float = 0.0
const STAMINA_REGEN_DELAY = 1.0

enum playerDirections {BAS, HAUT, GAUCHE, DROITE}
var currentPlayerDirections : playerDirections

signal stamina_changed(new_stamina: int)

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
	
	if event is InputEventKey and event.keycode == KEY_SHIFT and event.pressed and canMove and not isDashing and dashCooldownTimer <= 0.0 and canDash and stamina >= DASH_STAMINA_COST:
		var input_direction : Vector2 = Input.get_vector("Gauche", "Droite", "Haut", "Bas")
		if input_direction != Vector2.ZERO:
			isDashing = true
			dashDirection = input_direction.normalized()
			dashTimer = DASH_DURATION
			dashCooldownTimer = DASH_COOLDOWN
			consume_stamina(DASH_STAMINA_COST)

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
	
	# Gestion de la régénération de stamina
	if stamina < STAMINA_MAX and not isDashing:
		staminaRegenTimer += _delta
		if staminaRegenTimer >= STAMINA_REGEN_DELAY:
			staminaRegenTimer = 0.0
			regenerate_stamina()
	else:
		staminaRegenTimer = 0.0
	
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

func consume_stamina(amount: int) -> void:
	stamina = max(0, stamina - amount)
	stamina_changed.emit(stamina)

func regenerate_stamina() -> void:
	if stamina < STAMINA_MAX:
		stamina += 1
		stamina_changed.emit(stamina)
