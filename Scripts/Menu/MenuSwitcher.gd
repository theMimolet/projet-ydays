class_name MenuSwitcher
extends SwitcherBase

func _ready() -> void:
	switcher_container = find_child("MenuContainer")
	super._ready()
