extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var canMove = true

func _ready() -> void:
	#$AnimatedSprite2D.play("new_animation")
	canMove = true
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Interract"):
		InteractionManager.handle_interaction(global_position)

func _physics_process(_delta: float) -> void:

	# ============== MOUVEMENTS ==============
	
	if canMove :
		
		# Mouvement verticaux

		var axeX := Input.get_axis("Gauche", "Droite")
		if axeX:
			velocity.x = axeX * SPEED
			#$AnimatedSprite2D.play("walk")
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
		
		# Mouvement horizontaux
		
		var axeY := Input.get_axis("Haut", "Bas")
		if axeY:
			velocity.y = axeY * SPEED
		else:
			velocity.y = move_toward(velocity.y, 0, SPEED)

		move_and_slide()
