extends CharacterBody2D

var base_speed : float = 40.0  # Vitesse de base (modifiable)

@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var inventory : Node = $Inventaire
@onready var arme_sprite : Sprite2D = $ArmeSprite

@export var canMove : bool = true
var isMoving : bool

# Système d'arme équipée
var arme_equipee: Resource = null
signal arme_changed(arme: Resource)

# Système de points de vie
const MAX_HP : int = 100
var currentHP : int = MAX_HP
signal hp_changed(new_hp: int, max_hp: int)
signal player_died

# Système Dash
const DASH_SPEED = 200.0
const DASH_DURATION = 0.2
const DASH_COOLDOWN = 0.5
const DASH_STAMINA_COST = 1
var canDash : bool = true
var isDashing : bool = false
var dashTimer : float = 0.0
var dashCooldownTimer : float = 0.0
var dashDirection : Vector2 = Vector2.ZERO

# Système Stamina
var stamina : int = STAMINA_MAX
var staminaRegenTimer : float = 0.0
const STAMINA_MAX = 3
const STAMINA_REGEN_RATE = 0.5
const STAMINA_REGEN_DELAY = 1.0

enum playerDirections {BAS, HAUT, GAUCHE, DROITE}
var currentPlayerDirections : playerDirections

signal stamina_changed(new_stamina: int)

func _ready() -> void:
	if Dialogic.timeline_ended.connect(_on_timeline_ended) != OK:
		print("Erreur : impossible de se connecter au signal timeline_ended de Dialogic")
	if Dialogic.timeline_started.connect(_on_timeline_started) != OK:
		print("Erreur : impossible de se connecter au signal timeline_started de Dialogic")
	
	# Initialiser les HP et émettre le signal
	currentHP = MAX_HP
	hp_changed.emit(currentHP, MAX_HP)
	
	# Restaurer la position si on revient d'un combat (après le chargement de la room)
	_try_restore_combat_position()

func is_inventory_open() -> bool:
	"""Vérifie si l'inventaire est ouvert"""
	if inventory != null and "is_open" in inventory:
		return inventory.is_open
	return false

func _is_movement_blocked() -> bool:
	"""True si un dialogue est ouvert ou la console de dev est ouverte."""
	if Dialogic.current_timeline != null:
		return true
	var cons: Node = get_node_or_null("/root/DevConsole")
	if cons != null and "is_open" in cons and cons.is_open:
		return true
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
	# Ne pas réagir aux actions si un dialogue ou la console est ouverte
	if _is_movement_blocked():
		return
	# Ne pas gérer les interactions si l'inventaire est ouvert
	if not is_inventory_open():
		if event.is_action_pressed("Interact"):
			var interaction_found : bool = InteractionManager.handle_interaction(global_position)
			if interaction_found:
				canMove = false
	
	if event.is_action_pressed("Dash") and canMove and not isDashing and dashCooldownTimer <= 0.0 and canDash and stamina >= DASH_STAMINA_COST:
		var input_direction : Vector2 = Input.get_vector("Gauche", "Droite", "Haut", "Bas")
		if input_direction != Vector2.ZERO:
			isDashing = true
			dashDirection = input_direction.normalized()
			dashTimer = DASH_DURATION
			dashCooldownTimer = DASH_COOLDOWN
			consume_stamina(DASH_STAMINA_COST)

func _physics_process(delta: float) -> void:

	# ============== MOUVEMENTS ==============
	
	# Gestion du dash
	if isDashing:
		dashTimer -= delta
		InteractionManager.check_vase_collision(global_position)
		if dashTimer <= 0.0:
			isDashing = false
			dashDirection = Vector2.ZERO
	
	# Gestion du cooldown du dash
	if dashCooldownTimer > 0.0:
		dashCooldownTimer -= delta
	
	# Gestion de la régénération de stamina
	if stamina < STAMINA_MAX and not isDashing:
		staminaRegenTimer += delta
		if staminaRegenTimer >= STAMINA_REGEN_DELAY:
			staminaRegenTimer = 0.0
			regenerate_stamina()
	else:
		staminaRegenTimer = 0.0
	
	if canMove and not _is_movement_blocked():
		Mouvement()
		Animate()
	else :
		velocity = Vector2(0, 0)
		sprite.stop()

	move_and_slide()
	update_depth()
	
	# Mettre à jour les indicateurs (interactables + collectables)
	InteractionManager.update_interaction_indicators(global_position)

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
	_update_arme_position()
	
