extends Node2D

const DOOR_CLOSED_VISUAL: Texture2D = preload("res://Sprites/Porte/sprite_0.png")

## Timelines Dialogic (configurables dans l'inspecteur)
@export_category("Dialogues")
@export var intro_timeline: String = ""
@export var post_combat_timeline: String = ""

## Stats de combat de Rabiacci
@export_category("Combat Rabiacci")
@export var rabiacci_combat_hp: int = 80
@export var rabiacci_damage_min: int = 8
@export var rabiacci_damage_max: int = 15
@export var rabiacci_monster_name: String = "Rabiacci"

## Positions de la cinématique (relatives à la porte)
@export_category("Positionnement")
@export var player_offset_from_door: Vector2 = Vector2(0, 20)
@export var rabiacci_offset_from_player: Vector2 = Vector2(0, 30)

var _torches_allumees: int = 0
var _cinematique_lancee: bool = false

var _joueur: Node = null
var _door: Node = null
var _garde_rouge: Node = null


func _ready() -> void:
	await get_tree().process_frame

	_joueur = get_tree().get_first_node_in_group("Joueur")
	_door = _find_door()
	_garde_rouge = _find_garde_rouge()

	for torche: Node in get_tree().get_nodes_in_group("Torches"):
		if torche.has_signal("torch_lit"):
			torche.torch_lit.connect(_on_torch_lit)
		if "is_lit" in torche and torche.is_lit:
			_torches_allumees += 1

	if Global.get_flag("rabiacci_vaincu"):
		_apply_post_victory_state(false)
		return

	_force_precombat_door_visual()

	if Global.pending_post_combat_event == "rabiacci_couloir":
		Global.pending_post_combat_event = ""
		_lock_player_for_couloir_cinematic(true)
		_apply_post_victory_state(true)
		call_deferred("_post_combat_sequence")


func _find_door() -> Node:
	var doors: Array[Node] = get_tree().get_nodes_in_group("Doors")
	for d: Node in doors:
		if d.name == "DoorCouloir":
			return d
	return get_parent().get_node_or_null("DoorCouloir")


func _find_garde_rouge() -> Node:
	for pnj: Node in get_tree().get_nodes_in_group("PNJ"):
		if pnj.name == "Garde Rouge":
			return pnj
	var env: Node = get_parent().get_node_or_null("Environnement1Ydays1")
	if env != null:
		return env.get_node_or_null("Garde Rouge")
	return null


func _on_torch_lit() -> void:
	_torches_allumees += 1
	if _torches_allumees >= 2 and not _cinematique_lancee:
		_cinematique_lancee = true
		_start_cinematique()


func _start_cinematique() -> void:
	_lock_player_for_couloir_cinematic(true)

	Global.set_flag("couloir_torches_allumees")

	# Fondu au noir
	var scene_transition: Node = get_node_or_null("/root/SceneTransition")
	if scene_transition != null and scene_transition.has_method("fade_out"):
		await scene_transition.fade_out(0.8)
	
	# Pendant l'écran noir : ouvrir la porte, repositionner joueur et Rabiacci
	if _door != null:
		_door.is_open = false
		if _door.has_method("update_visual_state"):
			_door.update_visual_state(false)
		var static_body: Node = _door.get_node_or_null("StaticBody2D_Door")
		if static_body is StaticBody2D:
			static_body.queue_free()
		if _door.has_method("set_visual_override"):
			_door.set_visual_override(DOOR_CLOSED_VISUAL)

	var door_pos: Vector2 = _door.global_position if _door != null else Vector2.ZERO
	if _joueur != null:
		_joueur.global_position = door_pos + player_offset_from_door
	if _garde_rouge != null and _joueur != null:
		_garde_rouge.global_position = _joueur.global_position + rabiacci_offset_from_player

	await get_tree().create_timer(2.0).timeout

	# Retour de l'image
	if scene_transition != null and scene_transition.has_method("fade_in"):
		await scene_transition.fade_in(0.8)

	# Dialogue de Rabiacci avant le combat
	if intro_timeline != "":
		Dialogic.start(intro_timeline)
		await Dialogic.timeline_ended

	await get_tree().create_timer(0.3).timeout

	Global.pending_post_combat_event = "rabiacci_couloir"
	_launch_rabiacci_combat()


