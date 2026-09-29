extends Control

# --- RESOURCE PATHS ---
const BG_PATH: String = "res://assets/ui/backgrounds/setting/background-setting.png"
const BACK_SCENE_PATH: String = "res://scenes/ui/screens/main_menu/MainMenu.tscn"
const MENU_BUTTON_SCENE: PackedScene = preload("res://scenes/ui/components/MenuButton.tscn")

# --- UI TEXTS & LABELS ---
const TEXT_HEADER: String = "STREAM & AUDIO SETTINGS"
const TEXT_BGM: String = "BGM VOLUME"
const TEXT_SFX: String = "SFX VOLUME"
const TEXT_SHAKE: String = "SCREEN SHAKE"
const TEXT_BACK: String = "< BACK TO STUDIO"

# --- THEME COLORS ---
const COLOR_HEADER: Color = Color(0.95, 0.82, 0.25)
const COLOR_LABEL: Color = Color(0.9, 0.92, 0.95)
const COLOR_VALUE: Color = Color(0.95, 0.82, 0.25)

# --- TIMINGS & TRANSITIONS ---
const FADE_DURATION: float = 0.35

# Nilai Setting Sementara
var bgm_percent: int = 50
var sfx_percent: int = 100
var screen_shake: bool = true

# Label Displays
var lbl_bgm_val: Label
var lbl_sfx_val: Label
var lbl_shake_val: Label

func _ready() -> void:
	# Pastikan BGM Menu tetap menyala
	AudioManager.play_menu_bgm()

	# Ambil data dari SaveManager
	if SaveManager and SaveManager.current_data.has("settings"):
		var conf: Dictionary = SaveManager.current_data["settings"]
		var raw_bgm = conf.get("bgm_volume", 0.5)
		var raw_sfx = conf.get("sfx_volume", 1.0)
		bgm_percent = int(float(raw_bgm) * 100 if float(raw_bgm) <= 1.0 else float(raw_bgm))
		sfx_percent = int(float(raw_sfx) * 100 if float(raw_sfx) <= 1.0 else float(raw_sfx))
		screen_shake = conf.get("screen_shake_enabled", true)

	# 1. Background Setting
	var bg := TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	if ResourceLoader.exists(BG_PATH):
		bg.texture = load(BG_PATH)
	add_child(bg)

	# 2. Center Container
	var center_cont := CenterContainer.new()
	center_cont.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center_cont)

	var main_vbox := VBoxContainer.new()
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_theme_constant_override("separation", 12)
	center_cont.add_child(main_vbox)

	# Header Judul
	var title := Label.new()
	title.text = TEXT_HEADER
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontManager.apply(title, FontManager.Type.TITLE, 14, COLOR_HEADER)
	main_vbox.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 4)
	main_vbox.add_child(spacer)

	# 3. Baris Pengaturan
	var rows_vbox := VBoxContainer.new()
	rows_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	rows_vbox.add_theme_constant_override("separation", 8)
	main_vbox.add_child(rows_vbox)

	lbl_bgm_val = create_stepper_row(rows_vbox, TEXT_BGM, str(bgm_percent) + "%", 
		func(): change_volume("bgm", -10),
		func(): change_volume("bgm", 10)
	)

	lbl_sfx_val = create_stepper_row(rows_vbox, TEXT_SFX, str(sfx_percent) + "%", 
		func(): change_volume("sfx", -10),
		func(): change_volume("sfx", 10)
	)

	lbl_shake_val = create_stepper_row(rows_vbox, TEXT_SHAKE, "ON" if screen_shake else "OFF",
		func(): toggle_shake(),
		func(): toggle_shake()
	)

	var spacer_back := Control.new()
	spacer_back.custom_minimum_size = Vector2(0, 8)
	main_vbox.add_child(spacer_back)

	# 4. Tombol < BACK TO STUDIO
	var btn_back: GameMenuButton = MENU_BUTTON_SCENE.instantiate()
	btn_back.text = TEXT_BACK
	btn_back.set_dimensions(196, 24)
	btn_back.pressed.connect(_on_back_pressed)
	main_vbox.add_child(btn_back)


func create_stepper_row(parent: VBoxContainer, label_title: String, initial_val: String, on_minus: Callable, on_plus: Callable) -> Label:
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 8)
	parent.add_child(hbox)

	# Label Kiri (Nama Setting)
	var lbl := Label.new()
	lbl.text = label_title
	lbl.custom_minimum_size = Vector2(110, 0)
	FontManager.apply(lbl, FontManager.Type.BODY, 10, COLOR_LABEL)
	hbox.add_child(lbl)

	# Tombol [-]
	var btn_minus: GameMenuButton = MENU_BUTTON_SCENE.instantiate()
	btn_minus.text = "-"
	btn_minus.set_dimensions(24, 20)
	btn_minus.set_variant(GameMenuButton.Variant.ACCENT)
	btn_minus.pressed.connect(on_minus)
	hbox.add_child(btn_minus)

	# Nilai Tengah Counter
	var lbl_val := Label.new()
	lbl_val.text = initial_val
	lbl_val.custom_minimum_size = Vector2(46, 0)
	lbl_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontManager.apply(lbl_val, FontManager.Type.DIGITAL, 11, COLOR_VALUE)
	hbox.add_child(lbl_val)

	# Tombol [+]
	var btn_plus: GameMenuButton = MENU_BUTTON_SCENE.instantiate()
	btn_plus.text = "+"
	btn_plus.set_dimensions(24, 20)
	btn_plus.set_variant(GameMenuButton.Variant.ACCENT)
	btn_plus.pressed.connect(on_plus)
	hbox.add_child(btn_plus)

	return lbl_val


func change_volume(bus_type: String, delta_val: int) -> void:
	if bus_type == "bgm":
		bgm_percent = clampi(bgm_percent + delta_val, 0, 100)
		lbl_bgm_val.text = str(bgm_percent) + "%"
		if SaveManager and SaveManager.current_data.has("settings"):
			SaveManager.current_data["settings"]["bgm_volume"] = float(bgm_percent) / 100.0
			SaveManager.apply_audio_settings()
	elif bus_type == "sfx":
		sfx_percent = clampi(sfx_percent + delta_val, 0, 100)
		lbl_sfx_val.text = str(sfx_percent) + "%"
		if SaveManager and SaveManager.current_data.has("settings"):
			SaveManager.current_data["settings"]["sfx_volume"] = float(sfx_percent) / 100.0
			SaveManager.apply_audio_settings()


func toggle_shake() -> void:
	screen_shake = !screen_shake
	lbl_shake_val.text = "ON" if screen_shake else "OFF"
	if SaveManager and SaveManager.current_data.has("settings"):
		SaveManager.current_data["settings"]["screen_shake_enabled"] = screen_shake


func _on_back_pressed() -> void:
	# Pastikan setting tersimpan permanen ke file disk sebelum pindah scene
	if SaveManager:
		SaveManager.save_settings()

	TransitionManager.change_scene(BACK_SCENE_PATH, FADE_DURATION)