func paralysePlayer(yes : bool) -> void :
	if yes:
		canMove = false
	else : 
		canMove = true

func _on_timeline_started() -> void:
	canMove = false

func _on_timeline_ended() -> void:
	canMove = true

# ============== SYSTÈME D'ARME ÉQUIPÉE ==============

func equiper_arme(arme: Resource) -> void:
	arme_equipee = arme
	_update_arme_sprite()
	arme_changed.emit(arme)


func desequiper_arme() -> void:
	arme_equipee = null
	_update_arme_sprite()
	arme_changed.emit(null)


func get_arme_equipee() -> Resource:
	return arme_equipee


func _update_arme_sprite() -> void:
	if arme_sprite == null:
		return
	
	if arme_equipee == null or not arme_equipee.has_method("get_nom_arme"):
		arme_sprite.visible = false
		return
	
	if arme_equipee.sprite_overworld == null:
		arme_sprite.visible = false
		return
	
	arme_sprite.texture = arme_equipee.sprite_overworld
	arme_sprite.visible = true
	_update_arme_position()


func _update_arme_position() -> void:
	if arme_sprite == null or not arme_sprite.visible:
		return
	
	match currentPlayerDirections:
		playerDirections.BAS:
			arme_sprite.position = Vector2(8, 4)
			arme_sprite.rotation_degrees = 45
			arme_sprite.flip_h = false
			arme_sprite.z_index = 1
		playerDirections.HAUT:
			arme_sprite.position = Vector2(-8, -4)
			arme_sprite.rotation_degrees = -135
			arme_sprite.flip_h = false
			arme_sprite.z_index = -1
		playerDirections.GAUCHE:
			arme_sprite.position = Vector2(-10, 2)
			arme_sprite.rotation_degrees = -45
			arme_sprite.flip_h = true
			arme_sprite.z_index = 1
		playerDirections.DROITE:
			arme_sprite.position = Vector2(10, 2)
			arme_sprite.rotation_degrees = 45
			arme_sprite.flip_h = false
			arme_sprite.z_index = 1


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
	
	currentHP -= damage
	if currentHP < 0:
		currentHP = 0
	
	hp_changed.emit(currentHP, MAX_HP)
	
	if currentHP <= 0:
		player_died.emit()
		_on_player_death()

func heal(amount: int) -> void:
	"""Soigne le joueur"""
	if amount <= 0:
		return
	
	currentHP += amount
	if currentHP > MAX_HP:
		currentHP = MAX_HP
	
	hp_changed.emit(currentHP, MAX_HP)

func set_hp(new_hp: int) -> void:
	"""Définit directement les HP (utile pour les potions, etc.)"""
	currentHP = clamp(new_hp, 0, MAX_HP)
	hp_changed.emit(currentHP, MAX_HP)
	
	if currentHP <= 0:
		player_died.emit()
		_on_player_death()

func is_dead() -> bool:
	"""Retourne true si le joueur est mort"""
	return currentHP <= 0

func get_hp_percentage() -> float:
	"""Retourne le pourcentage de HP (0.0 à 1.0)"""
	return float(currentHP) / float(MAX_HP)

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
	"""Appelé quand le joueur meurt - change vers la scène game over"""
	print("Le joueur est mort !")
	# Changer vers la scène game over
	get_tree().change_scene_to_file("res://Scenes/gameover.tscn")


func _try_restore_combat_position() -> void:
	"""Essaie de restaurer la position après un combat"""
	if Global.player_return_position == Vector2.ZERO:
		return
	
	visible = false
	
	# Attendre que le RoomManager ait fini de charger (s'il existe et charge)
	var room_manager := get_tree().get_first_node_in_group("RoomManager")
	if room_manager and room_manager.has_signal("loaded"):
		if "isLoading" in room_manager and room_manager.isLoading:
			await room_manager.loaded
		else:
			# Attendre quelques frames pour que la scène se stabilise
			await get_tree().process_frame
			await get_tree().process_frame
	else:
		await get_tree().process_frame
		await get_tree().process_frame
	
	global_position = Global.player_return_position
	Global.player_return_position = Vector2.ZERO
	
	visible = true
