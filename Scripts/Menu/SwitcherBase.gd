# SwitcherBase.gd - Your brilliant logic, now universal!
class_name SwitcherBase
extends Node

# The container that holds the switchable items
@export var switcher_container: Container
var current_index: int = 0
var default_index: int = 0

func _ready() -> void:
	if not switcher_container:
		auto_find_container()
	
	setup_switcher()
	switch_to(default_index)
	connect_signals()

# Try to find the container automatically
func auto_find_container() -> void :
	# Look for common container names
	switcher_container = find_child("MenuContainer") # For menus
	if not switcher_container:
		switcher_container = find_child("MarginContainer") # For tabs
	if not switcher_container:
		switcher_container = find_child("Container") # Generic

# Override in child classes
func setup_switcher() -> void :
	pass

# Override in child classes
func connect_signals() -> void :
	pass

# YOUR BRILLIANT SWITCHING LOGIC - now universal! ✨
func switch_to(index: int) -> void:
	if not switcher_container:
		push_error("No switcher container found!")
		return
		
	var child_index := 0
	for child in switcher_container.get_children():
		if child_index == index:
			child.show()
		else:
			child.hide()
		child_index += 1
	current_index = index

func return_to_default() -> void:
	switch_to(default_index)

func get_children_number() -> int:
	return switcher_container.get_child_count() if switcher_container else 0
