extends Sprite2D

const COFFRE_FERME_TEXTURE = preload("res://Spritesheet/Coffre/sprite_coffre0.png")
const COFFRE_OUVERT_TEXTURE = preload("res://Spritesheet/Coffre/sprite_coffre2.png")
const VIEW_ITEM_TEXTURE := preload("res://Spritesheet/items/view-item.png")
const INDICATOR_OFFSET := Vector2(0, -28)
const INDICATOR_SCALE := Vector2(0.3, 0.3)

var is_opened : bool = false
var _indicator_sprite: Sprite2D = null

func _ready() -> void:
	# Ajouter au groupe pour la détection
	add_to_group("Coffres")
	
	# Initialiser avec le sprite fermé seulement si pas déjà défini
	if texture == null:
		texture = COFFRE_FERME_TEXTURE
	
	_setup_indicator()

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
	
	# Changer le sprite pour le coffre ouvert
	texture = COFFRE_OUVERT_TEXTURE
	is_opened = true

func enable_player_movement() -> void:
	# Utiliser call_deferred pour s'assurer que ça s'exécute au bon moment
	call_deferred("_enable_player_movement_deferred")

func _enable_player_movement_deferred() -> void:
	# Chercher le joueur et remettre canMove à true
	var joueur: Node = get_tree().get_first_node_in_group("Joueur")
	if joueur == null:
		# Essayer de trouver le joueur par son nom dans la scène racine
		var root: Node = get_tree().root
		joueur = root.find_child("Joueur", true, false)
	
	if joueur != null:
		if "canMove" in joueur:
			joueur.canMove = true
		else:
			print("Erreur : le joueur n'a pas la propriété canMove")
	else:
		print("Erreur : joueur introuvable pour remettre canMove à true")
