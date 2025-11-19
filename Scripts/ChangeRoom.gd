extends CanvasLayer

signal unloadFinished

@onready var niveau : Node = $"../Niveau" 
@onready var joueur : Node = $"../Joueur" 

func _ready() -> void:
	roomLoad("res://Scenes/RoomTest1.tscn", Vector2(320, -90))

func roomChange(room: String, posJoueur: Vector2) -> void:
	roomUnload()
	await unloadFinished
	roomLoad(room, posJoueur)

func roomUnload() -> void:
	$Animateur.play("fade-out")
	joueur.canMove = false

func roomLoad(room: String, posJoueur: Vector2) -> void: 
	$Animateur.play("RESET")
	niveau.add_child(load(room).instantiate()) # Charge le chunk au jeu
	Global.currentRoom = room
	joueur.position = posJoueur
	$Animateur.play("fade-in")

func _on_animateur_animation_finished(anim_name: StringName) -> void:
	match anim_name :
		"fade-out" :
			$Animateur.play("RESET")
			print(niveau.get_children())
			for child in niveau.get_children() :
				print(child)
				child.queue_free()
				child = null
			emit_signal("unloadFinished")
		"fade-in" :
			joueur.canMove = true
