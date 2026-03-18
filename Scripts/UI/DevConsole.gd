extends CanvasLayer

## Console de développement professionnelle
## F10 pour ouvrir/fermer

@onready var console_panel: Panel = $ConsolePanel
@onready var history_label: RichTextLabel = $ConsolePanel/MarginContainer/VBoxContainer/HistoryLabel
@onready var input_line: LineEdit = $ConsolePanel/MarginContainer/VBoxContainer/InputLine

var registry: CommandRegistry = null
var is_open: bool = false
var command_history: Array[String] = []
var history_index: int = -1
var max_history: int = 50

# Autocomplétion
var completion_suggestions: PackedStringArray = PackedStringArray()
var completion_index: int = -1
var original_input: String = ""

func _ready() -> void:
	add_to_group("DevConsole")
	
	# Créer le registry
	registry = CommandRegistry.new()
	
	# Enregistrer toutes les commandes
	_register_commands()
	
	# Configurer l'UI
	console_panel.visible = false
	history_label.bbcode_enabled = true
	history_label.scroll_following = true
	
	# Créer une police système
	var font: SystemFont = SystemFont.new()
	font.font_names = ["Arial", "Helvetica", "Liberation Sans", "sans-serif"]
	
	# Appliquer la police
	history_label.add_theme_font_override("normal_font", font)
	history_label.add_theme_font_override("bold_font", font)
	history_label.add_theme_font_override("italics_font", font)
	input_line.add_theme_font_override("font", font)
	
	# Taille de police
	history_label.add_theme_font_size_override("normal_font_size", 14)
	history_label.add_theme_font_size_override("bold_font_size", 14)
	history_label.add_theme_font_size_override("italics_font_size", 14)
	input_line.add_theme_font_size_override("font_size", 14)
	
	# Connecter les signaux
	input_line.text_submitted.connect(_on_command_submitted)

func _input(event: InputEvent) -> void:
	# Ouvrir/Fermer la console avec F10
	if event is InputEventKey and event.pressed and event.keycode == KEY_F10:
		toggle_console()
		get_viewport().set_input_as_handled()
		return
	
	# Si la console n'est pas ouverte, ignorer
	if not is_open:
		return
	
	# Gestion de l'historique avec flèches haut/bas
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_UP:
			_navigate_history(-1)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_DOWN:
			_navigate_history(1)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_TAB:
			_autocomplete()
			get_viewport().set_input_as_handled()

func toggle_console() -> void:
	"""Ouvre/ferme la console"""
	is_open = not is_open
	console_panel.visible = is_open
	
	if is_open:
		_open_console()
	else:
		_close_console()

func _open_console() -> void:
	"""Ouvre la console"""
	input_line.grab_focus()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Bloquer le mouvement du joueur
	var joueur: Node = get_tree().get_first_node_in_group("Joueur")
	if joueur and "canMove" in joueur:
		joueur.canMove = false
	
	add_message("[color=gray]Console ouverte. Tapez 'help' pour voir les commandes.[/color]")

func _close_console() -> void:
	"""Ferme la console"""
	input_line.release_focus()
	input_line.text = ""
	history_index = -1
	completion_suggestions.clear()
	completion_index = -1
	
	# Débloquer le mouvement du joueur
	var joueur: Node = get_tree().get_first_node_in_group("Joueur")
	if joueur and "canMove" in joueur:
		joueur.canMove = true
	
	# Garder le curseur visible (ne pas le cacher)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_command_submitted(command_text: String) -> void:
	"""Appelé quand l'utilisateur appuie sur Entrée"""
	if command_text.strip_edges().is_empty():
		return
	
	# Ajouter à l'historique
	_add_to_history(command_text)
	
	# Afficher la commande
	add_message("[color=cyan]> " + command_text + "[/color]")
	
	# Exécuter la commande
	var result: String = registry.execute_command(command_text)
	if not result.is_empty():
		add_message(result)
	
	# Vider l'input et garder le focus
	input_line.text = ""
	history_index = -1
	completion_suggestions.clear()
	completion_index = -1
	
	# Remettre le focus sur l'input
	input_line.grab_focus()

