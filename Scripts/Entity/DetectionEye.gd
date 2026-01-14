extends AnimatedSprite2D

var origin : Vector2
@onready var hostileModule : Node2D = $"../HostileModule"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	origin = position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	frame = hostileModule.niveauAlerte
	
	if hostileModule.niveauAlerte == 5 : 
		position = origin + Vector2(randi() % 20,randi() % 20) 
