extends Sprite2D

const COFFRE_FERME_TEXTURE = preload("res://Spritesheet/Coffre/sprite_coffre0.png")
const COFFRE_OUVERT_TEXTURE = preload("res://Spritesheet/Coffre/sprite_coffre2.png")

var is_opened : bool = false

func _ready() -> void:
	# Ajouter au groupe pour la détection
	add_to_group("Coffres")
	
	# Initialiser avec le sprite fermé seulement si pas déjà défini
	if texture == null:
		texture = COFFRE_FERME_TEXTURE

func interact() -> void:
	if is_opened:
		return
	
	# Changer le sprite pour le coffre ouvert
	texture = COFFRE_OUVERT_TEXTURE
	is_opened = true

func enable_player_movement() -> void:
	# Utiliser call_deferred pour s'assurer que ça s'exécute au bon moment
	call_deferred("_enable_player_movement_deferred")

func _enable_player_movement_deferred() -> void:
	# Chercher le joueur et remettre canMove à true
	var joueur = get_tree().get_first_node_in_group("Joueur")
	if joueur == null:
		# Essayer de trouver le joueur par son nom dans la scène racine
		var root = get_tree().root
		joueur = root.find_child("Joueur", true, false)
	
	if joueur != null:
		if "canMove" in joueur:
			joueur.canMove = true
		else:
			print("Erreur : le joueur n'a pas la propriété canMove")
	else:
		print("Erreur : joueur introuvable pour remettre canMove à true")
