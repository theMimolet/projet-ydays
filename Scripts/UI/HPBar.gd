extends Control

@onready var hp_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var player := get_tree().get_first_node_in_group("Joueur")

func _ready() -> void:
	visible = true
	
	await get_tree().process_frame
	
	if player != null and player.has_signal("hp_changed"):
		player.hp_changed.connect(_on_hp_changed)
		if "current_hp" in player and "MAX_HP" in player:
			_on_hp_changed(player.current_hp, player.MAX_HP)
	else:
		print("HPBar: Joueur non trouvé ou signal manquant")

func _on_hp_changed(new_hp: int, max_hp: int) -> void:
	if hp_sprite == null or max_hp <= 0:
		return
	
	if new_hp >= 100:
		hp_sprite.frame = 0  # sprite0
	elif new_hp >= 90:
		hp_sprite.frame = 1  # sprite1
	elif new_hp >= 80:
		hp_sprite.frame = 2  # sprite2
	elif new_hp >= 65:
		hp_sprite.frame = 3  # sprite3
	elif new_hp >= 50:
		hp_sprite.frame = 4  # sprite4
	elif new_hp >= 40:
		hp_sprite.frame = 5  # sprite5
	elif new_hp >= 25:
		hp_sprite.frame = 6  # sprite6
	elif new_hp >= 10:
		hp_sprite.frame = 7  # sprite7
	else:
		hp_sprite.frame = 8  # sprite8 (0 HP)
