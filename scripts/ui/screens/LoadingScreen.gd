extends Control
class_name LoadingScreen

const VIEWPORT_RES: Vector2 = Vector2(640, 360)

const RUN_FRAMES: Array[String] = [
	"res://assets/sprites/characters/rian/kanan_1.png",
	"res://assets/sprites/characters/rian/kanan_2.png",
	"res://assets/sprites/characters/rian/kanan_3.png"
]

const COL_BG_DEEP: Color = Color(0.02, 0.02, 0.04, 1.0)
const COL_BAR_BG: Color = Color(0.06, 0.08, 0.12, 0.95)
const COL_BAR_FILL: Color = Color(0.95, 0.82, 0.25, 1.0)
const COL_BORDER_GOLD: Color = Color(0.65, 0.55, 0.22, 0.9)
const COL_BORDER_OUTER: Color = Color(0.18, 0.20, 0.28, 0.7)
const COL_TEXT_GOLD: Color = Color(0.95, 0.82, 0.25, 1.0)
const COL_TEXT_MUTED: Color = Color(0.50, 0.55, 0.65, 1.0)

var target_scene_path: String = "":
	set(val):
		target_scene_path = val
		if is_inside_tree() and target_scene_path != "":
			_begin_threaded_load()

var target_progress: float = 0.0
var displayed_progress: float = 0.0

var run_textures: Array[Texture2D] = []
var sprite_rian: TextureRect
var frame_timer: float = 0.0
var current_frame_idx: int = 0
const FRAME_DURATION: float = 0.11

var progress_bar: ProgressBar
var lbl_percentage: Label
var lbl_status: Label
var is_loading_complete: bool = false
var _has_started_request: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_preset(Control.PRESET_FULL_RECT)
	custom_minimum_size = VIEWPORT_RES

	_load_textures()
	_build_ui()

	if target_scene_path != "":
		_begin_threaded_load()

func _begin_threaded_load() -> void:
	if _has_started_request or target_scene_path == "":
		return
	_has_started_request = true
	var err := ResourceLoader.load_threaded_request(target_scene_path)
	if err != OK:
		lbl_status.text = "ERROR LOADING PATH // RETRYING"
		get_tree().change_scene_to_file(target_scene_path)

func _load_textures() -> void:
	for p in RUN_FRAMES:
		if ResourceLoader.exists(p):
			run_textures.append(load(p))

func _build_ui() -> void:
	var root_node = Engine.get_main_loop().root if Engine.get_main_loop() else null
	var font_mgr = root_node.get_node_or_null("FontManager") if root_node else null

	# Background Gelap
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = COL_BG_DEEP
	add_child(bg)

	# Vignette Radial
	var vignette := TextureRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(0.08, 0.10, 0.16, 0.15), Color(0.00, 0.00, 0.00, 0.95)])
	var grad_tex := GradientTexture2D.new()
	grad_tex.gradient = grad
	grad_tex.fill = GradientTexture2D.FILL_RADIAL
	grad_tex.fill_from = Vector2(0.5, 0.5)
	grad_tex.fill_to = Vector2(1.0, 1.0)
	vignette.texture = grad_tex
	add_child(vignette)

	# Center Wrapper
	var screen_center := CenterContainer.new()
	screen_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(screen_center)

	var main_vbox := VBoxContainer.new()
	main_vbox.custom_minimum_size = Vector2(340, 140)
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_theme_constant_override("separation", 10)
	screen_center.add_child(main_vbox)

	# Sprite Karakter Rian
	var sprite_wrapper := CenterContainer.new()
	sprite_wrapper.custom_minimum_size = Vector2(340, 64)
	main_vbox.add_child(sprite_wrapper)

	sprite_rian = TextureRect.new()
	sprite_rian.custom_minimum_size = Vector2(48, 60)
	sprite_rian.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite_rian.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if not run_textures.is_empty():
		sprite_rian.texture = run_textures[0]
	sprite_wrapper.add_child(sprite_rian)

	# Frame Luar Bar
	var bar_outer_frame := PanelContainer.new()
	bar_outer_frame.custom_minimum_size = Vector2(324, 12)
	bar_outer_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var outer_style := StyleBoxFlat.new()
	outer_style.bg_color = Color(0.03, 0.04, 0.06, 0.8)
	outer_style.set_border_width_all(1)
	outer_style.border_color = COL_BORDER_OUTER
	outer_style.content_margin_left = 2
	outer_style.content_margin_right = 2
	outer_style.content_margin_top = 2
	outer_style.content_margin_bottom = 2
	bar_outer_frame.add_theme_stylebox_override("panel", outer_style)
	main_vbox.add_child(bar_outer_frame)

	# Progress Bar
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(318, 8)
	progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_bar.show_percentage = false
	progress_bar.min_value = 0.0
	progress_bar.max_value = 100.0
	progress_bar.value = 0.0

	var bg_st := StyleBoxFlat.new()
	bg_st.bg_color = COL_BAR_BG
	bg_st.set_border_width_all(1)
	bg_st.border_color = COL_BORDER_GOLD

	var fill_st := StyleBoxFlat.new()
	fill_st.bg_color = COL_BAR_FILL

	progress_bar.add_theme_stylebox_override("background", bg_st)
	progress_bar.add_theme_stylebox_override("fill", fill_st)
	bar_outer_frame.add_child(progress_bar)

	# Teks Info Bawah
	var info_hbox := HBoxContainer.new()
	info_hbox.custom_minimum_size = Vector2(320, 16)
	info_hbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	main_vbox.add_child(info_hbox)

	lbl_status = Label.new()
	lbl_status.text = "ESTABLISHING LIVE STREAM..."
	lbl_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if font_mgr and font_mgr.has_method("apply"):
		font_mgr.apply(lbl_status, 2, 9, COL_TEXT_MUTED)
	else:
		lbl_status.add_theme_font_size_override("font_size", 9)
		lbl_status.add_theme_color_override("font_color", COL_TEXT_MUTED)
	info_hbox.add_child(lbl_status)

	lbl_percentage = Label.new()
	lbl_percentage.text = "0%"
	if font_mgr and font_mgr.has_method("apply"):
		font_mgr.apply(lbl_percentage, 3, 11, COL_TEXT_GOLD)
	else:
		lbl_percentage.add_theme_font_size_override("font_size", 11)
		lbl_percentage.add_theme_color_override("font_color", COL_TEXT_GOLD)
	info_hbox.add_child(lbl_percentage)

