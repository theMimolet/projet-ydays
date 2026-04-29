extends CanvasLayer

@onready var hp_sprite: TextureRect = $HPContainer/HPSprite
@onready var hp_container: Control = $HPContainer

const HP_TEXTURES := [
	"res://Sprites/HP/sprite_noirceur0.png", # 100 HP
	"res://Sprites/HP/sprite_noirceur1.png", # 90 HP
	"res://Sprites/HP/sprite_noirceur2.png", # 80 HP
	"res://Sprites/HP/sprite_noirceur3.png", # 65 HP
	"res://Sprites/HP/sprite_noirceur4.png", # 50 HP
	"res://Sprites/HP/sprite_noirceur5.png", # 40 HP
	"res://Sprites/HP/sprite_noirceur6.png", # 25 HP
	"res://Sprites/HP/sprite_noirceur7.png", # 10 HP
	"res://Sprites/HP/sprite_noirceur8.png" # 0 HP
]

var joueur: Node = null

func _ready() -> void:
	if hp_container != null:
		hp_container.visible = true
		hp_container.modulate = Color(1, 1, 1, 1)
	
	# Chercher le joueur
	joueur = get_tree().get_first_node_in_group("Joueur")
	
	if joueur == null:
		# Attendre un frame si le joueur n'est pas encore prêt
		await get_tree().process_frame
		joueur = get_tree().get_first_node_in_group("Joueur")
	
	if joueur != null and joueur.has_signal("hp_changed"):
		joueur.hp_changed.connect(_on_hp_changed)
		# Mettre à jour l'affichage initial
		if "current_hp" in joueur and "MAX_HP" in joueur:
			_on_hp_changed(joueur.current_hp, joueur.MAX_HP)
	else:
		print("Erreur HUD : joueur introuvable ou signal hp_changed manquant")

func _on_hp_changed(new_hp: int, max_hp: int) -> void:
	if hp_sprite == null or max_hp <= 0:
		return
	
	# Déterminer l'index du sprite selon les paliers (comme dans Joueur.gd)
	var sprite_index: int = 0
	
	if new_hp >= 100:
		sprite_index = 0 # sprite0
	elif new_hp >= 90:
		sprite_index = 1 # sprite1
	elif new_hp >= 80:
		sprite_index = 2 # sprite2
	elif new_hp >= 65:
		sprite_index = 3 # sprite3
	elif new_hp >= 50:
		sprite_index = 4 # sprite4
	elif new_hp >= 40:
		sprite_index = 5 # sprite5
	elif new_hp >= 25:
		sprite_index = 6 # sprite6
	elif new_hp >= 10:
		sprite_index = 7 # sprite7
	else:
		sprite_index = 8 # sprite8 (0 HP)
	
	# Charger et appliquer le sprite
	if sprite_index >= 0 and sprite_index < HP_TEXTURES.size():
		var texture_path: String = HP_TEXTURES[sprite_index]
		var texture := load(texture_path) as Texture2D
		if texture != null:
			hp_sprite.texture = texture
			var texture_size := texture.get_size()
			if texture_size.x > 0 and texture_size.y > 0:
				hp_sprite.texture = texture
				hp_sprite.visible = true
				hp_sprite.modulate = Color(1, 1, 1, 1)
				if hp_container != null:
					hp_container.visible = true
					hp_container.modulate = Color(1, 1, 1, 1)
			else:
				push_warning("HUD: Texture size is invalid for " + texture_path)
		else:
			push_warning("HUD: Failed to load texture: " + texture_path)
	else:
		push_warning("HUD: Invalid sprite_index: " + str(sprite_index))
