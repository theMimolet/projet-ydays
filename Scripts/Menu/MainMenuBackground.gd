extends TextureRect


@export var frames: Array[Texture2D] = []
@export var fps: float = 10.0
var current_frame: int = 0
var time_accumulated: float = 0.0
var is_playing: bool = true

func _ready() -> void :
	load_frames_from_folder("res://Textures/MainMenuBackground/")
	if frames.size() > 0:
		texture = frames[0]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta : float) -> void :
	if not is_playing or frames.size() == 0:
		return
	
	time_accumulated += delta
	var frame_duration : float = 1.0 / fps
	
	# Avance au prochain frame si assez de temps s'est écoulé
	while time_accumulated >= frame_duration:
		time_accumulated -= frame_duration
		current_frame += 1
		
		# Gestion de la boucle
		if current_frame >= frames.size():
			current_frame = 0
		
		texture = frames[current_frame]

# Fonctions utiles
func play() -> void :
	is_playing = true
	current_frame = 0

func stop() -> void :
	is_playing = false

func pause() -> void :
	is_playing = false

func resume() -> void :
	is_playing = true

func load_frames_from_folder(folder_path: String) -> void :
	frames.clear()
	var dir := DirAccess.open(folder_path)
	if dir:
		dir.list_dir_begin()
		var file_name : String = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".png") or file_name.ends_with(".jpg"):
				frames.append(load(folder_path + "/" + file_name))
			file_name = dir.get_next()
		frames.sort() # Trie par nom de fichier
