extends CanvasLayer

const SLOT_SCENE = preload("res://Scenes/UI/InventorySlot.tscn")
const Item = preload("res://Scripts/Items/Item.gd")
const INVENTORY_SIZE: int = 16 # Nombre de slots d'inventaire

@onready var inventaire_panel: Panel = $InventairePanel
@onready var inventaire_container: GridContainer = $InventairePanel/InventaireContainer

var controles_hint: Control = null
var drag_preview: TextureRect = null
const DRAG_PREVIEW_SIZE: Vector2 = Vector2(36, 36)

var is_open: bool = false
var joueur: Node = null
var slots: Array = []
var dragged_slot = null

signal inventaire_opened
signal inventaire_closed

func _ready() -> void:
	# S'assurer que l'inventaire est au-dessus des autres UI (layer 0)
	layer = 10
	
	# Ajouter au groupe pour faciliter la recherche
	add_to_group("Inventaire")
	
	# Chercher le joueur
	joueur = get_tree().get_first_node_in_group("Joueur")
	
	# Créer les slots d'inventaire
	create_inventory_slots()
	
	# Panneau d'aide des contrôles (bas droite)
	_setup_controles_hint()
	# Preview de l'item pendant le drag
	_setup_drag_preview()
	
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

func _setup_controles_hint() -> void:
	controles_hint = MarginContainer.new()
	controles_hint.name = "ControlesHint"
	controles_hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	controles_hint.offset_left = -220
	controles_hint.offset_top = -90
	controles_hint.offset_right = -10
	controles_hint.offset_bottom = -10
	controles_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	controles_hint.add_theme_constant_override("margin_left", 8)
	controles_hint.add_theme_constant_override("margin_top", 8)
	controles_hint.add_theme_constant_override("margin_right", 8)
	controles_hint.add_theme_constant_override("margin_bottom", 8)
	var label: Label = Label.new()
	label.text = "TAB / ESC : Fermer\nClic gauche : Déplacer\nShift + Clic : Diviser\nClic droit : Utiliser"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	controles_hint.add_child(label)
	add_child(controles_hint)
	controles_hint.visible = false

func _setup_drag_preview() -> void:
	drag_preview = TextureRect.new()
	drag_preview.name = "DragPreview"
	drag_preview.set_anchors_preset(Control.PRESET_TOP_LEFT)
	drag_preview.offset_left = 0
	drag_preview.offset_top = 0
	drag_preview.offset_right = DRAG_PREVIEW_SIZE.x
	drag_preview.offset_bottom = DRAG_PREVIEW_SIZE.y
	drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_preview.visible = false
	drag_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	drag_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(drag_preview)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventaire"):
		toggle_inventaire()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and is_open:
		toggle_inventaire()
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if dragged_slot != null and drag_preview != null and drag_preview.visible:
		var mouse: Vector2 = get_viewport().get_mouse_position()
		var half: Vector2 = DRAG_PREVIEW_SIZE / 2
		drag_preview.offset_left = int(mouse.x - half.x)
		drag_preview.offset_top = int(mouse.y - half.y)
		drag_preview.offset_right = int(mouse.x + half.x)
		drag_preview.offset_bottom = int(mouse.y + half.y)

func toggle_inventaire() -> void:
	is_open = !is_open
	inventaire_panel.visible = is_open
	if controles_hint != null:
		controles_hint.visible = is_open
	
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
			var remaining: int = slot.item.max_stack - slot.quantity
			if remaining > 0:
				var to_add: int = min(quantity, remaining)
				slot.quantity += to_add
				slot.update_display()
				quantity -= to_add
				if quantity <= 0:
					return true
	
	# Chercher un slot vide
	for slot in slots:
		if slot.is_empty():
			var to_add: int = min(quantity, item.max_stack)
			slot.set_item(item, to_add)
			quantity -= to_add
			if quantity <= 0:
				return true
	
	# Si on arrive ici, l'inventaire est plein
	print("Inventaire plein !")
	return false

func remove_item(item_name: String, quantity: int = 1) -> bool:
	"""Retire un item de l'inventaire. Retourne true si réussi"""
	var remaining: int = quantity
	
	for slot in slots:
		if not slot.is_empty() and slot.item.item_name == item_name:
			var to_remove: int = min(remaining, slot.quantity)
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
	var total: int = 0
	for slot in slots:
		if not slot.is_empty() and slot.item.item_name == item_name:
			total += slot.quantity
	return total

# ============== DRAG & DROP ==============

