extends Resource
class_name Item

@export var item_name : String = ""
@export var item_description : String = ""
@export var item_texture : Texture2D
@export var max_stack : int = 1  # Nombre maximum d'items empilables
@export var item_type : String = "misc"  # Type d'item (weapon, consumable, misc, etc.)
@export var sprite_frames : SpriteFrames = null  # SpriteFrames pour les animations (optionnel)
@export var animation_name : String = "default"  # Nom de l'animation à utiliser

func _init(name: String = "", description: String = "", texture: Texture2D = null, stack: int = 1, type: String = "misc") -> void:
	item_name = name
	item_description = description
	item_texture = texture
	max_stack = stack
	item_type = type
