extends Node2D

# Script à attacher aux objets collectables dans le monde
# Quand le joueur interagit avec (F), l'item est automatiquement ajouté à l'inventaire
# Quand l'objet est ciblé (le plus proche), le flag view-item.png s'affiche au-dessus pour indiquer qu'on peut le ramasser

const VIEW_ITEM_TEXTURE = preload("res://Sprites/items/view-item.png")
const INDICATOR_OFFSET := Vector2(0, -28)
const INDICATOR_SCALE := Vector2(0.3, 0.3)

@export var item_resource: Item # Ressource Item à créer dans l'éditeur
@export var quantity: int = 1 # Quantité à donner
@export var collectable: bool = true # Si false, l'item ne peut pas être collecté
@export var can_collect: bool = true # Si false, l'item ne peut pas être collecté (contrôle logique externe)
@export var item_name_override: String = "" # Nom personnalisé pour l'item (pour le stacking)
@export var progress_key_on_collect: String = "" # Si défini, met Global.progress[key] = true à la collecte

var is_collected: bool = false
var indicator_sprite: Sprite2D = null
var is_targeted: bool = false

func _ready() -> void:
	add_to_group("CollectableItems")
	
	# Si pas de ressource Item définie, créer un item par défaut
	if item_resource == null:
		item_resource = Item.new()
		# Utiliser item_name_override si défini, sinon utiliser le nom du node
		if item_name_override != "":
			item_resource.item_name = item_name_override
		else:
			item_resource.item_name = name
		item_resource.item_description = "Un objet collectable"
		item_resource.max_stack = 5
		print("Item créé par défaut pour : ", name, " - Nom: ", item_resource.item_name)
	
	# Récupérer automatiquement le sprite de l'objet si item_texture n'est pas défini
	if item_resource.item_texture == null:
		var texture := get_sprite_texture()
		if texture != null:
			item_resource.item_texture = texture
	
	# Récupérer les SpriteFrames si un AnimatedSprite2D existe
	if item_resource.sprite_frames == null:
		var animated_sprite := get_node_or_null("AnimatedSprite2D")
		if animated_sprite != null and animated_sprite.sprite_frames != null:
			item_resource.sprite_frames = animated_sprite.sprite_frames
			if animated_sprite.animation != "":
				item_resource.animation_name = animated_sprite.animation

	# Capturer l'apparence "dans le monde" (scale + lumière) pour pouvoir re-spawn l'objet après un drop.
	if item_resource != null:
		item_resource.world_scale = scale
		# Harmoniser la taille d'icône inventaire pour ces matériaux.
		if item_resource.item_name == "Fer" or item_resource.item_name == "Silex" or item_resource.item_name == "briqué":
			item_resource.inventory_icon_scale = Vector2(0.7, 0.7)
		var world_light := _find_first_point_light_2d()
		if world_light != null and world_light.texture != null:
			item_resource.drop_light_texture = world_light.texture
			item_resource.drop_light_color = world_light.color
			item_resource.drop_light_energy = world_light.energy
			item_resource.drop_light_texture_scale = world_light.texture_scale
			item_resource.drop_light_position = world_light.position
			item_resource.drop_light_scale = world_light.scale
	
	# S'assurer que max_stack est au moins 5 si l'item est créé automatiquement
	# ou si item_name_override est défini (pour permettre le stacking)
	if item_name_override != "":
		# Si un nom personnalisé est défini, utiliser ce nom pour le stacking
		if item_resource.item_name != item_name_override:
			item_resource.item_name = item_name_override
		if item_resource.max_stack < 5:
			item_resource.max_stack = 5
	
	# Indicateur flottant (view-item.png) au-dessus de l'objet quand le joueur le cible
	indicator_sprite = Sprite2D.new()
	indicator_sprite.name = "IndicatorSprite"
	indicator_sprite.texture = VIEW_ITEM_TEXTURE
	indicator_sprite.set_as_top_level(true)
	indicator_sprite.global_position = global_position + INDICATOR_OFFSET
	indicator_sprite.centered = true
	indicator_sprite.global_rotation = 0.0
	indicator_sprite.global_scale = INDICATOR_SCALE
	indicator_sprite.z_index = 10000
	indicator_sprite.visible = false
	add_child(indicator_sprite)

func _process(_delta: float) -> void:
	_update_indicator_transform()

func _update_indicator_transform() -> void:
	if indicator_sprite == null or not indicator_sprite.visible:
		return
	indicator_sprite.global_position = global_position + INDICATOR_OFFSET
	indicator_sprite.global_rotation = 0.0
	indicator_sprite.global_scale = INDICATOR_SCALE

func _find_first_point_light_2d() -> PointLight2D:
	var direct := get_node_or_null("PointLight2D")
	if direct is PointLight2D:
		return direct

	for child in get_children():
		if child is PointLight2D:
			return child
		if child is Node:
			var nested := _find_first_point_light_2d_in(child)
			if nested != null:
				return nested
	
	return null

