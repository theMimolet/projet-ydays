class_name ConsoleCommands
extends RefCounted

## Module contenant toutes les commandes de base de la console
## Toutes les fonctions sont statiques pour être facilement accessibles

# ============== COMMANDES DE TEST ==============

static func cmd_ping(_args: Array) -> String:
	"""Commande de test simple"""
	return "[color=green]pong[/color]"

# ============== COMMANDES D'AIDE ==============

static func cmd_help(args: Array) -> String:
	"""Affiche la liste des commandes ou les details d'une commande specifique"""
	var registry: CommandRegistry = _get_registry()
	if registry == null:
		return "[color=red]Erreur: Registry introuvable[/color]"
	
	# Si un nom de commande est fourni, afficher les details
	if args.size() > 0:
		var command_name: String = args[0]
		var command: Command = registry.get_command(command_name)
		
		
		if command == null:
			return "[color=red]Commande inconnue: '" + command_name + "'[/color]"
		
		var help_text: String = "[color=yellow]=== " + command.command_name.to_upper() + " ===[/color]\n"
		help_text += "[color=white]Description: " + command.description + "[/color]\n"
		help_text += "[color=white]Usage: " + command.usage + "[/color]"
		return help_text
	
	# Sinon, afficher toutes les commandes
	var commands: Array[Command] = registry.get_all_commands()
	var help_text: String = "[color=yellow]=== COMMANDES DISPONIBLES ===[/color]\n"
	
	for command in commands:
		help_text += "[color=cyan]" + command.command_name.rpad(15) + "[/color] - " + command.description + "\n"
	
	help_text += "\n[color=gray]Tapez 'help <commande>' pour plus de details[/color]"
	return help_text

static func cmd_clear(_args: Array) -> String:
	"""Efface l'historique de la console"""
	var console: CanvasLayer = _get_console()
	if console and console.has_method("clear_history"):
		console.clear_history()
		return ""  # Pas de message car l'historique sera effacé
	return "[color=red]Erreur: Console introuvable[/color]"

# ============== COMMANDES DE JEU ==============

static func cmd_give(args: Array) -> String:
	"""Donne un item au joueur"""
	var item_name: String = args[0]
	var quantity: int = 1
	
	if args.size() > 1:
		quantity = int(args[1])
		if quantity <= 0:
			return "[color=red]Erreur: La quantite doit etre positive[/color]"
	
	# Récupérer l'inventaire
	var inventaire: Node = _get_tree().get_first_node_in_group("Inventaire")
	if inventaire == null:
		return "[color=red]Erreur: Inventaire introuvable[/color]"
	
	# Créer l'item
	var item: Item = Item.new()
	item.item_name = item_name
	item.item_description = "Item donné via console"
	item.max_stack = 99
	item.item_type = "console"
	
	# Ajouter à l'inventaire
	if inventaire.has_method("add_item"):
		var success: bool = inventaire.add_item(item, quantity)
		if success:
			return "[color=green]Item '" + item_name + "' (x" + str(quantity) + ") ajouté à l'inventaire[/color]"
		else:
			return "[color=red]Erreur: Impossible d'ajouter l'item (inventaire plein ?)[/color]"
	
	return "[color=red]Erreur: Inventaire invalide[/color]"

static func cmd_teleport(args: Array) -> String:
	"""Téléporte le joueur à une position"""
	var x: float = float(args[0])
	var y: float = float(args[1])
	
	var joueur: Node = _get_tree().get_first_node_in_group("Joueur")
	if joueur == null:
		return "[color=red]Erreur: Joueur introuvable[/color]"
	
	joueur.global_position = Vector2(x, y)
	return "[color=green]Téléporté à (" + str(x) + ", " + str(y) + ")[/color]"

static func cmd_set_speed(args: Array) -> String:
	"""Definit la vitesse du joueur"""
	var speed: float = float(args[0])
	
	if speed < 0:
		return "[color=red]Erreur: La vitesse doit etre positive[/color]"
	
	var joueur: Node = _get_tree().get_first_node_in_group("Joueur")
	if joueur == null:
		return "[color=red]Erreur: Joueur introuvable[/color]"
	
	if joueur.has_method("set_speed"):
		joueur.set_speed(speed)
		return "[color=green]Vitesse définie à " + str(speed) + "[/color]"
	
	return "[color=red]Erreur: Méthode set_speed() introuvable[/color]"

