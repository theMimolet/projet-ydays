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

func collect() -> bool:
	"""Tente de collecter l'item. Retourne true si réussi"""
	if not collectable or is_collected:
		return false
	
	var inventaire = get_tree().get_first_node_in_group("Inventaire")
	if inventaire == null:
		print("Erreur : Inventaire introuvable")
		# Remettre canMove à true même en cas d'erreur
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
		# Remettre canMove à true après la collecte
		enable_player_movement()
		# Cacher ou supprimer l'objet du monde
		queue_free()
		return true
	else:
		print("Impossible de collecter l'item : inventaire plein")
		# Remettre canMove à true même si l'inventaire est plein
		enable_player_movement()
		return false

func enable_player_movement() -> void:
	"""Remet canMove à true pour le joueur"""
	var joueur = get_tree().get_first_node_in_group("Joueur")
	if joueur != null and "canMove" in joueur:
		joueur.canMove = true

func can_be_collected() -> bool:
	"""Vérifie si l'item peut être collecté"""
	return collectable and not is_collected
