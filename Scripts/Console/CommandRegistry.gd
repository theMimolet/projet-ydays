class_name CommandRegistry
extends RefCounted

## Gestionnaire de commandes pour la console de développement
## Gère l'enregistrement, la validation et l'exécution des commandes

var _commands: Dictionary = {}  # Dictionary[String, Command]

func register_command(
	name: String,
	callback: Callable,
	description: String = "",
	min_args: int = 0,
	max_args: int = -1,
	usage: String = ""
) -> void:
	"""Enregistre une nouvelle commande dans le registre"""
	var command: Command = Command.new(
		name,
		callback,
		description,
		min_args,
		max_args,
		usage
	)
	_commands[name.to_lower()] = command

func execute_command(input: String) -> String:
	"""Parse et exécute une commande, retourne le résultat"""
	if input.strip_edges().is_empty():
		return ""
	
	# Parser l'entrée
	var parts: PackedStringArray = input.strip_edges().split(" ", false)
	if parts.is_empty():
		return ""
	
	var command_name: String = parts[0].to_lower()
	var args: Array = []
	
	# Extraire les arguments
	for i in range(1, parts.size()):
		args.append(parts[i])
	
	# Vérifier si la commande existe
	if not _commands.has(command_name):
		return "[color=red]Commande inconnue: '" + command_name + "'. Tapez 'help' pour voir les commandes disponibles.[/color]"
	
	var command: Command = _commands[command_name]
	
	# Valider les arguments
	if not command.validate_args(args):
		return command.get_error_message(args)
	
	# Vérifier que le callback est valide
	if not command.callback.is_valid():
		return "[color=red]Erreur: callback invalide pour la commande '" + command_name + "'.[/color]"
	
	# Exécuter la commande
	var result = command.callback.call(args)
	
	# Retourner le résultat
	if result == null or (result is String and result.is_empty()):
		return "[color=green]Commande exécutée avec succès.[/color]"
	
	return str(result)

func get_all_commands() -> Array[Command]:
	"""Retourne toutes les commandes enregistrées"""
	var commands_array: Array[Command] = []
	for command in _commands.values():
		commands_array.append(command)
	return commands_array

func get_command_names() -> PackedStringArray:
	"""Retourne les noms de toutes les commandes"""
	var names: PackedStringArray = PackedStringArray()
	for key in _commands.keys():
		names.append(key)
	return names

func find_completions(partial: String) -> PackedStringArray:
	"""Trouve toutes les commandes commençant par le texte partiel"""
	var completions: PackedStringArray = PackedStringArray()
	var partial_lower: String = partial.to_lower()
	
	for command_name in _commands.keys():
		if command_name.begins_with(partial_lower):
			completions.append(command_name)
	
	completions.sort()
	return completions

func has_command(name: String) -> bool:
	"""Vérifie si une commande existe"""
	return _commands.has(name.to_lower())

func get_command(name: String) -> Command:
	"""Récupère une commande par son nom"""
	return _commands.get(name.to_lower(), null)