static func cmd_heal(args: Array) -> String:
	"""Soigne le joueur"""
	var amount: int = 100  # Par défaut, soigne complètement
	
	if args.size() > 0:
		amount = int(args[0])
		if amount <= 0:
			return "[color=red]Erreur: La quantite doit etre positive[/color]"
	
	var joueur: Node = _get_tree().get_first_node_in_group("Joueur")
	if joueur == null:
		return "[color=red]Erreur: Joueur introuvable[/color]"
	
	if joueur.has_method("heal"):
		joueur.heal(amount)
		var current_hp: int = joueur.get("current_hp") if "current_hp" in joueur else 0
		var max_hp: int = joueur.get("MAX_HP") if "MAX_HP" in joueur else 0
		return "[color=green]Soigné de " + str(amount) + " HP. HP actuel: " + str(current_hp) + "/" + str(max_hp) + "[/color]"
	
	return "[color=red]Erreur: Méthode heal() introuvable[/color]"

static func cmd_set_hp(args: Array) -> String:
	"""Definit les HP du joueur"""
	var hp: int = int(args[0])
	
	if hp < 0:
		return "[color=red]Erreur: Les HP doivent etre positifs[/color]"
	
	var joueur: Node = _get_tree().get_first_node_in_group("Joueur")
	if joueur == null:
		return "[color=red]Erreur: Joueur introuvable[/color]"
	
	if joueur.has_method("set_hp"):
		joueur.set_hp(hp)
		var max_hp: int = joueur.get("MAX_HP") if "MAX_HP" in joueur else 0
		return "[color=green]HP défini à " + str(hp) + "/" + str(max_hp) + "[/color]"
	
	return "[color=red]Erreur: Méthode set_hp() introuvable[/color]"

static func cmd_give_weapon(args: Array) -> String:
	"""Donne une arme au joueur (dague, epee1, epee2, epee3, bloodsword)"""
	var weapon_name: String = args[0].to_lower()
	
	# Mapping des noms d'armes vers les fichiers .tres
	var weapon_paths: Dictionary = {
		"dague": "res://Resources/Armes/Dague.tres",
		"epee1": "res://Resources/Armes/Epee1.tres",
		"epee2": "res://Resources/Armes/Epee2.tres",
		"epee3": "res://Resources/Armes/Epee3.tres",
		"bloodsword": "res://Resources/Armes/BloodSword.tres",
		"blood": "res://Resources/Armes/BloodSword.tres",
	}
	
	if not weapon_paths.has(weapon_name):
		var available: String = ", ".join(weapon_paths.keys())
		return "[color=red]Arme inconnue: '" + weapon_name + "'. Disponibles: " + available + "[/color]"
	
	var weapon_path: String = weapon_paths[weapon_name]
	
	if not ResourceLoader.exists(weapon_path):
		return "[color=red]Erreur: Fichier d'arme introuvable: " + weapon_path + "[/color]"
	
	var weapon: Resource = load(weapon_path)
	if weapon == null:
		return "[color=red]Erreur: Impossible de charger l'arme[/color]"
	
	# Récupérer l'inventaire
	var inventaire: Node = _get_tree().get_first_node_in_group("Inventaire")
	if inventaire == null:
		return "[color=red]Erreur: Inventaire introuvable[/color]"
	
	# Ajouter à l'inventaire
	if inventaire.has_method("add_item"):
		var success: bool = inventaire.add_item(weapon, 1)
		if success:
			var nom: String = weapon.item_name if "item_name" in weapon else weapon_name
			return "[color=green]Arme '" + nom + "' ajoutée à l'inventaire![/color]"
		else:
			return "[color=red]Erreur: Inventaire plein[/color]"
	
	return "[color=red]Erreur: Inventaire invalide[/color]"


