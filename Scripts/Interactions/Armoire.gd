extends Sprite2D

const ARMOIRE_FERMEE_TEXTURE := preload("res://Spritesheet/Armoire/sprite_0.webp")
const ARMOIRE_OUVERTE_TEXTURE := preload("res://Spritesheet/Armoire/sprite_1.webp")

var is_opened: bool = false
var key_node: Node2D = null

func _ready() -> void:
	add_to_group("Armoires")
	if texture == null:
		texture = ARMOIRE_FERMEE_TEXTURE
	_update_key_state()

func interact() -> void:
	if is_opened:
		return
	texture = ARMOIRE_OUVERTE_TEXTURE
	is_opened = true
	_update_key_state()
	enable_player_movement()

func _update_key_state() -> void:
	if key_node == null:
		key_node = get_node_or_null("Key")
	if key_node == null:
		return
	key_node.visible = is_opened
	if "collectable" in key_node:
		key_node.collectable = is_opened
	if "can_collect" in key_node:
		key_node.can_collect = is_opened

func enable_player_movement() -> void:
	call_deferred("_enable_player_movement_deferred")

func _enable_player_movement_deferred() -> void:
	var joueur := get_tree().get_first_node_in_group("Joueur")
	if joueur == null:
		var root := get_tree().root
		joueur = root.find_child("Joueur", true, false)
	if joueur != null:
		if "canMove" in joueur:
			joueur.canMove = true
		else:
			print("Erreur : le joueur n'a pas la propriété canMove")
	else:
		print("Erreur : joueur introuvable pour remettre canMove à true")

