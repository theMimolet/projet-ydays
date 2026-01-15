extends CharacterBody2D

var base_speed : float = 40.0  # Vitesse de base (modifiable)
const DASH_SPEED = 200.0
const DASH_DURATION = 0.2
const DASH_COOLDOWN = 0.5
const STAMINA_MAX = 3
const STAMINA_REGEN_RATE = 0.5
const DASH_STAMINA_COST = 1

@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D
@export var canMove : bool = true
var canDash : bool = true

# Système de points de vie
const MAX_HP : int = 100
var current_hp : int = MAX_HP

signal hp_changed(new_hp: int, max_hp: int)
signal player_died

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
	
	# Initialiser les HP et émettre le signal
	current_hp = MAX_HP
	hp_changed.emit(current_hp, MAX_HP)

func is_inventory_open() -> bool:
	"""Vérifie si l'inventaire est ouvert"""
	var inventaire : Node = get_tree().get_first_node_in_group("Inventaire")
	if inventaire != null and "is_open" in inventaire:
		return inventaire.is_open
	return false

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
	velocity = input_direction * base_speed

func _input(event: InputEvent) -> void:
	# Ne pas gérer les interactions si l'inventaire est ouvert
	if not is_inventory_open():
		if event.is_action_pressed("Interract"):
			var interaction_found : bool = InteractionManager.handle_interaction(global_position)
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
	update_depth()
	
	# Mettre à jour les indicateurs des objets collectables proches (toujours, même si inventaire ouvert)
	InteractionManager.update_collectable_indicators(global_position)

func update_depth() -> void:
	const BASE_OFFSET := 1000
	z_index = BASE_OFFSET + int(global_position.y)

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
	
func paralysePlayer(yes : bool) -> void :
	if yes:
		canMove = false
	else : 
		canMove = true

func _on_timeline_ended() -> void:
	canMove = true

func consume_stamina(amount: int) -> void:
	stamina = max(0, stamina - amount)
	stamina_changed.emit(stamina)

func regenerate_stamina() -> void:
	if stamina < STAMINA_MAX:
		stamina += 1
		stamina_changed.emit(stamina)

# ============== SYSTÈME DE POINTS DE VIE ==============

func take_damage(damage: int) -> void:
	"""Inflige des dégâts au joueur"""
	if damage <= 0:
		return
	
	current_hp -= damage
	if current_hp < 0:
		current_hp = 0
	
	hp_changed.emit(current_hp, MAX_HP)
	
	if current_hp <= 0:
		player_died.emit()
		_on_player_death()

func heal(amount: int) -> void:
	"""Soigne le joueur"""
	if amount <= 0:
		return
	
	current_hp += amount
	if current_hp > MAX_HP:
		current_hp = MAX_HP
	
	hp_changed.emit(current_hp, MAX_HP)

func set_hp(new_hp: int) -> void:
	"""Définit directement les HP (utile pour les potions, etc.)"""
	current_hp = clamp(new_hp, 0, MAX_HP)
	hp_changed.emit(current_hp, MAX_HP)
	
	if current_hp <= 0:
		player_died.emit()
		_on_player_death()

func is_dead() -> bool:
	"""Retourne true si le joueur est mort"""
	return current_hp <= 0

func get_hp_percentage() -> float:
	"""Retourne le pourcentage de HP (0.0 à 1.0)"""
	return float(current_hp) / float(MAX_HP)

# ============== GESTION DE LA VITESSE ==============

func set_speed(value: float) -> void:
	"""Définit la vitesse de base du joueur"""
	base_speed = max(0.0, value)  # Empêcher les valeurs négatives

func add_speed(value: float) -> void:
	"""Ajoute à la vitesse de base du joueur"""
	base_speed = max(0.0, base_speed + value)  # Empêcher les valeurs négatives

func get_speed() -> float:
	"""Retourne la vitesse actuelle du joueur"""
	return base_speed

func _on_player_death() -> void:
	"""Appelé quand le joueur meurt - à personnaliser selon vos besoins"""
	print("Le joueur est mort !")
	# Ici vous pouvez ajouter :
	# - Animation de mort
	# - Game Over screen
	# - Respawn, etc.
