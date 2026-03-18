extends MenuSwitcher

enum menuState {MAIN, OPTIONS}

func _ready() -> void:
	GameSettings.window_mode_changed.connect(OnFullscreenChanged)
	OnFullscreenChanged(GameSettings.IsFullscreen())
	$VersionContainer/Version.text = ProjectSettings.get_setting("application/config/version")

func setup_switcher() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	default_index = menuState.MAIN

func _on_jouer_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Overworld.tscn")

func _on_paramètres_pressed() -> void:
	switch_to(menuState.OPTIONS)
	
func _on_quitter_pressed() -> void:
	get_tree().quit()

func _on_fullscreen_pressed() -> void:
	GameSettings.toggleFullscreen()
	OnFullscreenChanged(GameSettings.isFullscreen())

func OnFullscreenChanged(isFullscreen: bool) -> void:
	if isFullscreen : 
		$MenuContainer/Options/Fullscreen.text = "Fullscreen : On"
	else : 
		$MenuContainer/Options/Fullscreen.text = "Fullscreen : Off"

func _on_return_pressed() -> void:
	switch_to(menuState.MAIN)
