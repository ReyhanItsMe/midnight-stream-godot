extends Control

const NEXT_SCENE_PATH: String = "res://scenes/ui/screens/main_menu/MainMenu.tscn"
const CREDIT_IMAGE_PATH: String = "res://assets/ui/intro/intro-credits.png"

var credit_rect: TextureRect
var tween: Tween
var can_skip: bool = false
var is_finished: bool = false

func _ready() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color.BLACK
	add_child(bg)

	credit_rect = TextureRect.new()
	credit_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	credit_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	credit_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	credit_rect.modulate = Color(1.0, 1.0, 1.0, 0.0)
	add_child(credit_rect)

	if ResourceLoader.exists(CREDIT_IMAGE_PATH):
		credit_rect.texture = load(CREDIT_IMAGE_PATH)
	else:
		push_error("[Intro] FILE TIDAK DITEMUKAN: " + CREDIT_IMAGE_PATH)

	get_tree().create_timer(0.5).timeout.connect(func(): can_skip = true)

	play_sequence()

func play_sequence() -> void:
	tween = create_tween()
	if credit_rect.texture != null:
		tween.tween_property(credit_rect, "modulate:a", 1.0, 1.0)
		tween.tween_interval(1.5)
		tween.tween_property(credit_rect, "modulate:a", 0.0, 1.0)
	tween.tween_callback(go_to_menu)

func _unhandled_input(event: InputEvent) -> void:
	if not can_skip or is_finished:
		return

	if (event is InputEventKey and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		skip()

func skip() -> void:
	is_finished = true
	if tween and tween.is_valid():
		tween.kill()
	go_to_menu()

func go_to_menu() -> void:
	get_tree().change_scene_to_file(NEXT_SCENE_PATH)
