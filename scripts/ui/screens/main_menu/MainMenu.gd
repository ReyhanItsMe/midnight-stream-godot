extends Control

# --- RESOURCE PATHS ---
const BG_PATH: String = "res://assets/ui/backgrounds/menu/background-menu.png"
const TITLE_IMG_PATH: String = "res://assets/ui/titles/title-games.png"
const MENU_BUTTON_SCENE: PackedScene = preload("res://scenes/ui/components/MenuButton.tscn")

# --- NAVIGATION TARGET PATHS ---
const GAME_SCENE_PATH: String = "res://scenes/gameplay/prologue/Prologue.tscn"
const SETTINGS_SCENE_PATH: String = "res://scenes/ui/screens/settings/Settings.tscn"
const LOAD_SCENE_PATH: String = "res://scenes/ui/screens/load_game/LoadGame.tscn"

# --- UI LABELS & TEXTS ---
const TEXT_SUBTITLE: String = "LIVEVIBE PRESENTS // SANATORIUM DAHLIA"
const TEXT_TITLE_FALLBACK: String = "MIDNIGHT STREAM"
const TEXT_BTN_PLAY: String = "PLAY STREAM"
const TEXT_BTN_LOAD: String = "LOAD LOG"
const TEXT_BTN_SETTINGS: String = "SETTINGS"
const TEXT_BTN_EXIT: String = "EXIT"
const TEXT_FOOTER_CREDIT: String = "DEV BUILD v0.1 // CREATED BY RAIHAN AZHAR"

# --- THEME COLORS ---
const COLOR_SUBTITLE: Color = Color(0.85, 0.25, 0.2)
const COLOR_TITLE_FALLBACK: Color = Color.WHITE
const COLOR_FOOTER: Color = Color(0.65, 0.7, 0.75, 0.8)

# --- DIMENSIONS & TIMINGS ---
const TITLE_SPACER_HEIGHT: float = 8.0
const FADE_DURATION: float = 0.35

func _ready() -> void:
	# 1. Nyalakan BGM Menu (Tidak restart jika sudah berjalan)
	AudioManager.play_menu_bgm()

	# 2. Background Menu (640x360)
	var bg := TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	if ResourceLoader.exists(BG_PATH):
		bg.texture = load(BG_PATH)
	add_child(bg)

	# 3. Center Container
	var center_cont := CenterContainer.new()
	center_cont.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center_cont)

	var main_vbox := VBoxContainer.new()
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_theme_constant_override("separation", 6)
	center_cont.add_child(main_vbox)

	# Subtitle Merah (Geist-Pixel)
	var subtitle := Label.new()
	subtitle.text = TEXT_SUBTITLE
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontManager.apply(subtitle, FontManager.Type.RETRO_ALT, 10, COLOR_SUBTITLE)
	main_vbox.add_child(subtitle)

	# Title Graphic / Fallback Teks (Jersey 25 Arcade)
	if ResourceLoader.exists(TITLE_IMG_PATH):
		var title_tex := TextureRect.new()
		title_tex.texture = load(TITLE_IMG_PATH)
		title_tex.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		main_vbox.add_child(title_tex)
	else:
		var title_lbl := Label.new()
		title_lbl.text = TEXT_TITLE_FALLBACK
		title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		FontManager.apply(title_lbl, FontManager.Type.TITLE, 28, COLOR_TITLE_FALLBACK)
		main_vbox.add_child(title_lbl)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, TITLE_SPACER_HEIGHT)
	main_vbox.add_child(spacer)

	# 4. Mount Tombol Menu
	var btn_vbox := VBoxContainer.new()
	btn_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_vbox.add_theme_constant_override("separation", 5)
	main_vbox.add_child(btn_vbox)

	btn_vbox.add_child(build_button(TEXT_BTN_PLAY, _on_play_pressed))
	btn_vbox.add_child(build_button(TEXT_BTN_LOAD, _on_load_pressed))
	btn_vbox.add_child(build_button(TEXT_BTN_SETTINGS, _on_settings_pressed))
	btn_vbox.add_child(build_button(TEXT_BTN_EXIT, _on_exit_pressed, GameMenuButton.Variant.DANGER))

	# 5. Footer Credit Terminal (Handjet)
	var footer := Label.new()
	footer.text = TEXT_FOOTER_CREDIT
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	footer.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	footer.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	footer.grow_vertical = Control.GROW_DIRECTION_BEGIN
	footer.offset_right = -14
	footer.offset_bottom = -8
	FontManager.apply(footer, FontManager.Type.DIGITAL, 9, COLOR_FOOTER)
	add_child(footer)


func build_button(label_text: String, action: Callable, btn_variant: GameMenuButton.Variant = GameMenuButton.Variant.DEFAULT) -> GameMenuButton:
	var btn: GameMenuButton = MENU_BUTTON_SCENE.instantiate()
	btn.text = label_text
	btn.set_variant(btn_variant)
	btn.pressed.connect(action)
	FontManager.apply(btn, FontManager.Type.BODY_BOLD, 10, Color.WHITE)
	return btn


# ========================================
# EVENT HANDLERS (TRANSISI & AUDIO)
# ========================================

func _on_play_pressed() -> void:
	AudioManager.stop_bgm(0.5)
	TransitionManager.change_scene(GAME_SCENE_PATH, 0.5)

func _on_load_pressed() -> void:
	if ResourceLoader.exists(LOAD_SCENE_PATH):
		TransitionManager.change_scene(LOAD_SCENE_PATH, FADE_DURATION)
	else:
		print("[Menu] Scene LoadGame belum ditemukan.")

func _on_settings_pressed() -> void:
	TransitionManager.change_scene(SETTINGS_SCENE_PATH, FADE_DURATION)

func _on_exit_pressed() -> void:
	AudioManager.stop_bgm(0.25)
	await get_tree().create_timer(0.25).timeout
	get_tree().quit()
