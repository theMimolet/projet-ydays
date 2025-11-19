extends CharacterBody2D

const SPEED = 100.0

@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D
var canMove : bool = true

func _ready() -> void:
	if Dialogic.timeline_ended.connect(_on_timeline_ended) != OK:
		print("Erreur : impossible de se connecter au signal timeline_ended de Dialogic")

func Mouvement() -> void :
	var input_direction : Vector2 = Input.get_vector("Gauche", "Droite", "Haut", "Bas")
	velocity = input_direction * SPEED
	Animate()
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Interract"):
		canMove = false
		InteractionManager.handle_interaction(global_position)

func _physics_process(_delta: float) -> void:

	# ============== MOUVEMENTS ==============
	
	if canMove :
		Mouvement()
	else :
		velocity = Vector2(0, 0)
		sprite.stop()

	move_and_slide()

func Animate() -> void : 
	if velocity.x > 0:
		sprite.play("marche-droite")
	elif  velocity.x < 0 :
		sprite.play("marche-gauche")
	elif  velocity.y > 0:
		sprite.play("marche-devant")
	elif  velocity.y < 0:
		sprite.play("marche-derriere")
	else:
		sprite.stop()

func _on_timeline_ended() -> void:
	canMove = true
