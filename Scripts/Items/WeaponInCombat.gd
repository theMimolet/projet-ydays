extends Node
class_name Weapon

## ====== STATS MODIFIABLES DANS L'INSPECTEUR ======

@export_category("Dégâts")
@export var damage: float = 10.0
@export var damage_variation: float = 0.0 # Exemple: 2 = +/-2 dégâts

@export_category("Critiques")
@export var crit_chance: float = 0.1 # 0.1 = 10%
@export var crit_multiplier: float = 1.5

## ====== VARIABLES INTERNES ======

var _can_attack: bool = true

## ====== FONCTION PRINCIPALE ======

func attack(target):
	if not _can_attack:
		return
	
	if target == null:
		return
	
	var final_damage = calculate_damage()
	
	if target.has_method("take_damage"):
		target.take_damage(final_damage)
	
## ====== CALCUL DES DEGATS ======

func calculate_damage() -> float:
	var final_damage = damage
	
	# Variation aléatoire
	if damage_variation > 0:
		final_damage += randf_range(-damage_variation, damage_variation)
	
	# Critique
	if randf() <= crit_chance:
		final_damage *= crit_multiplier
		print("COUP CRITIQUE !")
	
	return max(final_damage, 0)


# L'ennemi doit avoir 
# extends CharacterBody2D

# @export var health: float = 100

# func take_damage(amount: float):
# 	health -= amount
# 	print("Dégâts reçus :", amount)
	
# 	if health <= 0:
# 		die()

# func die():
# 	print("Ennemi mort")
# 	queue_free()
