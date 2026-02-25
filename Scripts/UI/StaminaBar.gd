extends Control

@onready var stamina_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var player := get_tree().get_first_node_in_group("Joueur")

const DISPLAY_SCALE := 0.08

func _ready() -> void:
	visible = true
	_on_stamina_changed(3)
	
	await get_tree().process_frame
	
	if player != null and player.has_signal("stamina_changed"):
		player.stamina_changed.connect(_on_stamina_changed)
		if "stamina" in player:
			_on_stamina_changed(player.stamina)
	else:
		print("StaminaBar: Joueur non trouvé ou signal manquant")

func _on_stamina_changed(new_stamina: int) -> void:
	stamina_sprite.frame = new_stamina
	
