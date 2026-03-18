extends Control
class_name CombatController

## Contrôleur principal du combat. Gère l'interface, le QTE et les attaques.

signal combat_started
signal combat_ended(victory: bool)
signal attack_performed(damage: int, critical: bool)
signal attack_missed
signal joueur_hp_changed(current_hp: int, max_hp: int)
signal ennemi_hp_changed(current_hp: int, max_hp: int)

@export var arme_equipee: Resource
@export var joueur_max_hp: int = 100
@export var ennemi_max_hp: int = 50
@export var ennemi_attack: int = 10

@onready var btn_attaque: Button = $UI/BtnAttaque
@onready var btn_armes: Button = $UI/BtnArmes
@onready var qte_system: Node = $QTESystem
@onready var label_resultat: Label = $UI/LabelResultat
@onready var label_arme_actuelle: Label = $UI/LabelArmeActuelle
@onready var hp_joueur_sprite: AnimatedSprite2D = $AreneContainer/ZoneJoueur/HPJoueurContainer/HPJoueur
@onready var hp_ennemi_sprite: AnimatedSprite2D = $AreneContainer/ZoneEnnemi/HPEnnemiContainer/HPEnnemi
@onready var ennemi_sprite: TextureRect = $AreneContainer/ZoneEnnemi/EnnemiSprite
@onready var label_ennemi: Label = $AreneContainer/ZoneEnnemi/LabelEnnemi
@onready var modal_victoire: Panel = $ModalVictoire
@onready var btn_suivre: Button = $ModalVictoire/Center/Card/Margin/VBox/Actions/BtnSuivre
@onready var weapon_select_menu: Panel = $WeaponSelectMenu
@onready var arme_sprite_combat: TextureRect = $AreneContainer/ZoneJoueur/JoueurSprite/ArmeSpriteCombat

var combat_actif: bool = false
var joueur_hp: int = 100
var ennemi_hp: int = 50
var monster_id: String = ""
var armes_inventaire: Array = []
## Liste complète des armes disponibles pour tout le combat (inventaire + arme équipée au départ)
var armes_disponibles_combat: Array = []


func _ready() -> void:
	if btn_attaque:
		btn_attaque.pressed.connect(_on_attaque_pressed)
	if btn_armes:
		btn_armes.pressed.connect(_on_armes_pressed)
	if qte_system:
		qte_system.qte_completed.connect(_on_qte_completed)
		qte_system.qte_failed.connect(_on_qte_failed)
	if btn_suivre:
		btn_suivre.pressed.connect(_on_suivre_pressed)
	if weapon_select_menu:
		weapon_select_menu.weapon_selected.connect(_on_weapon_selected)
		weapon_select_menu.menu_closed.connect(_on_weapon_menu_closed)
	
	_cacher_resultat()
	_cacher_modal_victoire()
	
	# Charger les données de combat depuis Global
	_charger_donnees_combat()
	
	# Initialiser l'affichage
	_update_hp_joueur_display()
	_update_hp_ennemi_display()
	_update_arme_actuelle_display()
	_update_arme_sprite_combat()
	
	demarrer_combat(arme_equipee)


func _charger_donnees_combat() -> void:
	var data: Dictionary = Global.combat_data
	
	if data.is_empty():
		return
	
	# HP du joueur (récupérés de la vraie valeur du joueur)
	if data.has("joueur_hp"):
		joueur_hp = data["joueur_hp"]
	if data.has("joueur_max_hp"):
		joueur_max_hp = data["joueur_max_hp"]
	
	# Arme équipée du joueur (null = à mains nues)
	if data.has("arme_equipee"):
		arme_equipee = data["arme_equipee"]
	
	# Armes disponibles dans l'inventaire
	if data.has("armes_inventaire"):
		armes_inventaire = data["armes_inventaire"]
	
	# Liste complète pour tout le combat : inventaire + arme équipée (pour pouvoir resélectionner après un switch)
	armes_disponibles_combat = armes_inventaire.duplicate()
	if arme_equipee != null and arme_equipee not in armes_disponibles_combat:
		armes_disponibles_combat.append(arme_equipee)
	
	# Données de l'ennemi
	if data.has("monster_id"):
		monster_id = data["monster_id"]
	if data.has("monster_hp"):
		ennemi_hp = data["monster_hp"]
		ennemi_max_hp = data["monster_max_hp"] if data.has("monster_max_hp") else data["monster_hp"]
	if data.has("monster_attack"):
		ennemi_attack = data["monster_attack"]
	if data.has("monster_name") and label_ennemi:
		label_ennemi.text = data["monster_name"]
	if data.has("monster_texture") and ennemi_sprite:
		ennemi_sprite.texture = data["monster_texture"]


func demarrer_combat(arme: Resource = null) -> void:
	if arme:
		arme_equipee = arme
	combat_actif = true
	_cacher_resultat()
	combat_started.emit()


func terminer_combat(victoire: bool) -> void:
	combat_actif = false
	btn_attaque.disabled = true
	combat_ended.emit(victoire)
	
	if victoire:
		_afficher_modal_victoire()
	else:
		# Game over - délai pour voir le résultat
		await get_tree().create_timer(1.5).timeout
		Global.end_combat(false)


func _on_attaque_pressed() -> void:
	if not combat_actif:
		return
	btn_attaque.disabled = true
	qte_system.lancer_qte()


func _on_qte_completed() -> void:
	_effectuer_attaque_joueur()


func _on_qte_failed() -> void:
	_afficher_resultat("Raté !", Color.RED)
	attack_missed.emit()
	# L'ennemi attaque quand même
	await get_tree().create_timer(1.0).timeout
	_effectuer_attaque_ennemi()


