extends Control
class_name CombatController

## Contrôleur principal du combat. Gère l'interface, le QTE et les attaques.

const WeaponInCombatRes = preload("res://Scripts/Items/WeaponInCombat.gd")

signal combat_started
signal combat_ended(victory: bool)
signal attack_performed(damage: int, critical: bool)
signal attack_missed
signal joueur_hp_changed(current_hp: int, max_hp: int)
signal ennemi_hp_changed(current_hp: int, max_hp: int)

@export var arme_equipee: Resource
@export var joueur_max_hp: int = 100
@export var ennemi_max_hp: int = 50

@onready var btn_attaque: Button = $UI/BtnAttaque
@onready var qte_system: Node = $QTESystem
@onready var label_resultat: Label = $UI/LabelResultat
@onready var hp_joueur_sprite: AnimatedSprite2D = $AreneContainer/ZoneJoueur/HPJoueurContainer/HPJoueur

var combat_actif: bool = false
var joueur_hp: int = 100
var ennemi_hp: int = 50


func _ready() -> void:
	if btn_attaque:
		btn_attaque.pressed.connect(_on_attaque_pressed)
	if qte_system:
		qte_system.qte_completed.connect(_on_qte_completed)
		qte_system.qte_failed.connect(_on_qte_failed)
	_cacher_resultat()
	
	# Initialiser les HP
	joueur_hp = joueur_max_hp
	ennemi_hp = ennemi_max_hp
	_update_hp_joueur_display()
	
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


## Met à jour l'affichage de la barre HP du joueur (sprite animé)
func _update_hp_joueur_display() -> void:
	if not hp_joueur_sprite:
		return
	
	var hp_percent := (float(joueur_hp) / float(joueur_max_hp)) * 100.0
	
	# Frame 8 = plein (100%), Frame 0 = vide (0%)
	if hp_percent >= 100:
		hp_joueur_sprite.frame = 8
	elif hp_percent >= 90:
		hp_joueur_sprite.frame = 7
	elif hp_percent >= 80:
		hp_joueur_sprite.frame = 6
	elif hp_percent >= 65:
		hp_joueur_sprite.frame = 5
	elif hp_percent >= 50:
		hp_joueur_sprite.frame = 4
	elif hp_percent >= 40:
		hp_joueur_sprite.frame = 3
	elif hp_percent >= 25:
		hp_joueur_sprite.frame = 2
	elif hp_percent >= 10:
		hp_joueur_sprite.frame = 1
	else:
		hp_joueur_sprite.frame = 0
	
	joueur_hp_changed.emit(joueur_hp, joueur_max_hp)


## Inflige des dégâts au joueur
func infliger_degats_joueur(degats: int) -> void:
	joueur_hp = max(0, joueur_hp - degats)
	_update_hp_joueur_display()
	
	if joueur_hp <= 0:
		terminer_combat(false)


## Soigne le joueur
func soigner_joueur(soin: int) -> void:
	joueur_hp = min(joueur_max_hp, joueur_hp + soin)
	_update_hp_joueur_display()


## Définit les HP du joueur directement
func set_joueur_hp(hp: int) -> void:
	joueur_hp = clamp(hp, 0, joueur_max_hp)
	_update_hp_joueur_display()