func _launch_rabiacci_combat() -> void:
	var combat_data: Dictionary = {
		"monster_hp": rabiacci_combat_hp,
		"monster_max_hp": rabiacci_combat_hp,
		"monster_attack": rabiacci_damage_min,
		"monster_attack_min": rabiacci_damage_min,
		"monster_attack_max": rabiacci_damage_max,
		"monster_name": rabiacci_monster_name,
	}

	if _garde_rouge != null:
		_collect_visuals(_garde_rouge, combat_data)

	Global.start_combat(combat_data)


func _collect_visuals(node: Node, data: Dictionary) -> void:
	for child: Node in node.get_children():
		if child is AnimatedSprite2D:
			var anim_sprite := child as AnimatedSprite2D
			if anim_sprite.sprite_frames != null:
				data["monster_sprite_frames"] = anim_sprite.sprite_frames
				data["monster_animation"] = anim_sprite.animation
				var frames := anim_sprite.sprite_frames
				var anim_name := anim_sprite.animation
				if frames.get_frame_count(anim_name) > 0:
					data["monster_texture"] = frames.get_frame_texture(anim_name, 0)
				return
		if child is Sprite2D and (child as Sprite2D).texture != null:
			data["monster_texture"] = (child as Sprite2D).texture
			return


func _post_combat_sequence() -> void:
	await get_tree().process_frame
	await get_tree().process_frame

	_lock_player_for_couloir_cinematic(true)
	_move_player_to_named_point("Couloir_vers_jardin")

	if post_combat_timeline != "":
		Dialogic.start(post_combat_timeline)
		await Dialogic.timeline_ended

	Global.set_flag("rabiacci_vaincu")

	if _door != null:
		_door.is_open = true
		if _door.has_method("clear_visual_override"):
			_door.clear_visual_override()
		if _door.has_method("update_visual_state"):
			_door.update_visual_state(false)

	_lock_player_for_couloir_cinematic(false)
	if _joueur != null and "canMove" in _joueur:
		_joueur.canMove = true


func _apply_post_victory_state(hold_closed_door_visual: bool = false) -> void:
	for torche: Node in get_tree().get_nodes_in_group("Torches"):
		if "is_lit" in torche and not torche.is_lit and torche.has_method("_allumer"):
			torche._allumer(false)

	if Global.get_flag("couloir_torches_allumees"):
		for torche: Node in get_tree().get_nodes_in_group("Torches"):
			if torche.has_method("ensure_lit_visual"):
				torche.ensure_lit_visual()

	if _door != null:
		_door.is_open = not hold_closed_door_visual
		if not hold_closed_door_visual and _door.has_method("clear_visual_override"):
			_door.clear_visual_override()
		if _door.has_method("update_visual_state"):
			_door.update_visual_state(false)
		if hold_closed_door_visual and _door.has_method("set_visual_override"):
			_door.set_visual_override(DOOR_CLOSED_VISUAL)

		var static_body: Node = _door.get_node_or_null("StaticBody2D_Door")
		if static_body is StaticBody2D:
			static_body.queue_free()


func _force_precombat_door_visual() -> void:
	if _door == null:
		return
	_door.is_open = false
	if _door.has_method("set_visual_override"):
		_door.set_visual_override(DOOR_CLOSED_VISUAL)
	if _door.has_method("update_visual_state"):
		_door.update_visual_state(false)


func _move_player_to_named_point(point_name: String) -> void:
	if _joueur == null:
		return
	var spawn_point: Node2D = get_parent().get_node_or_null(point_name)
	if spawn_point != null:
		_joueur.global_position = spawn_point.global_position


func _lock_player_for_couloir_cinematic(locked: bool) -> void:
	if _joueur != null and _joueur.has_method("set_cutscene_movement_lock"):
		_joueur.set_cutscene_movement_lock(locked)
	elif _joueur != null and "canMove" in _joueur:
		_joueur.canMove = not locked