func add_message(message: String) -> void:
	"""Ajoute un message à l'historique"""
	history_label.append_text(message + "\n")
	# Forcer le scroll vers le bas
	await get_tree().process_frame
	var scrollbar: VScrollBar = history_label.get_v_scroll_bar()
	if scrollbar:
		scrollbar.value = scrollbar.max_value

func clear_history() -> void:
	"""Efface l'historique de la console"""
	history_label.clear()

func _add_to_history(command: String) -> void:
	"""Ajoute une commande à l'historique"""
	# Ne pas ajouter si c'est la même que la dernière
	if command_history.size() > 0 and command_history[-1] == command:
		return
	
	command_history.append(command)
	
	# Limiter la taille de l'historique
	if command_history.size() > max_history:
		command_history.pop_front()

func _navigate_history(direction: int) -> void:
	"""Navigue dans l'historique des commandes (↑ ↓)"""
	if command_history.is_empty():
		return
	
	# Initialiser l'index si nécessaire
	if history_index == -1:
		if direction < 0:
			history_index = command_history.size()
		else:
			return
	
	# Naviguer
	history_index += direction
	history_index = clampi(history_index, 0, command_history.size())
	
	# Afficher la commande
	if history_index < command_history.size():
		input_line.text = command_history[history_index]
		input_line.caret_column = input_line.text.length()
	else:
		input_line.text = ""

func _autocomplete() -> void:
	"""Autocomplétion avec TAB"""
	var current_text: String = input_line.text.strip_edges()
	
	# Si on commence une nouvelle recherche
	if completion_index == -1:
		if current_text.is_empty():
			return
		
		original_input = current_text
		completion_suggestions = registry.find_completions(current_text)
		
		if completion_suggestions.is_empty():
			return
		
		completion_index = 0
	else:
		# Cycle vers la suggestion suivante
		completion_index = (completion_index + 1) % completion_suggestions.size()
	
	# Appliquer la suggestion
	if completion_suggestions.size() > 0:
		input_line.text = completion_suggestions[completion_index]
		input_line.caret_column = input_line.text.length()
		
		# Afficher les suggestions
		if completion_suggestions.size() > 1:
			var suggestions_str: String = " | ".join(completion_suggestions)
			add_message("[color=gray]Suggestions: " + suggestions_str + "[/color]")

func _register_commands() -> void:
	"""Enregistre toutes les commandes disponibles"""
	# Test
	registry.register_command("ping", ConsoleCommands.cmd_ping, "Test de connexion", 0, 0)
	
	# Aide
	registry.register_command("help", ConsoleCommands.cmd_help, "Affiche les commandes disponibles", 0, 1, "help [commande]")
	registry.register_command("clear", ConsoleCommands.cmd_clear, "Efface l'historique", 0, 0)
	
	# Jeu
	registry.register_command("give", ConsoleCommands.cmd_give, "Donne un item", 1, 2, "give <item> [quantite]")
	registry.register_command("teleport", ConsoleCommands.cmd_teleport, "Teleporte le joueur", 2, 2, "teleport <x> <y>")
	registry.register_command("set_speed", ConsoleCommands.cmd_set_speed, "Definit la vitesse", 1, 1, "set_speed <valeur>")
	registry.register_command("heal", ConsoleCommands.cmd_heal, "Soigne le joueur", 0, 1, "heal [quantite]")
	registry.register_command("set_hp", ConsoleCommands.cmd_set_hp, "Definit les HP", 1, 1, "set_hp <valeur>")
	registry.register_command("set_room", ConsoleCommands.cmd_set_room, "Change la room actuelle", 1, 2, "set_hp <room> [spawnpoint]")
	
	# Armes
	registry.register_command("give_weapon", ConsoleCommands.cmd_give_weapon, "Donne une arme", 1, 1, "give_weapon <dague|epee1|epee2|epee3|bloodsword>")
	registry.register_command("give_all_weapons", ConsoleCommands.cmd_give_all_weapons, "Donne toutes les armes", 0, 0, "give_all_weapons")
	registry.register_command("equip_weapon", ConsoleCommands.cmd_equip_weapon, "Equipe une arme", 1, 1, "equip_weapon <dague|epee1|epee2|epee3|bloodsword>")
	registry.register_command("list_weapons", ConsoleCommands.cmd_list_weapons, "Liste les armes", 0, 0, "list_weapons")
