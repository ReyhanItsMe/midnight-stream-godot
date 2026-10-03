## Skrip pengendali Menu Utama (Main Menu).
##
## Menggunakan ScenePaths untuk navigasi transisi, AssetPaths untuk grafis visual,
## serta Palette untuk harmonisasi warna tema.
class_name MainMenu
extends Control

# --- UI LABELS & TEXTS ---
const TEXT_SUBTITLE: String = "LIVEVIBE PRESENTS // SANATORIUM DAHLIA"
const TEXT_TITLE_FALLBACK: String = "MIDNIGHT STREAM"
const TEXT_BTN_PLAY: String = "PLAY STREAM"
const TEXT_BTN_LOAD: String = "LOAD LOG"
const TEXT_BTN_SETTINGS: String = "SETTINGS"
const TEXT_BTN_EXIT: String = "EXIT"
const TEXT_FOOTER_CREDIT: String = "DEV BUILD v0.1 // CREATED BY RAIHAN AZHAR"

# --- DIMENSIONS & TIMINGS ---
const TITLE_SPACER_HEIGHT: float = 8.0
const FADE_DURATION: float = 0.35

var menu_button_scene: PackedScene

func _ready() -> void:
	# 1. Nyalakan BGM Menu (tidak restart jika sudah bermain)
	AudioManager.play_menu_bgm()
	_load_scene_resources()

	# 2. Background Menu (640x360)
	var bg := TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	var bg_path: String = AssetPaths.UI.BG_MENU
	if ResourceLoader.exists(bg_path):
		bg.texture = load(bg_path)
	add_child(bg)

	# 3. Center Container
	var center_cont := CenterContainer.new()
	center_cont.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center_cont)

	var main_vbox := VBoxContainer.new()
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_theme_constant_override("separation", 6)
	center_cont.add_child(main_vbox)

	# Subtitle Merah
	var subtitle := Label.new()
	subtitle.text = TEXT_SUBTITLE
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontManager.apply(subtitle, FontManager.Type.RETRO_ALT, 10, Palette.RED_ACCENT)
	main_vbox.add_child(subtitle)

	# Title Graphic / Fallback Teks
	var title_img_path: String = AssetPaths.UI.TITLE_LOGO
	if ResourceLoader.exists(title_img_path):
		var title_tex := TextureRect.new()
		title_tex.texture = load(title_img_path)
		title_tex.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		main_vbox.add_child(title_tex)
	else:
		var title_lbl := Label.new()
		title_lbl.text = TEXT_TITLE_FALLBACK
		title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		FontManager.apply(title_lbl, FontManager.Type.TITLE, 28, Palette.WHITE)
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

	# 5. Footer Credit Terminal
	var footer := Label.new()
	footer.text = TEXT_FOOTER_CREDIT
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	footer.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	footer.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	footer.grow_vertical = Control.GROW_DIRECTION_BEGIN
	footer.offset_right = -14
	footer.offset_bottom = -8
	FontManager.apply(footer, FontManager.Type.DIGITAL, 9, Palette.TEXT_MUTED)
	add_child(footer)

func _load_scene_resources() -> void:
	var btn_path: String = ScenePaths.UIComponents.MENU_BUTTON
	if ResourceLoader.exists(btn_path):
		menu_button_scene = load(btn_path)
	else:
		push_error("[MainMenu] Menu button scene tidak ditemukan di: " + btn_path)

func build_button(label_text: String, action: Callable, btn_variant: GameMenuButton.Variant = GameMenuButton.Variant.DEFAULT) -> GameMenuButton:
	var btn: GameMenuButton = menu_button_scene.instantiate()
	btn.text = label_text
	btn.set_variant(btn_variant)
	btn.pressed.connect(action)
	FontManager.apply(btn, FontManager.Type.BODY_BOLD, 10, Palette.WHITE)
	return btn


# ==============================================================================
# EVENT HANDLERS (TRANSISI & AUDIO)
# ==============================================================================

func _on_play_pressed() -> void:
	AudioManager.stop_bgm(0.4)
	# Menggunakan layar loading beranimasi Rian lari + progress bar via ScenePaths
	TransitionManager.change_scene_with_loading(ScenePaths.Maps.PROLOGUE, FADE_DURATION)

func _on_load_pressed() -> void:
	TransitionManager.change_scene(ScenePaths.Screens.LOAD_GAME, FADE_DURATION)

func _on_settings_pressed() -> void:
	TransitionManager.change_scene(ScenePaths.Screens.SETTINGS, FADE_DURATION)

func _on_exit_pressed() -> void:
	AudioManager.stop_bgm(0.25)
	await get_tree().create_timer(0.25).timeout
	get_tree().quit()
