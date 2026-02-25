extends Control
class_name CombatController

## Contrôleur principal du combat. Gère l'interface, le QTE et les attaques.

const WeaponInCombatRes = preload("res://Scripts/Items/WeaponInCombat.gd")

signal combat_started
signal combat_ended(victory: bool)
signal attack_performed(damage: int, critical: bool)
signal attack_missed

@export var arme_equipee: Resource

@onready var btn_attaque: Button = $UI/BtnAttaque
@onready var qte_system: Node = $QTESystem
@onready var label_resultat: Label = $UI/LabelResultat

var combat_actif: bool = false


func _ready() -> void:
	if btn_attaque:
		btn_attaque.pressed.connect(_on_attaque_pressed)
	if qte_system:
		qte_system.qte_completed.connect(_on_qte_completed)
		qte_system.qte_failed.connect(_on_qte_failed)
	_cacher_resultat()
	demarrer_combat(arme_equipee)


func demarrer_combat(arme: Resource = null) -> void:
	if arme:
		arme_equipee = arme
	combat_actif = true
	_cacher_resultat()
	combat_started.emit()


func terminer_combat(victoire: bool) -> void:
	combat_actif = false
	combat_ended.emit(victoire)


func _on_attaque_pressed() -> void:
	print("[Combat] Bouton Attaque pressé")
	print("[Combat] combat_actif = ", combat_actif)
	print("[Combat] arme_equipee = ", arme_equipee)
	if not combat_actif:
		print("[Combat] Combat non actif, abandon")
		return
	if not arme_equipee:
		push_warning("CombatController: Aucune arme équipée!")
		return
	print("[Combat] Lancement du QTE...")
	btn_attaque.disabled = true
	qte_system.lancer_qte()


func _on_qte_completed() -> void:
	btn_attaque.disabled = false
	_effectuer_attaque()


func _on_qte_failed() -> void:
	btn_attaque.disabled = false
	_afficher_resultat("Raté !", Color.RED)
	attack_missed.emit()


func _effectuer_attaque() -> void:
	if not arme_equipee:
		return
	var resultat: Dictionary = arme_equipee.get_degats_avec_critique()
	var degats: int = resultat["degats"]
	var critique: bool = resultat["critique"]
	
	var texte := "%d dégâts" % degats
	var couleur := Color.WHITE
	if critique:
		texte += " CRITIQUE!"
		couleur = Color.YELLOW
	
	_afficher_resultat(texte, couleur)
	attack_performed.emit(degats, critique)


func _afficher_resultat(texte: String, couleur: Color) -> void:
	if label_resultat:
		label_resultat.text = texte
		label_resultat.modulate = couleur
		label_resultat.visible = true
		# Masquer après 2 secondes
		await get_tree().create_timer(2.0).timeout
		_cacher_resultat()


func _cacher_resultat() -> void:
	if label_resultat:
		label_resultat.visible = false
