extends Item
class_name Weapon

@export var combat_data: WeaponInCombat
@export var sprite_overworld: Texture2D

func _init(
	name: String = "",
	description: String = "",
	texture: Texture2D = null,
	stack: int = 1,
	p_combat_data: WeaponInCombat = null,
	p_sprite_overworld: Texture2D = null
) -> void:
	super._init(name, description, texture, stack, "weapon")
	combat_data = p_combat_data
	sprite_overworld = p_sprite_overworld


func get_degats() -> int:
	if combat_data:
		return combat_data.get_degats()
	return 0


func get_degats_avec_critique() -> Dictionary:
	if combat_data:
		return combat_data.get_degats_avec_critique()
	return { "degats": 0, "critique": false }


func get_description_degats() -> String:
	if combat_data:
		return combat_data.get_description_degats()
	return "0"


func get_nom_arme() -> String:
	if combat_data and combat_data.nom_arme != "":
		return combat_data.nom_arme
	return item_name
