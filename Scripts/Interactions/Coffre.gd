extends Sprite2D

const COFFRE_FERME_TEXTURE = preload("res://Spritesheet/Coffre/sprite_coffre0.png")
const COFFRE_OUVERT_TEXTURE = preload("res://Spritesheet/Coffre/sprite_coffre2.png")

var is_opened : bool = false

func _ready() -> void:
	# Ajouter au groupe pour la détection
	add_to_group("Coffres")
	
	# Initialiser avec le sprite fermé
	texture = COFFRE_FERME_TEXTURE

func interact() -> void:
	if is_opened:
		return
	
	# Changer le sprite pour le coffre ouvert
	texture = COFFRE_OUVERT_TEXTURE
	is_opened = true
