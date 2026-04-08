extends MenuSwitcher

enum menuState {MAIN, OPTIONS, PLAY, SAVES}

const OVERWORLD_SCENE := "res://Scenes/Overworld.tscn"

@onready var save_list: VBoxContainer = $MenuContainer/Saves/SaveScroll/SaveList

func _ready() -> void:
	super._ready()
	GameSettings.window_mode_changed.connect(OnFullscreenChanged)
	OnFullscreenChanged(GameSettings.IsFullscreen())
	$VersionContainer/Version.text = ProjectSettings.get_setting("application/config/version")
	_refresh_save_buttons()

func setup_switcher() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	default_index = menuState.MAIN

func _on_paramètres_pressed() -> void:
	switch_to(menuState.OPTIONS)

func _on_quitter_pressed() -> void:
	get_tree().quit()

func _on_fullscreen_pressed() -> void:
	GameSettings.toggleFullscreen()
	OnFullscreenChanged(GameSettings.isFullscreen())

func OnFullscreenChanged(isFullscreen: bool) -> void:
	if isFullscreen:
		$MenuContainer/Options/Fullscreen.text = "Fullscreen : On"
	else:
		$MenuContainer/Options/Fullscreen.text = "Fullscreen : Off"

func _on_return_pressed() -> void:
	switch_to(menuState.MAIN)

func _on_save_return_pressed() -> void:
	switch_to(menuState.PLAY)

func _on_load_game_pressed() -> void:
	_refresh_save_buttons()
	switch_to(menuState.SAVES)

func _on_new_game_pressed() -> void:
	Global.pending_new_game_save = SaveSystem.GetNextGenericSaveName()
	get_tree().change_scene_to_file(OVERWORLD_SCENE)

func _refresh_save_buttons() -> void:
	if save_list == null:
		return

	for child in save_list.get_children():
		child.queue_free()

	var saves := SaveSystem.ListSaves()
	saves.sort()

	if saves.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Aucune sauvegarde disponible"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		save_list.add_child(empty_label)
		return

	for save_name: String in saves:
		var save_button := Button.new()
		save_button.text = save_name
		save_button.theme = $MenuContainer/Main/Jouer.theme
		save_button.pressed.connect(_on_save_button_pressed.bind(save_name))
		save_list.add_child(save_button)

func _on_save_button_pressed(save_name: String) -> void:
	Global.pending_save_to_load = save_name
	get_tree().change_scene_to_file(OVERWORLD_SCENE)


func _on_jouer_pressed() -> void:
	switch_to(menuState.PLAY)
