extends Area2D

@export var damage_per_hit: int = 10
@export var hit_cooldown: float = 0.6

var _cooldown_left: float = 0.0
var _players_in_area: Array[Node2D] = []

func _ready() -> void:
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	if _cooldown_left > 0.0:
		_cooldown_left -= delta
		return
	
	if damage_per_hit <= 0:
		return
	
	if _players_in_area.is_empty():
		return
	
	for player in _players_in_area:
		if is_instance_valid(player) and player.has_method("take_damage"):
			player.take_damage(damage_per_hit)
	
	_cooldown_left = hit_cooldown

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Joueur"):
		return
	
	if body in _players_in_area:
		return
	
	_players_in_area.append(body)

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("Joueur"):
		return
	
	var idx := _players_in_area.find(body)
	if idx >= 0:
		_players_in_area.remove_at(idx)