func _find_first_point_light_2d_in(root: Node) -> PointLight2D:
	for child in root.get_children():
		if child is PointLight2D:
			return child
		if child is Node:
			var nested := _find_first_point_light_2d_in(child)
			if nested != null:
				return nested
	return null

func collect() -> bool:
	"""Tente de collecter l'item. Retourne true si réussi"""
	if not collectable or not can_collect or is_collected:
		enable_player_movement()
		return false
	
	var inventaire: Node = get_tree().get_first_node_in_group("Inventaire")
	if inventaire == null:
		print("Erreur : Inventaire introuvable")
		enable_player_movement()
		return false
	
	# Vérifier que l'item_resource est valide
	if item_resource == null:
		print("Erreur : item_resource est null pour ", name)
		enable_player_movement()
		return false
	
	print("Tentative de collecte : ", item_resource.item_name, " (x", quantity, ")")
	
	# Ajouter l'item à l'inventaire
	var success: bool = inventaire.add_item(item_resource, quantity)
	
	if success:
		is_collected = true
		if progress_key_on_collect != "":
			Global.progress[progress_key_on_collect] = true
		print("Item collecté : ", item_resource.item_name, " (x", quantity, ")")
		# Cacher ou supprimer l'objet du monde
		queue_free()
		# Remettre canMove à true après la collecte (avant queue_free pour être sûr)
		enable_player_movement()
		return true
	else:
		print("Impossible de collecter l'item : inventaire plein")
		enable_player_movement()
		return false

func enable_player_movement() -> void:
	"""Remet canMove à true pour le joueur"""
	call_deferred("_enable_player_movement_deferred")

func _enable_player_movement_deferred() -> void:
	"""Remet canMove à true pour le joueur (appelé en différé)"""
	var joueur: Node = get_tree().get_first_node_in_group("Joueur")
	if joueur == null:
		joueur = get_tree().current_scene.get_node_or_null("Joueur")
	if joueur != null and "canMove" in joueur:
		joueur.canMove = true
		print("Mouvement réactivé pour le joueur")
	else:
		push_warning("CollectableItem: Impossible de trouver le joueur pour réactiver le mouvement")

func can_be_collected() -> bool:
	"""Vérifie si l'item peut être collecté"""
	return collectable and can_collect and not is_collected

func get_sprite_texture() -> Texture2D:
	"""Récupère le sprite de l'objet (Sprite2D, AnimatedSprite2D, ou TextureRect)"""
	# Cas 1: le script est directement sur un Sprite2D
	if "texture" in self and self.texture != null:
		return self.texture
	
	# Cas 2: le script est directement sur un AnimatedSprite2D
	if "sprite_frames" in self and self.sprite_frames != null:
		var self_anim_name: String = "default"
		if "animation" in self and self.animation != "":
			self_anim_name = self.animation
		if self.sprite_frames.has_animation(self_anim_name) and self.sprite_frames.get_frame_count(self_anim_name) > 0:
			return self.sprite_frames.get_frame_texture(self_anim_name, 0)

	# Chercher un AnimatedSprite2D (priorité car souvent plus visible)
	var animated_sprite := get_node_or_null("AnimatedSprite2D")
	if animated_sprite != null and animated_sprite.sprite_frames != null:
		var frames: SpriteFrames = animated_sprite.sprite_frames
		var anim_name: String = "default"
		if animated_sprite.animation != "":
			anim_name = animated_sprite.animation
		if frames.has_animation(anim_name) and frames.get_frame_count(anim_name) > 0:
			return frames.get_frame_texture(anim_name, 0)
	
	# Chercher un Sprite2D enfant
	var sprite := get_node_or_null("Sprite2D")
	if sprite != null and sprite.texture != null:
		return sprite.texture
	
	# Chercher récursivement dans tous les enfants
	for child in get_children():
		if child is AnimatedSprite2D:
			var child_animated := child as AnimatedSprite2D
			if child_animated.sprite_frames != null:
				var frames: SpriteFrames = child_animated.sprite_frames
				var anim_name: String = "default"
				if child_animated.animation != "":
					anim_name = child_animated.animation
				if frames.has_animation(anim_name) and frames.get_frame_count(anim_name) > 0:
					return frames.get_frame_texture(anim_name, 0)
		elif child is Sprite2D:
			var child_sprite := child as Sprite2D
			if child_sprite.texture != null:
				return child_sprite.texture
		elif child is TextureRect:
			var child_texture_rect := child as TextureRect
			if child_texture_rect.texture != null:
				return child_texture_rect.texture
	
	return null

func show_indicator() -> void:
	"""Affiche le flag (view-item) au-dessus de l'objet pour indiquer qu'on peut le ramasser"""
	if indicator_sprite != null:
		_update_indicator_transform()
		indicator_sprite.visible = true
		is_targeted = true

func hide_indicator() -> void:
	"""Cache le flag"""
	if indicator_sprite != null:
		indicator_sprite.visible = false
		is_targeted = false
