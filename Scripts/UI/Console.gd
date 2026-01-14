extends CanvasLayer

@onready var console_panel : Panel = $ConsolePanel
@onready var history_label : RichTextLabel = $ConsolePanel/HistoryLabel
@onready var input_line : LineEdit = $ConsolePanel/InputLine

var is_open : bool = false
var command_registry : Node = null
var item_registry : Node = null
var joueur : Node = null

func _ready() -> void:
	# Créer les registres
	var command_script = load("res://Scripts/Console/CommandRegistry.gd")
	command_registry = Node.new()
	command_registry.name = "CommandRegistry"
	command_registry.set_script(command_script)
	add_child(command_registry)
	command_registry.console_reference = self
	
	var item_script = load("res://Scripts/Console/ItemRegistry.gd")
	item_registry = Node.new()
	item_registry.name = "ItemRegistry"
	item_registry.set_script(item_script)
	add_child(item_registry)
	
	# Attendre que les registres soient initialisés
	await get_tree().process_frame
	
	# Appeler manuellement _ready() sur les registres
	if item_registry.has_method("_ready"):
		item_registry._ready()
	
	# Chercher le joueur
	joueur = get_tree().get_first_node_in_group("Joueur")
	if joueur == null:
		await get_tree().process_frame
		joueur = get_tree().get_first_node_in_group("Joueur")
	
	# Cacher la console au départ
	console_panel.visible = false
	
	# Configuration de la police
	history_label.add_theme_font_size_override("normal_font_size", 10)
	history_label.add_theme_font_size_override("bold_font_size", 10)
	history_label.add_theme_font_size_override("italics_font_size", 10)
	input_line.add_theme_font_size_override("font_size", 10)
	
	# Enregistrer les commandes
	register_commands()
	
	# Connecter les signaux
	input_line.text_submitted.connect(_on_command_submitted)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F10:
			toggle_console()

func toggle_console() -> void:
	is_open = !is_open
	console_panel.visible = is_open
	
	if is_open:
		open_console()
	else:
		close_console()

func open_console() -> void:
	"""Ouvre la console"""
	input_line.grab_focus()
	if joueur != null and "canMove" in joueur:
		joueur.canMove = false
	add_message("[color=gray]Console ouverte. Tapez 'help' pour voir les commandes disponibles.[/color]")

func close_console() -> void:
	"""Ferme la console"""
	input_line.release_focus()
	if joueur != null and "canMove" in joueur:
		joueur.canMove = true
	input_line.text = ""

func _on_command_submitted(command_text: String) -> void:
	"""Appelé quand l'utilisateur appuie sur Entrée"""
	if command_text.is_empty():
		return
	
	# Afficher la commande dans l'historique
	add_message("[color=cyan]> " + command_text + "[/color]")
	
	# Exécuter la commande
	if command_registry != null:
		var result = command_registry.execute_command(command_text)
		if not result.is_empty():
			add_message(result)
	else:
		add_message("[color=red]Erreur: CommandRegistry non initialisé[/color]")
	
	# Vider le champ de saisie
	input_line.text = ""

func add_message(message: String) -> void:
	"""Ajoute un message à l'historique"""
	history_label.append_text(message + "\n")
	# Scroll vers le bas
	await get_tree().process_frame
	history_label.scroll_to_line(history_label.get_line_count() - 1)

func register_commands() -> void:
	"""Enregistre toutes les commandes disponibles"""
	
	if command_registry == null:
		return
	
	# Commande: give <item_name> [quantity]
	command_registry.register_command("give", _cmd_give, "give <item_name> [quantity] - Donne un item à l'inventaire")
	
	# Commande: add speed <value>
	command_registry.register_command("add", _cmd_add, "add speed <value> - Ajoute à la vitesse du joueur")
	
	# Commande: set speed <value>
	command_registry.register_command("set", _cmd_set, "set speed <value> - Définit la vitesse du joueur")
	
	# Commande: heal [amount]
	command_registry.register_command("heal", _cmd_heal, "heal [amount] - Soigne le joueur")
	
	# Commande: set_hp <value>
	command_registry.register_command("set_hp", _cmd_set_hp, "set_hp <value> - Définit les HP du joueur")
	
	# Commande: teleport <x> <y>
	command_registry.register_command("teleport", _cmd_teleport, "teleport <x> <y> - Téléporte le joueur")
	
	# Commande: help
	command_registry.register_command("help", _cmd_help, "help - Affiche la liste des commandes disponibles")

# ============== IMPLÉMENTATION DES COMMANDES ==============

