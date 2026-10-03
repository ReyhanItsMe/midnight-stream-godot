## Skrip intro layar pembuka (Logo / Credits).
##
## Menampilkan splash logo/kredit sebelum berpindah secara otomatis
## atau lewat tombol skip menuju MainMenu via TransitionManager.
class_name Intro
extends Control

var credit_rect: TextureRect
var tween: Tween
var can_skip: bool = false
var is_finished: bool = false

func _ready() -> void:
	# Background hitam pekat
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Palette.BLACK
	add_child(bg)

	# Tampilan gambar kredit / logo studio
	credit_rect = TextureRect.new()
	credit_rect.name = "CreditRect"
	credit_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	credit_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	credit_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	credit_rect.modulate = Palette.alpha(Palette.WHITE, 0.0)
	add_child(credit_rect)

	# Ambil path gambar langsung dari registry AssetPaths
	var credit_path: String = AssetPaths.UI.INTRO_CREDITS
	if ResourceLoader.exists(credit_path):
		credit_rect.texture = load(credit_path)
	else:
		push_error("[Intro] File tidak ditemukan di: " + credit_path)

	# Beri jeda 0.5 detik sebelum pemain diizinkan melakukan skip
	get_tree().create_timer(0.5).timeout.connect(func(): can_skip = true)

	play_sequence()

func play_sequence() -> void:
	tween = create_tween()
	if credit_rect.texture != null:
		# Muncul perlahan (Fade In)
		tween.tween_property(credit_rect, "modulate:a", 1.0, 1.0)
		# Tahan selama 1.5 detik
		tween.tween_interval(1.5)
		# Menghilang perlahan (Fade Out)
		tween.tween_property(credit_rect, "modulate:a", 0.0, 1.0)
	
	tween.tween_callback(go_to_menu)

func _unhandled_input(event: InputEvent) -> void:
	if not can_skip or is_finished:
		return

	if (event is InputEventKey and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		skip()

func skip() -> void:
	if is_finished:
		return
		
	is_finished = true
	if tween and tween.is_valid():
		tween.kill()
		
	go_to_menu()

func go_to_menu() -> void:
	is_finished = true
	# Pindah scene ke Main Menu via ScenePaths dan TransitionManager
	TransitionManager.change_scene(ScenePaths.Screens.MAIN_MENU, 0.4)
