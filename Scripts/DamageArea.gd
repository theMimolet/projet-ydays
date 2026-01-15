extends Area2D

@export var damage_amount : int = 10  # Dégâts infligés
@export var damage_cooldown : float = 1.0  # Temps entre chaque dégât (en secondes)

var damage_timer : float = 0.0
var players_in_area : Array[Node2D] = []

func _ready() -> void:
	# S'assurer que le monitoring est activé
	monitoring = true
	monitorable = false
	
	# Connecter les signaux pour détecter quand le joueur entre/sort de la zone
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	if damage_timer > 0.0:
		damage_timer -= delta
	
	# Infliger des dégâts aux joueurs dans la zone
	if damage_timer <= 0.0 and players_in_area.size() > 0:
		for player in players_in_area:
			if player.has_method("take_damage"):
				player.take_damage(damage_amount)
				print("Dégâts infligés: ", damage_amount, " HP restants: ", player.current_hp)
		damage_timer = damage_cooldown

func _on_body_entered(body: Node2D) -> void:
	"""Appelé quand un corps entre dans la zone"""
	if body.is_in_group("Joueur"):
		if body not in players_in_area:
			players_in_area.append(body)
			print("Joueur entré dans la zone de dégâts")

func _on_body_exited(body: Node2D) -> void:
	"""Appelé quand un corps sort de la zone"""
	if body.is_in_group("Joueur"):
		var index = players_in_area.find(body)
		if index >= 0:
			players_in_area.remove_at(index)
			print("Joueur sorti de la zone de dégâts")
