extends CanvasLayer

## Autoload pour les transitions de scène avec fondu noir

var color_rect: ColorRect

var is_transitioning: bool = false


func _ready() -> void:
	layer = 200
	
	color_rect = get_node_or_null("ColorRect") as ColorRect
	if color_rect == null:
		var rect := ColorRect.new()
		rect.name = "ColorRect"
		rect.color = Color.BLACK
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(rect)
		color_rect = rect
	
	color_rect.modulate.a = 0.0
	color_rect.visible = true


## Transition vers une nouvelle scène avec fondu noir
## black_screen_delay: temps d'attente en écran noir (0 pour transition rapide)
func transition_to_scene(scene_path: String, fade_out_duration: float = 0.5, fade_in_duration: float = 0.5, black_screen_delay: float = 0.0) -> void:
	if is_transitioning:
		return
	
	is_transitioning = true
	
	# Fondu vers noir
	var tween := create_tween()
	tween.tween_property(color_rect, "modulate:a", 1.0, fade_out_duration)
	await tween.finished
	
	# Changer de scène
	get_tree().change_scene_to_file(scene_path)
	
	# Attendre que la scène soit chargée
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Attendre un délai supplémentaire si spécifié (pour masquer le repositionnement)
	if black_screen_delay > 0.0:
		await get_tree().create_timer(black_screen_delay).timeout
	
	# Fondu depuis noir
	var tween_out := create_tween()
	tween_out.tween_property(color_rect, "modulate:a", 0.0, fade_in_duration)
	await tween_out.finished
	
	is_transitioning = false


## Fondu vers noir uniquement (sans changer de scène)
func fade_out(duration: float = 0.5) -> void:
	var tween := create_tween()
	tween.tween_property(color_rect, "modulate:a", 1.0, duration)
	await tween.finished


## Fondu depuis noir uniquement
func fade_in(duration: float = 0.5) -> void:
	var tween := create_tween()
	tween.tween_property(color_rect, "modulate:a", 0.0, duration)
	await tween.finished
