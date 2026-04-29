extends Sprite2D

const COFFRE_FERME_TEXTURE = preload("res://Sprites/Coffre/sprite_coffre0.png")
const COFFRE_OUVERT_TEXTURE = preload("res://Sprites/Coffre/sprite_coffre2.png")
const VIEW_ITEM_TEXTURE := preload("res://Sprites/items/view-item.png")
const INDICATOR_OFFSET := Vector2(0, -28)
const INDICATOR_SCALE := Vector2(0.3, 0.3)

var is_opened: bool = false
var _indicator_sprite: Sprite2D = null

@export var item_resource: Item # Item Resource à déposer au sol
@export var quantity: int = 1
@export var progress_key: String = '' # Optionnel: si vide, on calcule une clé stable
@export var drop_offset_x: float = -24.0 # Déplacer vers la gauche (comme demandé)
@export var drop_offset_y: float = 0.0 # Déplacement vertical (0 => pas de décalage Y)
@export var drop_scale_multiplier: float = 0.7 # Réduire la taille du drop (comme demandé)

func _get_effective_progress_key() -> String:
	if progress_key != '':
		return progress_key
	# Fallback: clé stable basée sur la room courante + le chemin du noeud.
	# Utile pour éviter que tous les coffres partagent la même clé vide.
	var room_path := Global.currentRoom if 'currentRoom' in Global else ''
	return 'coffre_opened:' + room_path + ':' + str(get_path())

func _ready() -> void:
	# Ajouter au groupe pour la détection
	add_to_group("Coffres")

	_setup_indicator()

	var effective_key := _get_effective_progress_key()
	if Global.progress.get(effective_key, false):
		is_opened = true
		texture = COFFRE_OUVERT_TEXTURE
		hide_indicator()
	elif texture == null:
		# Initialiser avec le sprite fermé seulement si pas déjà défini
		texture = COFFRE_FERME_TEXTURE
	
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

	# Drop de l'item au sol (uniquement la première ouverture)
	if item_resource != null:
		var inventaire: Node = get_tree().get_first_node_in_group("Inventaire")
		var rooms: Node = get_tree().current_scene.get_node_or_null("Room")
		if inventaire != null and inventaire.has_method("create_collectable_item") and rooms != null:
			var drop_global := global_position + Vector2(drop_offset_x, drop_offset_y)
			var drop_local := drop_global
			# create_collectable_item() affecte `collectable.position`, donc on doit fournir la position en espace local du node parent.
			if rooms is Node2D:
				drop_local = (rooms as Node2D).to_local(drop_global)
			var collectable_item: Node2D = inventaire.create_collectable_item(item_resource, drop_local, quantity)
			rooms.add_child(collectable_item)
			collectable_item.scale *= drop_scale_multiplier
			# Évite que l'item se fasse "masquer" par le coffre sprite.
			if "z_index" in collectable_item:
				collectable_item.z_index = z_index + 1
			# Évite un ramassage immédiat lors du même appui que l'ouverture.
			if "can_collect" in collectable_item:
				collectable_item.can_collect = false
				var timer := get_tree().create_timer(0.1)
				timer.timeout.connect(func():
					if is_instance_valid(collectable_item) and "can_collect" in collectable_item:
						collectable_item.can_collect = true
				)
		else:
			print("Coffre: impossible de déposer l'item au sol (Inventaire/Room manquants).")

	Global.progress[_get_effective_progress_key()] = true
	hide_indicator()

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
