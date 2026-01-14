extends Node

# Registre centralisé de toutes les commandes de la console
var commands : Dictionary = {}
var console_reference = null

func _ready() -> void:
	# Enregistrer les commandes de base
	register_default_commands()

func register_command(name: String, callback: Callable, description: String = "") -> void:
	"""Enregistre une nouvelle commande"""
	commands[name.to_lower()] = {
		"callback": callback,
		"description": description,
		"name": name
	}

func execute_command(command_line: String) -> String:
	"""Exécute une commande et retourne le résultat"""
	if command_line.is_empty():
		return ""
	
	# Parser la commande
	var parts = command_line.strip_edges().split(" ", false)
	if parts.is_empty():
		return ""
	
	var command_name = parts[0].to_lower()
	var args : Array = []
	if parts.size() > 1:
		for i in range(1, parts.size()):
			args.append(parts[i])
	
	# Vérifier si la commande existe
	if not command_name in commands:
		return "[color=red]Erreur: Commande inconnue '" + command_name + "'. Tapez 'help' pour voir les commandes disponibles.[/color]"
	
	# Exécuter la commande
	var command_data = commands[command_name]
	var callback = command_data.callback
	
	if callback.is_valid():
		var result = callback.callv(args)
		return result if result != null else "[color=green]Commande exécutée avec succès.[/color]"
	else:
		return "[color=red]Erreur: Callback invalide pour la commande '" + command_name + "'.[/color]"

func get_command_list() -> Array:
	"""Retourne la liste de toutes les commandes avec leurs descriptions"""
	var list : Array = []
	for key in commands.keys():
		var cmd = commands[key]
		list.append({
			"name": cmd.name,
			"description": cmd.description
		})
	return list

func register_default_commands() -> void:
	"""Enregistre les commandes par défaut"""
	# Les commandes seront enregistrées depuis Console.gd après l'initialisation
	pass
