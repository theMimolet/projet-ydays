extends Panel

const Item = preload("res://Scripts/Items/Item.gd")

@onready var item_texture : TextureRect = $ItemTexture
@onready var quantity_label : Label = $QuantityLabel

var item = null  # Item
var quantity : int = 0
var slot_index : int = -1
var is_dragging : bool = false

signal slot_clicked(slot)
signal slot_drag_started(slot)
signal slot_dropped(slot, target_slot)
signal slot_right_clicked(slot)

func _ready() -> void:
	# Style du slot
	custom_minimum_size = Vector2(40, 40)
	
	# Initialiser l'affichage
	update_display()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Vérifier si Alt est pressé pour le split
				if Input.is_key_pressed(KEY_ALT) and quantity > 1:
					slot_clicked.emit(self)
				elif not Input.is_key_pressed(KEY_ALT):
					slot_clicked.emit(self)
			else:
				# Fin du drag
				if is_dragging:
					var target = _get_slot_under_mouse()
					if target != null and target != self:
						slot_dropped.emit(self, target)
					set_dragging(false)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if not is_empty():
				slot_right_clicked.emit(self)

func _get_slot_under_mouse():
	var mouse_pos : Vector2 = get_global_mouse_position()
	var slots = get_tree().get_nodes_in_group("InventorySlot")
	
	for slot in slots:
		if slot.has_method("is_empty"):
			var rect : Rect2 = Rect2(slot.global_position, slot.size)
			if rect.has_point(mouse_pos):
				return slot
	return null

func set_item(new_item, new_quantity: int = 1) -> void:
	item = new_item
	quantity = new_quantity
	update_display()

func add_item(new_item, amount: int = 1) -> bool:
	"""Ajoute un item au slot. Retourne true si réussi, false si le slot est plein"""
	if item == null:
		# Slot vide, on peut ajouter
		item = new_item
		quantity = min(amount, new_item.max_stack)
		update_display()
		return true
	elif item.item_name == new_item.item_name:
		# Même item, on peut empiler
		var new_quantity = quantity + amount
		if new_quantity <= item.max_stack:
			quantity = new_quantity
			update_display()
			return true
		else:
			# Trop d'items, on remplit au maximum
			quantity = item.max_stack
			update_display()
			return false
	else:
		# Item différent, slot occupé
		return false

func remove_item(amount: int = 1) -> void:
	"""Retire des items du slot"""
	if item == null:
		return
	
	quantity -= amount
	if quantity <= 0:
		item = null
		quantity = 0
	
	update_display()

func clear_slot() -> void:
	"""Vide complètement le slot"""
	item = null
	quantity = 0
	update_display()

func is_empty() -> bool:
	"""Retourne true si le slot est vide"""
	return item == null or quantity <= 0

func update_display() -> void:
	"""Met à jour l'affichage du slot"""
	if item != null and item.item_texture != null:
		item_texture.texture = item.item_texture
		item_texture.visible = true
	else:
		item_texture.texture = null
		item_texture.visible = false
	
	# Afficher la quantité si > 1
	if quantity > 1:
		quantity_label.text = "x" + str(quantity)
		quantity_label.visible = true
	else:
		quantity_label.text = ""
		quantity_label.visible = false

func set_dragging(dragging: bool) -> void:
	"""Active ou désactive l'état de drag pour le feedback visuel"""
	is_dragging = dragging
	if dragging:
		modulate = Color(1, 1, 1, 0.5)
	else:
		modulate = Color(1, 1, 1, 1)

func split_stack() -> bool:
	"""Divise une pile en retirant 1 item. Retourne true si réussi"""
	if quantity > 1:
		quantity -= 1
		update_display()
		return true
	return false
