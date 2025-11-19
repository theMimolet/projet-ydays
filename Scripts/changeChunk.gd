extends CanvasLayer

signal unloadFinished

@onready var niveau : Node = $"../Niveau" 

func _ready() -> void:
	chunkLoad("res://Scenes/ck-test-1.tscn", Vector2(320, -90))

func chunkChange(chunk: String, posJoueur: Vector2) -> void:
	chunkUnload()
	await unloadFinished
	chunkLoad(chunk, posJoueur)

func chunkUnload() -> void:
	$Animateur.play("fade-out")

func chunkLoad(chunk: String, posJoueur: Vector2) -> void: 
	$Animateur.play("RESET")
	niveau.add_child(load(chunk).instantiate()) # Charge le chunk au jeu
	$"../Joueur".position = posJoueur
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
