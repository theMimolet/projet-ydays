extends Node

signal window_mode_changed(isFullscreen : bool)

var globalVolume : float = 0

func IsFullscreen() -> bool:
	return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	
func ToggleFullscreen() -> void: 
		var mode := DisplayServer.window_get_mode()
		var is_window: bool = mode != DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if is_window else DisplayServer.WINDOW_MODE_WINDOWED)
		
		window_mode_changed.emit(IsFullscreen())
