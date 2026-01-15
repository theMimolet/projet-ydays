extends Node

# Exemple d'utilisation du système d'inventaire
# Vous pouvez créer vos items ici ou les charger depuis des ressources

static func create_test_item() -> Item:
	"""Crée un item de test"""
	var item = Item.new()
	item.item_name = "Pomme"
	item.item_description = "Une pomme rouge et juteuse"
	item.max_stack = 10
	item.item_type = "consumable"
	# item.item_texture = preload("res://path/to/apple.png")  # Ajoutez votre texture
	return item

static func add_test_item_to_inventory() -> void:
	"""Ajoute un item de test à l'inventaire"""
	var inventaire = Engine.get_main_loop().root.get_tree().get_first_node_in_group("Inventaire")
	if inventaire != null:
		var item = create_test_item()
		inventaire.add_item(item, 5)
