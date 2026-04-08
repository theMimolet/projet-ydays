extends Node2D

@export var required_item_name : String = "key_zone1"
@export_file("*.tscn") var room_to_load : String
@export var spawn_point_name : String = "InitialSpawn"
@export var is_open : bool = false

@export_category("Visuel")
@export var closed_texture: Texture2D = null
@export var open_texture: Texture2D = null

@export var dialog_no_key_timeline : String = "porte_sans_clef"
@export var dialog_with_key_timeline : String = "porte_avec_clef"

func _ready() -> void:
	add_to_group("Doors")
	update_visual_state()

func update_visual_state() -> void:
	var sprite := get_node_or_null("DoorSprite")
	if sprite is Sprite2D:
		if is_open:
			if open_texture != null:
				sprite.texture = open_texture
		else:
			# Si aucune texture "fermée" n'est fournie, on garde la texture existante
			if closed_texture != null:
				sprite.texture = closed_texture
	
	_update_room_switcher_state()

func _update_room_switcher_state() -> void:
	# Optionnel : si la porte a un enfant RoomSwitcher (Area2D), on l'active uniquement quand la porte est ouverte.
	var rs := get_node_or_null("RoomSwitcher")
	if rs is Area2D:
		(rs as Area2D).monitoring = is_open
		(rs as Area2D).monitorable = is_open
		for c in (rs as Area2D).get_children():
			if c is CollisionShape2D:
				(c as CollisionShape2D).disabled = not is_open

func interact() -> void:
	if is_open:
		_perform_room_change()
		return
	
	var inventaire: Node = get_tree().get_first_node_in_group("Inventaire")
	if inventaire == null:
		return
	
	var joueur: Node = get_tree().get_first_node_in_group("Joueur")
	
	# Cas 1 : le joueur n'a pas la clé -> simple description de la porte
	if not inventaire.has_item(required_item_name, 1):
		if dialog_no_key_timeline != "":
			Dialogic.start(dialog_no_key_timeline)
			if joueur != null and "canMove" in joueur:
				joueur.canMove = false
		return
	
	# Cas 2 : le joueur a la clé -> dialogue \"voulez-vous utiliser la clef ?\"
	# La logique réelle d'utilisation de la clé se fait dans use_key_and_open(),
	# appelée depuis le timeline via Global.use_key_on_pending_door().
	Global.set_pending_door(self)
	if dialog_with_key_timeline != "":
		Dialogic.start(dialog_with_key_timeline)
		if joueur != null and "canMove" in joueur:
			joueur.canMove = false

func use_key_and_open() -> void:
	if is_open:
		return
	
	var inventaire: Node = get_tree().get_first_node_in_group("Inventaire")
	if inventaire == null:
		return
	
	if not inventaire.has_item(required_item_name, 1):
		return
	
	inventaire.remove_item(required_item_name, 1)
	is_open = true
	update_visual_state()
	
	var static_body := get_node_or_null("StaticBody2D_Door")
	if static_body is StaticBody2D:
		static_body.queue_free()
	
	_perform_room_change()

func _perform_room_change() -> void:
	if room_to_load == "":
		return
	
	# Tenter de récupérer le gestionnaire de rooms
	var room_manager := get_tree().current_scene.get_node_or_null("ChangeRoom")
	if room_manager == null:
		room_manager = get_tree().get_first_node_in_group("ChangeRoom")
	
	if room_manager != null and room_manager.has_method("roomChange"):
		room_manager.roomChange(room_to_load, spawn_point_name)
