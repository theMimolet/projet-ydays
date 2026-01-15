extends Node2D

func _ready() -> void:
	# S'assurer que la souris est visible
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_menu_principal_pressed() -> void:
	"""Retourne au menu principal"""
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

func _on_charger_sauvegarde_pressed() -> void:
	"""Charge une sauvegarde (à implémenter plus tard)"""
	print("Chargement de sauvegarde - à implémenter")
