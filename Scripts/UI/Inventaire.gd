extends CanvasLayer

const SLOT_SCENE = preload("res://Scenes/UI/InventorySlot.tscn")
const Item = preload("res://Scripts/Items/Item.gd")
const INVENTORY_SIZE : int = 16  # Nombre de slots d'inventaire

@onready var inventaire_panel : Panel = $InventairePanel
@onready var inventaire_container : GridContainer = $InventairePanel/InventaireContainer

var is_open : bool = false
var joueur : Node = null
var slots : Array = []
var dragged_slot = null

signal inventaire_opened
signal inventaire_closed

func _ready() -> void:
	# Ajouter au groupe pour faciliter la recherche
	add_to_group("Inventaire")
	
	# Chercher le joueur
	joueur = get_tree().get_first_node_in_group("Joueur")
	
	# Créer les slots d'inventaire
	create_inventory_slots()
	
	# Cacher l'inventaire au départ
	inventaire_panel.visible = false
	is_open = false

func create_inventory_slots() -> void:
	"""Crée tous les slots d'inventaire"""
	for i in range(INVENTORY_SIZE):
		var slot = SLOT_SCENE.instantiate()
		slot.slot_index = i
		slot.add_to_group("InventorySlot")
		slot.slot_clicked.connect(_on_slot_clicked)
		slot.slot_dropped.connect(_on_slot_dropped)
		inventaire_container.add_child(slot)
		slots.append(slot)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_TAB:
			toggle_inventaire()

func toggle_inventaire() -> void:
	is_open = !is_open
	inventaire_panel.visible = is_open
	
	if is_open:
		open_inventaire()
	else:
		close_inventaire()

func open_inventaire() -> void:
	inventaire_opened.emit()
	if joueur != null and "canMove" in joueur:
		joueur.canMove = false

func close_inventaire() -> void:
	inventaire_closed.emit()
	if joueur != null and "canMove" in joueur:
		joueur.canMove = true

# ============== GESTION DES ITEMS ==============

func add_item(item, quantity: int = 1) -> bool:
	"""Ajoute un item à l'inventaire. Retourne true si réussi"""
	# Chercher un slot avec le même item qui peut encore en contenir
	for slot in slots:
		if not slot.is_empty() and slot.item.item_name == item.item_name:
			var remaining : int = slot.item.max_stack - slot.quantity
			if remaining > 0:
				var to_add : int = min(quantity, remaining)
				slot.quantity += to_add
				slot.update_display()
				quantity -= to_add
				if quantity <= 0:
					return true
	
	# Chercher un slot vide
	for slot in slots:
		if slot.is_empty():
			var to_add : int = min(quantity, item.max_stack)
			slot.set_item(item, to_add)
			quantity -= to_add
			if quantity <= 0:
				return true
	
	# Si on arrive ici, l'inventaire est plein
	print("Inventaire plein !")
	return false

func remove_item(item_name: String, quantity: int = 1) -> bool:
	"""Retire un item de l'inventaire. Retourne true si réussi"""
	var remaining : int = quantity
	
	for slot in slots:
		if not slot.is_empty() and slot.item.item_name == item_name:
			var to_remove : int = min(remaining, slot.quantity)
			slot.remove_item(to_remove)
			remaining -= to_remove
			if remaining <= 0:
				return true
	
	return remaining <= 0

func has_item(item_name: String, quantity: int = 1) -> bool:
	"""Vérifie si l'inventaire contient l'item en quantité suffisante"""
	var total = 0
	for slot in slots:
		if not slot.is_empty() and slot.item.item_name == item_name:
			total += slot.quantity
	return total >= quantity

func get_item_count(item_name: String) -> int:
	"""Retourne le nombre total d'un item dans l'inventaire"""
	var total : int = 0
	for slot in slots:
		if not slot.is_empty() and slot.item.item_name == item_name:
			total += slot.quantity
	return total

# ============== DRAG & DROP ==============

func _on_slot_clicked(slot) -> void:
	"""Gère le clic sur un slot"""
	if dragged_slot == null and not slot.is_empty():
		# Commencer le drag
		dragged_slot = slot
		print("Début du drag: ", slot.item.item_name)

func _on_slot_dropped(source_slot, target_slot) -> void:
	"""Gère le drop d'un slot vers un autre"""
	if source_slot == null or target_slot == null:
		dragged_slot = null
		return
	
	# Si le slot cible est vide, on déplace l'item
	if target_slot.is_empty():
		target_slot.set_item(source_slot.item, source_slot.quantity)
		source_slot.clear_slot()
	# Si c'est le même item, on empile
	elif target_slot.item.item_name == source_slot.item.item_name:
		var total : int = target_slot.quantity + source_slot.quantity
		if total <= target_slot.item.max_stack:
			target_slot.quantity = total
			target_slot.update_display()
			source_slot.clear_slot()
		else:
			# Échanger les quantités
			var max_stack : int = target_slot.item.max_stack
			var excess : int = total - max_stack
			target_slot.quantity = max_stack
			source_slot.quantity = excess
			target_slot.update_display()
			source_slot.update_display()
	# Sinon, on échange les items
	else:
		var temp_item = target_slot.item
		var temp_quantity : int = target_slot.quantity
		target_slot.set_item(source_slot.item, source_slot.quantity)
		source_slot.set_item(temp_item, temp_quantity)
	
	dragged_slot = null
	print("Drop effectué")
