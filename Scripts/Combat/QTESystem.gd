extends Control
class_name QTESystem

## Système de Quick Time Event : affiche une séquence de touches (Z, Q, S, D)
## que le joueur doit appuyer dans l'ordre et dans le temps imparti.

signal qte_completed
signal qte_failed
signal qte_key_success(key: String)
signal qte_key_failed(key: String)

@export var nombre_touches: int = 4
@export var temps_par_touche: float = 1.0
@export var touches_possibles: Array[String] = ["Z", "Q", "S", "D"]

@onready var container_touches: HBoxContainer = $ContainerTouches
@onready var label_temps: Label = $LabelTemps
@onready var panel_qte: Panel = $PanelQTE

var sequence_actuelle: Array[String] = []
var index_actuel: int = 0
var temps_restant: float = 0.0
var qte_en_cours: bool = false

# Mapping des touches vers les actions Godot
var key_mapping: Dictionary = {
	"Z": KEY_W,
	"Q": KEY_A,
	"S": KEY_S,
	"D": KEY_D,
}


func _ready() -> void:
	set_process(false)
	_cacher_qte()


func _process(delta: float) -> void:
	if not qte_en_cours:
		return
	
	temps_restant -= delta
	_update_affichage_temps()
	
	if temps_restant <= 0:
		_echouer_qte()


func _input(event: InputEvent) -> void:
	if not qte_en_cours:
		return
	
	if event is InputEventKey and event.pressed and not event.echo:
		var touche_attendue := sequence_actuelle[index_actuel]
		var keycode_attendu: int = key_mapping.get(touche_attendue, 0)
		
		if event.physical_keycode == keycode_attendu:
			_valider_touche()
		else:
			# Mauvaise touche = échec
			_echouer_qte()


func lancer_qte(nb_touches: int = -1) -> void:
	print("[QTE] Lancement du QTE")
	if nb_touches > 0:
		nombre_touches = nb_touches
	
	_generer_sequence()
	print("[QTE] Séquence générée: ", sequence_actuelle)
	index_actuel = 0
	temps_restant = temps_par_touche * nombre_touches
	qte_en_cours = true
	
	_afficher_qte()
	_update_affichage_sequence()
	set_process(true)
	print("[QTE] panel_qte visible = ", panel_qte.visible if panel_qte else "NULL")


func _generer_sequence() -> void:
	sequence_actuelle.clear()
	for i in range(nombre_touches):
		var touche := touches_possibles[randi() % touches_possibles.size()]
		sequence_actuelle.append(touche)


func _valider_touche() -> void:
	qte_key_success.emit(sequence_actuelle[index_actuel])
	index_actuel += 1
	_update_affichage_sequence()
	
	if index_actuel >= sequence_actuelle.size():
		_reussir_qte()


func _reussir_qte() -> void:
	qte_en_cours = false
	set_process(false)
	_cacher_qte()
	qte_completed.emit()


func _echouer_qte() -> void:
	if index_actuel < sequence_actuelle.size():
		qte_key_failed.emit(sequence_actuelle[index_actuel])
	qte_en_cours = false
	set_process(false)
	_cacher_qte()
	qte_failed.emit()


func _afficher_qte() -> void:
	if panel_qte:
		panel_qte.visible = true


func _cacher_qte() -> void:
	if panel_qte:
		panel_qte.visible = false


func _update_affichage_sequence() -> void:
	if not container_touches:
		return
	
	# Nettoyer les anciens labels
	for child in container_touches.get_children():
		child.queue_free()
	
	# Créer un label pour chaque touche
	for i in range(sequence_actuelle.size()):
		var label := Label.new()
		label.text = sequence_actuelle[i]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2(40, 40)
		
		# Style selon l'état
		if i < index_actuel:
			# Touche validée
			label.modulate = Color.GREEN
		elif i == index_actuel:
			# Touche actuelle
			label.modulate = Color.YELLOW
			label.add_theme_font_size_override("font_size", 24)
		else:
			# Touche à venir
			label.modulate = Color.WHITE
		
		container_touches.add_child(label)


func _update_affichage_temps() -> void:
	if label_temps:
		label_temps.text = "%.1f s" % temps_restant
		if temps_restant < 1.0:
			label_temps.modulate = Color.RED
		else:
			label_temps.modulate = Color.WHITE
