extends MenuSwitcher

enum menuState {MAIN, OPTIONS}
#@onready var join_values: NodePath = "MenuContainer/Join/Values"

func setup_switcher() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	default_index = menuState.MAIN
	#$VersionContainer/Version.text = "v" + ProjectSettings.get_setting("application/config/version")

func _on_jouer_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Overworld.tscn")

func _on_quitter_pressed() -> void:
	get_tree().quit()
