extends Node

const Item = preload("res://Scripts/Items/Item.gd")

# Registre d'items prédéfinis pour la console
var items_registry : Dictionary = {}

func _ready() -> void:
	# Initialiser le registre avec les items de base
	register_default_items()

func register_default_items() -> void:
	"""Enregistre les items par défaut"""
	
	# Torche
	var torch = Item.new()
	torch.item_name = "torch"
	torch.item_description = "Une torche qui éclaire dans l'obscurité"
	torch.max_stack = 10
	torch.item_type = "tool"
	# torch.item_texture = preload("res://path/to/torch.png")  # À ajouter plus tard
	register_item("torch", torch)
	
	# Pomme
	var apple = Item.new()
	apple.item_name = "apple"
	apple.item_description = "Une pomme rouge et juteuse"
	apple.max_stack = 20
	apple.item_type = "consumable"
	# apple.item_texture = preload("res://path/to/apple.png")  # À ajouter plus tard
	register_item("apple", apple)
	
	# Potion de soin
	var health_potion = Item.new()
	health_potion.item_name = "health_potion"
	health_potion.item_description = "Une potion qui restaure la santé"
	health_potion.max_stack = 5
	health_potion.item_type = "consumable"
	register_item("health_potion", health_potion)
	
	# Épée
	var sword = Item.new()
	sword.item_name = "sword"
	sword.item_description = "Une épée tranchante"
	sword.max_stack = 1
	sword.item_type = "weapon"
	register_item("sword", sword)

func register_item(name: String, item: Item) -> void:
	"""Enregistre un item dans le registre"""
	items_registry[name.to_lower()] = item

func get_item(name: String) -> Item:
	"""Récupère un item par son nom. Retourne null si non trouvé"""
	var key = name.to_lower()
	if key in items_registry:
		# Créer une copie de l'item pour éviter de modifier l'original
		var original = items_registry[key]
		var copy = Item.new()
		copy.item_name = original.item_name
		copy.item_description = original.item_description
		copy.item_texture = original.item_texture
		copy.max_stack = original.max_stack
		copy.item_type = original.item_type
		return copy
	return null

func get_all_item_names() -> Array:
	"""Retourne la liste de tous les noms d'items disponibles"""
	return items_registry.keys()