func _effectuer_attaque_joueur() -> void:
	var degats: int
	var critique: bool = false
	if arme_equipee != null and arme_equipee.has_method("get_degats_avec_critique"):
		var resultat: Dictionary = arme_equipee.get_degats_avec_critique()
		degats = resultat["degats"]
		critique = resultat["critique"]
	else:
		# À mains nues : 2 à 3 dégâts
		degats = randi_range(2, 3)
	
	# Infliger les dégâts à l'ennemi
	ennemi_hp = max(0, ennemi_hp - degats)
	_update_hp_ennemi_display()
	
	var texte := "%d dégâts" % degats
	var couleur := Color.WHITE
	if critique:
		texte += " CRITIQUE!"
		couleur = Color.YELLOW
	
	_afficher_resultat(texte, couleur)
	attack_performed.emit(degats, critique)
	
	# Vérifier si l'ennemi est mort
	if ennemi_hp <= 0:
		await get_tree().create_timer(1.0).timeout
		terminer_combat(true)
		return
	
	# Tour de l'ennemi
	await get_tree().create_timer(1.5).timeout
	_effectuer_attaque_ennemi()


func _effectuer_attaque_ennemi() -> void:
	if not combat_actif:
		return
	
	var degats := ennemi_attack
	infliger_degats_joueur(degats)
	
	_afficher_resultat("L'ennemi inflige %d dégâts !" % degats, Color.ORANGE_RED)
	
	# Vérifier si le joueur est mort
	if joueur_hp <= 0:
		return
	
	# Réactiver le bouton attaque
	await get_tree().create_timer(1.5).timeout
	if combat_actif:
		btn_attaque.disabled = false


func _afficher_resultat(texte: String, couleur: Color) -> void:
	if label_resultat:
		label_resultat.text = texte
		label_resultat.modulate = couleur
		label_resultat.visible = true


func _cacher_resultat() -> void:
	if label_resultat:
		label_resultat.visible = false


func _afficher_modal_victoire() -> void:
	if modal_victoire:
		modal_victoire.visible = true


func _cacher_modal_victoire() -> void:
	if modal_victoire:
		modal_victoire.visible = false


func _on_suivre_pressed() -> void:
	Global.end_combat(true)


func _on_armes_pressed() -> void:
	if not combat_actif:
		return
	if weapon_select_menu:
		btn_attaque.disabled = true
		btn_armes.disabled = true
		# Utiliser la liste complète du combat pour que l'arme qu'on vient de déséquiper reste sélectionnable
		weapon_select_menu.afficher_menu(armes_disponibles_combat, arme_equipee)


func _on_weapon_selected(arme: Resource) -> void:
	arme_equipee = arme
	_update_arme_actuelle_display()
	_update_arme_sprite_combat()
	btn_attaque.disabled = false
	btn_armes.disabled = false


func _on_weapon_menu_closed() -> void:
	btn_attaque.disabled = false
	btn_armes.disabled = false


func _update_arme_actuelle_display() -> void:
	if not label_arme_actuelle:
		return
	
	if arme_equipee == null:
		label_arme_actuelle.text = "À mains nues (2-3 dmg)"
		return
	
	var nom_arme: String = ""
	if arme_equipee.has_method("get_nom_arme"):
		nom_arme = arme_equipee.get_nom_arme()
	elif "item_name" in arme_equipee:
		nom_arme = arme_equipee.item_name
	else:
		nom_arme = "Arme"
	
	var degats: String = ""
	if arme_equipee.has_method("get_description_degats"):
		degats = arme_equipee.get_description_degats()
	elif "combat_data" in arme_equipee and arme_equipee.combat_data:
		degats = arme_equipee.combat_data.get_description_degats()
	
	label_arme_actuelle.text = "%s (%s dmg)" % [nom_arme, degats]


func _update_arme_sprite_combat() -> void:
	if not arme_sprite_combat:
		return
	
	if arme_equipee == null:
		arme_sprite_combat.visible = false
		return
	
	var texture: Texture2D = null
	if "sprite_overworld" in arme_equipee and arme_equipee.sprite_overworld != null:
		texture = arme_equipee.sprite_overworld
	elif "item_texture" in arme_equipee and arme_equipee.item_texture != null:
		texture = arme_equipee.item_texture
	
	if texture != null:
		arme_sprite_combat.texture = texture
		arme_sprite_combat.visible = true
	else:
		arme_sprite_combat.visible = false


## Met à jour l'affichage de la barre HP du joueur (sprite animé)
func _update_hp_joueur_display() -> void:
	if not hp_joueur_sprite:
		return
	
	var hp_percent := (float(joueur_hp) / float(joueur_max_hp)) * 100.0
	hp_joueur_sprite.frame = _get_hp_frame(hp_percent)
	joueur_hp_changed.emit(joueur_hp, joueur_max_hp)


## Met à jour l'affichage de la barre HP de l'ennemi
func _update_hp_ennemi_display() -> void:
	if not hp_ennemi_sprite:
		return
	
	var hp_percent := (float(ennemi_hp) / float(ennemi_max_hp)) * 100.0
	hp_ennemi_sprite.frame = _get_hp_frame(hp_percent)
	ennemi_hp_changed.emit(ennemi_hp, ennemi_max_hp)


## Retourne la frame correspondant au pourcentage de HP
## Frame 0 = plein (100%), Frame 8 = vide (0%)
func _get_hp_frame(hp_percent: float) -> int:
	if hp_percent >= 100:
		return 0
	elif hp_percent >= 90:
		return 1
	elif hp_percent >= 80:
		return 2
	elif hp_percent >= 65:
		return 3
	elif hp_percent >= 50:
		return 4
	elif hp_percent >= 40:
		return 5
	elif hp_percent >= 25:
		return 6
	elif hp_percent >= 10:
		return 7
	else:
		return 8


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