func _cmd_give(args: Array) -> String:
	"""Commande: give <item_name> [quantity]"""
	if args.is_empty():
		return "[color=red]Erreur: Syntaxe incorrecte. Utilisez: give <item_name> [quantity][/color]"
	
	var item_name = args[0]
	var quantity : int = 1
	
	if args.size() > 1:
		quantity = int(args[1])
		if quantity <= 0:
			return "[color=red]Erreur: La quantité doit être positive.[/color]"
	
	# Récupérer l'item depuis le registre
	var item = item_registry.get_item(item_name)
	if item == null:
		var item_names = item_registry.get_all_item_names()
		var item_names_str = ""
		for i in range(item_names.size()):
			if i > 0:
				item_names_str += ", "
			item_names_str += str(item_names[i])
		return "[color=red]Erreur: Item '" + item_name + "' introuvable. Items disponibles: " + item_names_str + "[/color]"
	
	# Ajouter à l'inventaire
	var inventaire = get_tree().get_first_node_in_group("Inventaire")
	if inventaire == null:
		return "[color=red]Erreur: Inventaire introuvable.[/color]"
	
	var success = inventaire.add_item(item, quantity)
	if success:
		return "[color=green]Item '" + item_name + "' (x" + str(quantity) + ") ajouté à l'inventaire.[/color]"
	else:
		return "[color=red]Erreur: Impossible d'ajouter l'item. Inventaire plein ?[/color]"

func _cmd_add(args: Array) -> String:
	"""Commande: add speed <value>"""
	if args.size() < 2 or args[0] != "speed":
		return "[color=red]Erreur: Syntaxe incorrecte. Utilisez: add speed <value>[/color]"
	
	var value = float(args[1])
	if joueur == null:
		return "[color=red]Erreur: Joueur introuvable.[/color]"
	
	if not joueur.has_method("add_speed"):
		return "[color=red]Erreur: Le joueur n'a pas la méthode add_speed.[/color]"
	
	joueur.add_speed(value)
	return "[color=green]Vitesse augmentée de " + str(value) + ". Vitesse actuelle: " + str(joueur.get_speed()) + "[/color]"

func _cmd_set(args: Array) -> String:
	"""Commande: set speed <value>"""
	if args.size() < 2 or args[0] != "speed":
		return "[color=red]Erreur: Syntaxe incorrecte. Utilisez: set speed <value>[/color]"
	
	var value = float(args[1])
	if joueur == null:
		return "[color=red]Erreur: Joueur introuvable.[/color]"
	
	if not joueur.has_method("set_speed"):
		return "[color=red]Erreur: Le joueur n'a pas la méthode set_speed.[/color]"
	
	joueur.set_speed(value)
	return "[color=green]Vitesse définie à " + str(value) + ".[/color]"

func _cmd_heal(args: Array) -> String:
	"""Commande: heal [amount]"""
	var amount : int = 100  # Par défaut, soigne complètement
	
	if not args.is_empty():
		amount = int(args[0])
		if amount <= 0:
			return "[color=red]Erreur: La quantité doit être positive.[/color]"
	
	if joueur == null:
		return "[color=red]Erreur: Joueur introuvable.[/color]"
	
	if not joueur.has_method("heal"):
		return "[color=red]Erreur: Le joueur n'a pas la méthode heal.[/color]"
	
	joueur.heal(amount)
	return "[color=green]Joueur soigné de " + str(amount) + " HP. HP actuel: " + str(joueur.current_hp) + "/" + str(joueur.MAX_HP) + "[/color]"

func _cmd_set_hp(args: Array) -> String:
	"""Commande: set_hp <value>"""
	if args.is_empty():
		return "[color=red]Erreur: Syntaxe incorrecte. Utilisez: set_hp <value>[/color]"
	
	var value = int(args[0])
	if value < 0:
		return "[color=red]Erreur: Les HP doivent être positifs.[/color]"
	
	if joueur == null:
		return "[color=red]Erreur: Joueur introuvable.[/color]"
	
	if not joueur.has_method("set_hp"):
		return "[color=red]Erreur: Le joueur n'a pas la méthode set_hp.[/color]"
	
	joueur.set_hp(value)
	return "[color=green]HP défini à " + str(value) + "/" + str(joueur.MAX_HP) + ".[/color]"

func _cmd_teleport(args: Array) -> String:
	"""Commande: teleport <x> <y>"""
	if args.size() < 2:
		return "[color=red]Erreur: Syntaxe incorrecte. Utilisez: teleport <x> <y>[/color]"
	
	var x = float(args[0])
	var y = float(args[1])
	
	if joueur == null:
		return "[color=red]Erreur: Joueur introuvable.[/color]"
	
	joueur.global_position = Vector2(x, y)
	return "[color=green]Joueur téléporté à (" + str(x) + ", " + str(y) + ").[/color]"

func _cmd_help(args: Array) -> String:
	"""Commande: help"""
	var commands = command_registry.get_command_list()
	var help_text = "[color=yellow]=== Commandes disponibles ===[/color]\n"
	
	for cmd in commands:
		help_text += "[color=cyan]" + cmd.name + "[/color] - " + cmd.description + "\n"
	
	return help_text