func _on_slot_clicked(slot) -> void:
	"""Gère le clic sur un slot"""
	if dragged_slot == null and not slot.is_empty():
		# Vérifier si Shift est pressé pour le split
		if Input.is_key_pressed(KEY_SHIFT) and slot.quantity > 1:
			# Mode split : déplacer 1 item vers le slot libre le plus proche
			var nearest_empty_slot = _find_nearest_empty_slot(slot)
			if nearest_empty_slot != null:
				# Déplacer 1 item vers le slot libre
				nearest_empty_slot.set_item(slot.item, 1)
				slot.split_stack()
				print("Split: 1 item de ", slot.item.item_name, " déplacé vers slot ", nearest_empty_slot.slot_index)
			else:
				print("Split: Aucun slot libre disponible")
		else:
			# Mode drag normal
			dragged_slot = slot
			slot.set_dragging(true)
			if drag_preview != null and slot.item != null and slot.item.item_texture != null:
				drag_preview.texture = slot.item.item_texture
				drag_preview.visible = true
			print("Début du drag: ", slot.item.item_name)

func _on_slot_dropped(source_slot, target_slot) -> void:
	"""Gère le drop d'un slot vers un autre"""
	if source_slot == null or target_slot == null:
		_cleanup_drag(source_slot)
		return
	
	# Si le slot cible est vide, on déplace l'item
	if target_slot.is_empty():
		target_slot.set_item(source_slot.item, source_slot.quantity)
		source_slot.clear_slot()
	# Si c'est le même item, on empile
	elif target_slot.item.item_name == source_slot.item.item_name:
		var total: int = target_slot.quantity + source_slot.quantity
		if total <= target_slot.item.max_stack:
			target_slot.quantity = total
			target_slot.update_display()
			source_slot.clear_slot()
		else:
			# Échanger les quantités
			var max_stack: int = target_slot.item.max_stack
			var excess: int = total - max_stack
			target_slot.quantity = max_stack
			source_slot.quantity = excess
			source_slot.update_display()
			target_slot.update_display()
	# Sinon, on échange les items
	else:
		var temp_item = target_slot.item
		var temp_quantity: int = target_slot.quantity
		target_slot.set_item(source_slot.item, source_slot.quantity)
		source_slot.set_item(temp_item, temp_quantity)
	
	_cleanup_drag(source_slot)
	print("Drop effectué")

func _cleanup_drag(slot) -> void:
	"""Nettoie l'état de drag"""
	if slot != null and slot.has_method("set_dragging"):
		slot.set_dragging(false)
	if drag_preview != null:
		drag_preview.visible = false
		drag_preview.texture = null
	dragged_slot = null

func _find_nearest_empty_slot(reference_slot) -> Node:
	"""Trouve le slot vide le plus proche du slot de référence"""
	var nearest_slot = null
	var nearest_distance: float = INF
	
	# Obtenir la position du slot de référence dans le container
	var ref_index: int = reference_slot.slot_index
	var ref_pos: Vector2 = _get_slot_position_in_container(ref_index)
	
	for slot in slots:
		if slot.is_empty():
			var slot_pos: Vector2 = _get_slot_position_in_container(slot.slot_index)
			var distance: float = ref_pos.distance_to(slot_pos)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_slot = slot
	
	return nearest_slot

func _get_slot_position_in_container(slot_index: int) -> Vector2:
	"""Calcule la position d'un slot dans le container basé sur son index"""
	# Le GridContainer organise les slots en grille
	# On peut calculer la position en fonction de l'index
	var columns: int = inventaire_container.columns if inventaire_container.columns > 0 else 4
	var row: int = slot_index / columns
	var col: int = slot_index % columns
	# Estimation de la taille d'un slot (40x40 + espacement)
	var slot_size: float = 40.0
	var h_spacing: float = inventaire_container.get_theme_constant(&"h_separation")
	var v_spacing: float = inventaire_container.get_theme_constant(&"v_separation")
	if h_spacing == 0.0:
		h_spacing = 4.0 # Valeur par défaut
	if v_spacing == 0.0:
		v_spacing = 4.0 # Valeur par défaut
	return Vector2(col * (slot_size + h_spacing), row * (slot_size + v_spacing))
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
	var quantity_to_drop: int = 1
	
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
	
	# Créer un AnimatedSprite2D si sprite_frames est défini, sinon un Sprite2D simple
	if item.sprite_frames != null:
		var animated_sprite := AnimatedSprite2D.new()
		animated_sprite.name = "AnimatedSprite2D"
		animated_sprite.sprite_frames = item.sprite_frames
		if item.animation_name != "" and item.sprite_frames.has_animation(item.animation_name):
			animated_sprite.animation = item.animation_name
		else:
			# Utiliser la première animation disponible
			var animations = item.sprite_frames.get_animation_names()
			if animations.size() > 0:
				animated_sprite.animation = animations[0]
		collectable.add_child(animated_sprite)
		# Lancer l'animation après avoir ajouté au parent
		if animated_sprite.animation != "":
			animated_sprite.play()
	elif item.item_texture != null:
		var sprite := Sprite2D.new()
		sprite.name = "Sprite2D"
		collectable.add_child(sprite)
		# Assigner la texture après avoir ajouté au parent pour éviter les erreurs
		sprite.texture = item.item_texture
	
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
