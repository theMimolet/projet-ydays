extends Sprite2D

const ARMOIRE_FERMEE_TEXTURE := preload("res://Spritesheet/Armoire/sprite_0.webp")
const ARMOIRE_OUVERTE_TEXTURE := preload("res://Spritesheet/Armoire/sprite_1.webp")
const VIEW_ITEM_TEXTURE := preload("res://Spritesheet/items/view-item.png")
const INDICATOR_OFFSET := Vector2(0, -28)
const INDICATOR_SCALE := Vector2(0.3, 0.3)

@export var progress_key: String = "zone1_armoire_ouverte"
@export var key_collected_progress_key: String = "zone1_clef_trouvee"

var is_opened: bool = false
var key_node: Node2D = null
var _indicator_sprite: Sprite2D = null

func _ready() -> void:
	add_to_group("Armoires")
	if texture == null:
		texture = ARMOIRE_FERMEE_TEXTURE
	_setup_indicator()
	_update_key_state()
	if Global.progress.get(progress_key, false):
		setState(true)

func setState(opened: bool) -> void:
	is_opened = opened
	texture = ARMOIRE_OUVERTE_TEXTURE if opened else ARMOIRE_FERMEE_TEXTURE
	hide_indicator()
	_update_key_state()

func _setup_indicator() -> void:
	_indicator_sprite = Sprite2D.new()
	_indicator_sprite.name = "IndicatorSprite"
	_indicator_sprite.texture = VIEW_ITEM_TEXTURE
	_indicator_sprite.set_as_top_level(true)
	_indicator_sprite.global_position = global_position + INDICATOR_OFFSET
	_indicator_sprite.centered = true
	_indicator_sprite.global_rotation = 0.0
	_indicator_sprite.global_scale = INDICATOR_SCALE
	_indicator_sprite.z_index = 10000
	_indicator_sprite.visible = false
	add_child(_indicator_sprite)

func show_indicator() -> void:
	if _indicator_sprite != null:
		_update_indicator_transform()
		_indicator_sprite.visible = true

func hide_indicator() -> void:
	if _indicator_sprite != null:
		_indicator_sprite.visible = false

func _process(_delta: float) -> void:
	_update_indicator_transform()

func _update_indicator_transform() -> void:
	if _indicator_sprite == null or not _indicator_sprite.visible:
		return
	_indicator_sprite.global_position = global_position + INDICATOR_OFFSET
	_indicator_sprite.global_rotation = 0.0
	_indicator_sprite.global_scale = INDICATOR_SCALE

func interact() -> void:
	if is_opened:
		return
	setState(true)
	Global.progress[progress_key] = true
	enable_player_movement()

func _update_key_state() -> void:
	if key_node == null:
		key_node = get_node_or_null("Key")
	if key_node == null:
		return

	if "progress_key_on_collect" in key_node:
		key_node.progress_key_on_collect = key_collected_progress_key

	if Global.progress.get(key_collected_progress_key, false):
		key_node.queue_free()
		key_node = null
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