func _process(delta: float) -> void:
	_animate_rian(delta)
	_update_loading_progress(delta)

func _animate_rian(delta: float) -> void:
	if run_textures.is_empty() or not sprite_rian:
		return

	frame_timer += delta
	if frame_timer >= FRAME_DURATION:
		frame_timer -= FRAME_DURATION
		current_frame_idx = (current_frame_idx + 1) % run_textures.size()
		sprite_rian.texture = run_textures[current_frame_idx]

func _update_loading_progress(delta: float) -> void:
	if is_loading_complete:
		return

	# Jika scene path kosong, batalkan hanging loading
	if target_scene_path == "":
		return

	var progress_array: Array = []
	var status := ResourceLoader.load_threaded_get_status(target_scene_path, progress_array)

	if not progress_array.is_empty():
		target_progress = progress_array[0] * 100.0

	# JIKA SUDAH SELESAI DI LOAD OLEH RESOURCE LOADER, LANGSUNG ARAHKAN PROGRESS KE 100
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		target_progress = 100.0

	# Interpolasi nilai progress bar agar ada transisi halus
	displayed_progress = move_toward(displayed_progress, target_progress, delta * 140.0)
	progress_bar.value = displayed_progress
	lbl_percentage.text = "%d%%" % int(displayed_progress)

	if (status == ResourceLoader.THREAD_LOAD_LOADED or target_progress >= 100.0) and displayed_progress >= 99.0:
		is_loading_complete = true
		progress_bar.value = 100.0
		lbl_percentage.text = "100%"
		lbl_status.text = "BROADCAST ONLINE // READY"

		var overlay := ColorRect.new()
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay.color = Color(0, 0, 0, 0)
		overlay.z_index = 100
		add_child(overlay)

		var tw := create_tween()
		tw.tween_interval(0.1)
		tw.tween_property(overlay, "color:a", 1.0, 0.2).set_trans(Tween.TRANS_SINE)
		tw.tween_callback(_switch_scene)
	elif status == ResourceLoader.THREAD_LOAD_FAILED:
		lbl_status.text = "SIGNAL LOST // RETRYING"
		is_loading_complete = true
		get_tree().change_scene_to_file(target_scene_path)

func _switch_scene() -> void:
	var loaded_res = ResourceLoader.load_threaded_get(target_scene_path)
	if loaded_res is PackedScene:
		get_tree().change_scene_to_packed(loaded_res)
	else:
		get_tree().change_scene_to_file(target_scene_path)
