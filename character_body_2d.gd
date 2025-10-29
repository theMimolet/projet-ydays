extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0


func _physics_process(delta: float) -> void:

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var axeX := Input.get_axis("Gauche", "Droite")
	if axeX:
		velocity.x = axeX * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	var axeY := Input.get_axis("Haut", "Bas")
	if axeY:
		velocity.y = axeY * SPEED
	else:
		velocity.y = move_toward(velocity.y, 0, SPEED)

	move_and_slide()
