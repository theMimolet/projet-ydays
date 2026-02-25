extends Panel
class_name WeaponSelectMenu

signal weapon_selected(arme: Resource)
signal menu_closed

const SLOT_SIZE: Vector2 = Vector2(64, 80)
const GRID_COLUMNS: int = 4
const SLOT_SPACING: int = 8

@onready var grid_container: GridContainer = $MarginContainer/VBoxContainer/GridContainer
@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var close_button: Button = $MarginContainer/VBoxContainer/CloseButton

var armes_disponibles: Array = []
var arme_selectionnee: Resource = null


func _ready() -> void:
	visible = false
	if close_button:
		close_button.pressed.connect(_on_close_pressed)


func afficher_menu(armes: Array, arme_actuelle: Resource = null) -> void:
	armes_disponibles = armes
	arme_selectionnee = arme_actuelle
	_creer_slots_armes()
	visible = true


func fermer_menu() -> void:
	visible = false
	menu_closed.emit()


func _creer_slots_armes() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	
	if armes_disponibles.is_empty():
		var label := Label.new()
		label.text = "Aucune arme disponible"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grid_container.add_child(label)
		return
	
	for arme in armes_disponibles:
		var slot := _creer_slot_arme(arme)
		grid_container.add_child(slot)


func _creer_slot_arme(arme: Resource) -> Control:
	var slot := Panel.new()
	slot.custom_minimum_size = SLOT_SIZE
	
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 2)
	slot.add_child(vbox)
	
	var texture_rect := TextureRect.new()
	texture_rect.custom_minimum_size = Vector2(48, 48)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if arme.item_texture:
		texture_rect.texture = arme.item_texture
	vbox.add_child(texture_rect)
	
	var nom_label := Label.new()
	nom_label.text = arme.get_nom_arme() if arme.has_method("get_nom_arme") else arme.item_name
	nom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nom_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(nom_label)
	
	var degats_label := Label.new()
	if arme.has_method("get_description_degats"):
		degats_label.text = arme.get_description_degats() + " dmg"
	elif arme.combat_data:
		degats_label.text = arme.combat_data.get_description_degats() + " dmg"
	else:
		degats_label.text = "? dmg"
	degats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	degats_label.add_theme_font_size_override("font_size", 9)
	degats_label.modulate = Color(0.8, 0.8, 0.8)
	vbox.add_child(degats_label)
	
	if arme == arme_selectionnee:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.3, 0.5, 0.3, 0.8)
		style.set_corner_radius_all(4)
		slot.add_theme_stylebox_override("panel", style)
	
	var button := Button.new()
	button.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.flat = true
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(_on_arme_selectionnee.bind(arme))
	slot.add_child(button)
	
	return slot


func _on_arme_selectionnee(arme: Resource) -> void:
	arme_selectionnee = arme
	weapon_selected.emit(arme)
	fermer_menu()


func _on_close_pressed() -> void:
	fermer_menu()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	if event.is_action_pressed("ui_cancel"):
		fermer_menu()
		get_viewport().set_input_as_handled()
