extends Node2D

# Script à attacher aux objets collectables dans le monde
# Quand le joueur interagit avec (F), l'item est automatiquement ajouté à l'inventaire

@export var item_resource : Item  # Ressource Item à créer dans l'éditeur
@export var quantity : int = 1  # Quantité à donner
@export var collectable : bool = true  # Si false, l'item ne peut pas être collecté

var is_collected : bool = false

func _ready() -> void:
	add_to_group("CollectableItems")
	
	# Si pas de ressource Item définie, créer un item par défaut
	if item_resource == null:
		item_resource = Item.new()
		item_resource.item_name = name
		item_resource.item_description = "Un objet collectable"
		item_resource.max_stack = 1
		print("Item créé par défaut pour : ", name, " - Nom: ", item_resource.item_name)
	
	# Récupérer automatiquement le sprite de l'objet si item_texture n'est pas défini
	if item_resource.item_texture == null:
		item_resource.item_texture = get_sprite_texture()

func collect() -> bool:
	"""Tente de collecter l'item. Retourne true si réussi"""
	if not collectable or is_collected:
		enable_player_movement()
		return false
	
	var inventaire = get_tree().get_first_node_in_group("Inventaire")
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
	var success : bool = inventaire.add_item(item_resource, quantity)
	
	if success:
		is_collected = true
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
	var joueur = get_tree().get_first_node_in_group("Joueur")
	if joueur == null:
		joueur = get_tree().current_scene.get_node_or_null("Joueur")
	if joueur != null and "canMove" in joueur:
		joueur.canMove = true
		print("Mouvement réactivé pour le joueur")
	else:
		push_warning("CollectableItem: Impossible de trouver le joueur pour réactiver le mouvement")

func can_be_collected() -> bool:
	"""Vérifie si l'item peut être collecté"""
	return collectable and not is_collected

func get_sprite_texture() -> Texture2D:
	"""Récupère le sprite de l'objet (Sprite2D, AnimatedSprite2D, ou TextureRect)"""
	# Chercher un AnimatedSprite2D (priorité car souvent plus visible)
	var animated_sprite := get_node_or_null("AnimatedSprite2D")
	if animated_sprite != null and animated_sprite.sprite_frames != null:
		var frames : SpriteFrames = animated_sprite.sprite_frames
		var anim_name : String = "default"
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
				var frames : SpriteFrames = child_animated.sprite_frames
				var anim_name : String = "default"
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
