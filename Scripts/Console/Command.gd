class_name Command
extends RefCounted

## Classe représentant une commande de la console
## Utilisée par CommandRegistry pour stocker et gérer les commandes disponibles

var command_name: String
var description: String
var callback: Callable
var min_args: int = 0
var max_args: int = -1  # -1 = illimité
var usage: String = ""

func _init(
	p_name: String,
	p_callback: Callable,
	p_description: String = "",
	p_min_args: int = 0,
	p_max_args: int = -1,
	p_usage: String = ""
) -> void:
	command_name = p_name
	callback = p_callback
	description = p_description
	min_args = p_min_args
	max_args = p_max_args
	usage = p_usage if not p_usage.is_empty() else p_name

func validate_args(args: Array) -> bool:
	"""Vérifie si le nombre d'arguments est valide"""
	var arg_count: int = args.size()
	
	if arg_count < min_args:
		return false
	
	if max_args != -1 and arg_count > max_args:
		return false
	
	return true

func get_error_message(args: Array) -> String:
	"""Retourne un message d'erreur approprié pour des arguments invalides"""
	var arg_count: int = args.size()
	
	if arg_count < min_args:
		return "[color=red]Erreur: pas assez d'arguments. Usage: " + usage + "[/color]"
	
	if max_args != -1 and arg_count > max_args:
		return "[color=red]Erreur: trop d'arguments. Usage: " + usage + "[/color]"
	
	return "[color=red]Erreur: arguments invalides. Usage: " + usage + "[/color]"
