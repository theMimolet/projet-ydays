extends Resource
class_name WeaponInCombat

## Données de combat pour une arme.
## Crée une nouvelle Resource dans Godot, assigne ce script, et modifie les valeurs.

@export_category("Dégâts")
@export var damage_min: int = 5
@export var damage_max: int = 10
@export var degats_fixes: bool = false

@export_category("Options")
@export var multiplicateur_critique: float = 1.5
@export_range(0.0, 1.0, 0.01) var chance_critique: float = 0.1
@export var nom_arme: String = "Arme"


func get_degats() -> int:
	if degats_fixes:
		return damage_min
	return randi_range(damage_min, damage_max)


func get_degats_avec_critique() -> Dictionary:
	var est_critique := randf() < chance_critique
	var base := get_degats()
	var degats_finaux := base
	if est_critique:
		degats_finaux = int(base * multiplicateur_critique)
	return { "degats": degats_finaux, "critique": est_critique }


func get_description_degats() -> String:
	if degats_fixes:
		return str(damage_min)
	return "%d-%d" % [damage_min, damage_max]


func get_degats_moyens() -> float:
	if degats_fixes:
		return float(damage_min)
	return (damage_min + damage_max) / 2.0
