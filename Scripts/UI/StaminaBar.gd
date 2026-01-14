extends Control

@onready var stamina_sprite: TextureRect = $StaminaSprite

const STAMINA_TEXTURES := [
	"res://Spritesheet/stamina/1.png",
	"res://Spritesheet/stamina/2.png",
	"res://Spritesheet/stamina/3.png",
	"res://Spritesheet/stamina/4.png"
]

const DISPLAY_SCALE := 0.08

func _ready() -> void:
	visible = true
	modulate = Color(1, 1, 1, 1)
	_on_stamina_changed(3)
	
	await get_tree().process_frame
	
	var player := get_tree().get_first_node_in_group("Joueur")
	if player == null:
		player = get_tree().current_scene.get_node_or_null("Joueur")
	
	if player != null and player.has_signal("stamina_changed"):
		player.stamina_changed.connect(_on_stamina_changed)
		if "stamina" in player:
			_on_stamina_changed(player.stamina)
	else:
		print("StaminaBar: Joueur non trouvé ou signal manquant")

func _on_stamina_changed(new_stamina: int) -> void:
	var stamina_level: int = clamp(new_stamina, 0, 3)
	var sprite_index: int = 3 - stamina_level
	
	if sprite_index >= 0 and sprite_index < STAMINA_TEXTURES.size():
		var texture_path: String = STAMINA_TEXTURES[sprite_index]
		var texture := load(texture_path) as Texture2D
		if texture != null:
			stamina_sprite.texture = texture
			var texture_size := texture.get_size()
			if texture_size.x > 0 and texture_size.y > 0:
				stamina_sprite.texture = texture
				stamina_sprite.visible = true
				stamina_sprite.modulate = Color(1, 1, 1, 1)
				visible = true
				modulate = Color(1, 1, 1, 1)
			else:
				push_warning("StaminaBar: Texture size is invalid for " + texture_path)
		else:
			push_warning("StaminaBar: Failed to load texture: " + texture_path)
	else:
		push_warning("StaminaBar: Invalid sprite_index: " + str(sprite_index))
