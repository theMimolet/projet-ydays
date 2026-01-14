extends CanvasLayer

@onready var hp_label : Label = $HUDContainer/HPContainer/HPLabel

var joueur : Node = null

func _ready() -> void:
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
	if hp_label != null:
		hp_label.text = "HP: %d / %d" % [new_hp, max_hp]
