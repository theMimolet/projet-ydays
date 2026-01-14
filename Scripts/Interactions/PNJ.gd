extends CharacterBody2D

var dialogue_timeline: String = "timeline-test"
var has_interacted: bool = false
var player: CharacterBody2D

func _ready() -> void:
	add_to_group("PNJ")
	
	# S'assurer que le PNJ ne bouge pas
	velocity = Vector2.ZERO
	
	find_player()

func find_player() -> void:
	player = get_tree().get_first_node_in_group("Joueur")
	if player == null:
		player = get_tree().current_scene.get_node_or_null("Joueur")
	if player == null:
		push_warning("PNJ: Impossible de trouver le joueur. Le z_index ne pourra pas être mis à jour.")

func _physics_process(_delta: float) -> void:
	update_depth()

func update_depth() -> void:
	const BASE_OFFSET := 1000
	z_index = BASE_OFFSET + int(global_position.y)

func interact() -> void:
	if not has_interacted:
		has_interacted = true
	
	# Lancer le dialogue Dialogic
	Dialogic.start(dialogue_timeline)
	
	# Bloquer le mouvement du joueur pendant le dialogue
	if player != null and "canMove" in player:
		player.canMove = false