static func cmd_equip_weapon(args: Array) -> String:
	"""Equipe directement une arme sur le joueur (dague, epee1, epee2, epee3, bloodsword)"""
	var weapon_name: String = args[0].to_lower()
	
	var weapon_paths: Dictionary = {
		"dague": "res://Resources/Armes/Dague.tres",
		"epee1": "res://Resources/Armes/Epee1.tres",
		"epee2": "res://Resources/Armes/Epee2.tres",
		"epee3": "res://Resources/Armes/Epee3.tres",
		"bloodsword": "res://Resources/Armes/BloodSword.tres",
		"blood": "res://Resources/Armes/BloodSword.tres",
	}
	
	if not weapon_paths.has(weapon_name):
		var available: String = ", ".join(weapon_paths.keys())
		return "[color=red]Arme inconnue: '" + weapon_name + "'. Disponibles: " + available + "[/color]"
	
	var weapon_path: String = weapon_paths[weapon_name]
	var weapon: Resource = load(weapon_path)
	if weapon == null:
		return "[color=red]Erreur: Impossible de charger l'arme[/color]"
	
	var joueur: Node = _get_tree().get_first_node_in_group("Joueur")
	if joueur == null:
		return "[color=red]Erreur: Joueur introuvable[/color]"
	
	if joueur.has_method("equiper_arme"):
		joueur.equiper_arme(weapon)
		var nom: String = weapon.item_name if "item_name" in weapon else weapon_name
		return "[color=green]Arme '" + nom + "' équipée![/color]"
	
	return "[color=red]Erreur: Méthode equiper_arme() introuvable sur le joueur[/color]"


static func cmd_list_weapons(_args: Array) -> String:
	"""Liste toutes les armes disponibles"""
	var weapons_info: Array = [
		["dague", "Dague", "3-6 dmg", "20% crit"],
		["epee1", "Epee de fer", "5-10 dmg", "10% crit"],
		["epee2", "Epee d'acier", "8-14 dmg", "12% crit"],
		["bloodsword", "Epee de sang", "12-18 dmg", "15% crit"],
		["epee3", "Epee legendaire", "15-25 dmg", "25% crit"],
	]
	
	var result: String = "[color=yellow]=== ARMES DISPONIBLES ===[/color]\n"
	for info in weapons_info:
		result += "[color=cyan]" + info[0].rpad(12) + "[/color] "
		result += info[1].rpad(18) + " | " + info[2].rpad(10) + " | " + info[3] + "\n"
	
	result += "\n[color=gray]Utilisez 'give_weapon <nom>' pour ajouter à l'inventaire[/color]"
	result += "\n[color=gray]Utilisez 'equip_weapon <nom>' pour équiper directement[/color]"
	return result


static func cmd_set_room(args: Array) -> String:
	"""Definit la nouvelle room et le spawnpoint du joueur"""
	var requestedRoom: String = String(args[0])
	var requestedSpawn: String = "InitialSpawn"
	
	if args.size() > 1:
		requestedSpawn = String(args[1])
	
	if requestedRoom == null : 
		return "[color=red]Erreur: Veuillez entrer le chemin de la room[/color]"
	
	var cheminScene: String = "res://Scenes/Rooms/"+requestedRoom+".tscn"
	
	if !ResourceLoader.exists(cheminScene):
		return "[color=red]Erreur: La room "+requestedRoom+" n'existe pas[/color]"
	
	var sceneResource: PackedScene = load(cheminScene) 
	var sceneInstance := sceneResource.instantiate()
	
	if !sceneInstance.has_node(requestedSpawn):
		return "[color=red]Erreur: Le Spawn "+requestedSpawn+" n'existe pas[/color]"
		
	var spawnNode : Node = sceneInstance.get_node(requestedSpawn)
	if spawnNode.get_class() != "Node2D":
		return "[color=red]Erreur: Le Spawn "+requestedSpawn+" n'a pas le bon type[/color]"
	
	sceneInstance.queue_free()
	
	var roomManager : Node = _get_tree().get_first_node_in_group("RoomManager")
	
	roomManager.roomChange(cheminScene, requestedSpawn)
	
	return "[color=green] Chargement de "+requestedRoom+"...[/color]"

# ============== FONCTIONS UTILITAIRES ==============

static func _get_tree() -> SceneTree:
	"""Récupère le SceneTree"""
	return Engine.get_main_loop() as SceneTree

static func _get_console() -> CanvasLayer:
	"""Récupère la console"""
	var tree: SceneTree = _get_tree()
	if tree:
		return tree.get_first_node_in_group("DevConsole")
	return null

static func _get_registry() -> CommandRegistry:
	"""Récupère le CommandRegistry depuis la console"""
	var console: CanvasLayer = _get_console()
	if console and "registry" in console:
		return console.registry
	return null
