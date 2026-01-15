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
var split_mode : bool = false

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
		slot.slot_right_clicked.connect(_on_slot_right_clicked)
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
		# Vérifier si Alt est pressé pour le split
		if Input.is_key_pressed(KEY_ALT) and slot.quantity > 1:
			# Mode split : créer un slot temporaire avec 1 item
			split_mode = true
			# Créer une copie du slot pour le drag
			var temp_slot = SLOT_SCENE.instantiate()
			temp_slot.set_item(slot.item, 1)
			temp_slot.add_to_group("InventorySlot")
			temp_slot.slot_dropped.connect(_on_slot_dropped)
			inventaire_container.add_child(temp_slot)
			# Réduire la quantité du slot source
			slot.split_stack()
			dragged_slot = temp_slot
			temp_slot.set_dragging(true)
			print("Split: 1 item de ", slot.item.item_name)
		else:
			# Mode drag normal
			split_mode = false
			dragged_slot = slot
			slot.set_dragging(true)
			print("Début du drag: ", slot.item.item_name)

func _on_slot_dropped(source_slot, target_slot) -> void:
	"""Gère le drop d'un slot vers un autre"""
	if source_slot == null or target_slot == null:
		_cleanup_drag(source_slot)
		return
	
	# Si le slot source est un slot temporaire de split, le supprimer après le drop
	var is_temp_slot : bool = split_mode and source_slot not in slots
	
	# Si le slot cible est vide, on déplace l'item
	if target_slot.is_empty():
		target_slot.set_item(source_slot.item, source_slot.quantity)
		if is_temp_slot:
			source_slot.queue_free()
		else:
			source_slot.clear_slot()
	# Si c'est le même item, on empile
	elif target_slot.item.item_name == source_slot.item.item_name:
		var total : int = target_slot.quantity + source_slot.quantity
		if total <= target_slot.item.max_stack:
			target_slot.quantity = total
			target_slot.update_display()
			if is_temp_slot:
				source_slot.queue_free()
			else:
				source_slot.clear_slot()
		else:
			# Échanger les quantités
			var max_stack : int = target_slot.item.max_stack
			var excess : int = total - max_stack
			target_slot.quantity = max_stack
			if is_temp_slot:
				# Si c'est un slot temporaire, créer un nouveau slot pour l'excès
				var excess_slot = SLOT_SCENE.instantiate()
				excess_slot.set_item(source_slot.item, excess)
				excess_slot.add_to_group("InventorySlot")
				excess_slot.slot_clicked.connect(_on_slot_clicked)
				excess_slot.slot_dropped.connect(_on_slot_dropped)
				excess_slot.slot_right_clicked.connect(_on_slot_right_clicked)
				# Trouver un slot vide pour le placer
				for slot in slots:
					if slot.is_empty():
						slot.set_item(source_slot.item, excess)
						break
				source_slot.queue_free()
			else:
				source_slot.quantity = excess
				source_slot.update_display()
			target_slot.update_display()
	# Sinon, on échange les items
	else:
		var temp_item = target_slot.item
		var temp_quantity : int = target_slot.quantity
		target_slot.set_item(source_slot.item, source_slot.quantity)
		if is_temp_slot:
			# Si c'est un slot temporaire, créer un nouveau slot pour l'item échangé
			for slot in slots:
				if slot.is_empty():
					slot.set_item(temp_item, temp_quantity)
					break
			source_slot.queue_free()
		else:
			source_slot.set_item(temp_item, temp_quantity)
	
	_cleanup_drag(source_slot)
	print("Drop effectué")

func _cleanup_drag(slot) -> void:
	"""Nettoie l'état de drag"""
	if slot != null and slot.has_method("set_dragging"):
		slot.set_dragging(false)
	dragged_slot = null
	split_mode = false
# ============== DROP SUR LA MAP ==============

func _on_slot_right_clicked(slot) -> void:
	"""Gère le clic droit sur un slot pour drop l'item sur la map"""
	if slot.is_empty():
		return
	
	drop_item_on_map(slot)

func drop_item_on_map(slot) -> void:
	"""Pose un item sur la map à la position du joueur"""
	if slot.is_empty() or joueur == null:
		return
	
	var item_to_drop = slot.item
	var quantity_to_drop : int = 1
	
	# Créer un objet CollectableItem
	var collectable_item := create_collectable_item(item_to_drop, joueur.global_position, quantity_to_drop)
	
	# Ajouter l'objet à la scène dans le node "Room"
	var rooms := get_tree().current_scene.get_node_or_null("Room")
	if rooms == null:
		push_warning("Inventaire: Impossible de trouver le node Room pour drop l'item")
		return
	
	rooms.add_child(collectable_item)
	
	# Retirer l'item du slot
	if slot.quantity > 1:
		slot.remove_item(1)
	else:
		slot.clear_slot()
	
	print("Item dropé sur la map: ", item_to_drop.item_name, " (x", quantity_to_drop, ")")

func create_collectable_item(item: Item, position: Vector2, quantity: int = 1) -> Node2D:
	"""Crée un objet CollectableItem avec les propriétés données"""
	var collectable := Node2D.new()
	collectable.name = item.item_name + "_dropped"
	collectable.position = position
	collectable.set_script(load("res://Scripts/Items/CollectableItem.gd"))
	
	# Assigner les propriétés
	collectable.item_resource = item
	collectable.quantity = quantity
	collectable.collectable = true
	
	# Créer un Sprite2D pour afficher l'item
	if item.item_texture != null:
		var sprite := Sprite2D.new()
		sprite.texture = item.item_texture
		sprite.name = "Sprite2D"
		collectable.add_child(sprite)
	
	# Ajouter une collision shape pour l'interaction
	var static_body := StaticBody2D.new()
	static_body.name = "StaticBody2D"
	var collision_shape := CollisionShape2D.new()
	var rectangle_shape := RectangleShape2D.new()
	rectangle_shape.size = Vector2(16, 16)
	collision_shape.shape = rectangle_shape
	static_body.add_child(collision_shape)
	collectable.add_child(static_body)
	
	return collectable
