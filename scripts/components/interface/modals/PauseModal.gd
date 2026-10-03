## Modal menu pause terpusat dengan sub-view navigasi (Main Pause, Load Log, dan Settings).
##
## Cara pakai:
##   var pause_ui = PauseModal.new()
##   add_child(pause_ui)
##   pause_ui.open_pause_menu() # Menjeda gameplay dan menampilkan menu pause
##   pause_ui.resume_game()     # Menutup pause dan melanjutkan gameplay
class_name PauseModal
extends Control

const VIEWPORT_RES: Vector2 = Vector2(640, 360)
const MAIN_MENU_PATH: String = "res://scenes/ui/screens/main_menu/MainMenu.tscn"

const COL_BG_DARK: Color = Color(0.05, 0.06, 0.09, 0.96)
const COL_BORDER_GOLD: Color = Color(0.65, 0.55, 0.22, 0.85)

var btn_pause_hud: GameMenuButton
var overlay_bg: ColorRect
var modal_wrapper: VBoxContainer
var card_panel: PanelContainer
var btn_floating_close: GameMenuButton

var view_main: PauseViewMain
var view_load: PauseViewLoad
var view_settings: PauseViewSettings

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	position = Vector2.ZERO
	size = VIEWPORT_RES
	custom_minimum_size = VIEWPORT_RES
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_build_hud_pause_button()
	_build_modal_structure()
	_show_view("none")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if overlay_bg.visible:
			resume_game()
		else:
			open_pause_menu()
		get_viewport().set_input_as_handled()

func _build_hud_pause_button() -> void:
	btn_pause_hud = GameMenuButton.new()
	btn_pause_hud.text = "|| PAUSE"
	btn_pause_hud.set_dimensions(68, 22)
	btn_pause_hud.font_size_override = 9
	btn_pause_hud.set_variant(GameMenuButton.Variant.DEFAULT)
	btn_pause_hud.set_anchors_preset(Control.PRESET_CENTER_TOP)
	btn_pause_hud.grow_horizontal = Control.GROW_DIRECTION_BOTH
	btn_pause_hud.offset_top = 10
	btn_pause_hud.pressed.connect(open_pause_menu)
	add_child(btn_pause_hud)

func _build_modal_structure() -> void:
	overlay_bg = ColorRect.new()
	overlay_bg.color = Color(0.01, 0.01, 0.02, 0.84)
	overlay_bg.custom_minimum_size = VIEWPORT_RES
	overlay_bg.visible = false
	add_child(overlay_bg)

	var center := CenterContainer.new()
	center.custom_minimum_size = VIEWPORT_RES
	overlay_bg.add_child(center)

	modal_wrapper = VBoxContainer.new()
	modal_wrapper.add_theme_constant_override("separation", 6)
	modal_wrapper.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(modal_wrapper)

	card_panel = PanelContainer.new()
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = COL_BG_DARK
	card_style.set_border_width_all(1)
	card_style.border_color = COL_BORDER_GOLD
	card_panel.add_theme_stylebox_override("panel", card_style)
	modal_wrapper.add_child(card_panel)

	var content_stack := MarginContainer.new()
	card_panel.add_child(content_stack)

	# 1. Pasang Sub-View Molecules
	view_main = PauseViewMain.new()
	view_main.resume_requested.connect(resume_game)
	view_main.load_requested.connect(func():
		view_load.refresh_slots()
		_show_view("load")
	)
	view_main.settings_requested.connect(func():
		view_settings.sync_and_refresh()
		_show_view("settings")
	)
	view_main.exit_requested.connect(_confirm_back_to_menu)
	content_stack.add_child(view_main)

	view_load = PauseViewLoad.new()
	view_load.back_requested.connect(func(): _show_view("main"))
	view_load.load_executed.connect(resume_game)
	content_stack.add_child(view_load)

	view_settings = PauseViewSettings.new()
	view_settings.back_requested.connect(func(): _show_view("main"))
	content_stack.add_child(view_settings)

	# 2. Tombol Floating Close [X]
	btn_floating_close = GameMenuButton.new()
	btn_floating_close.text = "X"
	btn_floating_close.set_dimensions(22, 20)
	btn_floating_close.font_size_override = 9
	btn_floating_close.set_variant(GameMenuButton.Variant.DANGER)
	btn_floating_close.pressed.connect(func():
		if view_main.visible:
			resume_game()
		else:
			_show_view("main")
	)
	modal_wrapper.add_child(btn_floating_close)

func open_pause_menu() -> void:
	get_tree().paused = true
	var player_cls = get_tree().current_scene.find_child("Player", true, false)
	if player_cls:
		player_cls.set("joystick_vector", Vector2.ZERO)
		player_cls.set("is_sprint_pressed", false)

	btn_pause_hud.visible = false
	overlay_bg.visible = true
	_show_view("main")

func resume_game() -> void:
	overlay_bg.visible = false
	btn_pause_hud.visible = true
	get_tree().paused = false

func _show_view(view_name: String) -> void:
	view_main.visible = (view_name == "main")
	view_load.visible = (view_name == "load")
	view_settings.visible = (view_name == "settings")

func _confirm_back_to_menu() -> void:
	get_tree().paused = false
	var fade_canvas := get_tree().root.get_node_or_null("FadeCanvas")
	if fade_canvas:
		fade_canvas.queue_free()

	var trans_mgr: Node = get_node_or_null("/root/TransitionManager")
	if trans_mgr and trans_mgr.has_method("change_scene"):
		trans_mgr.change_scene(MAIN_MENU_PATH)
	else:
		get_tree().change_scene_to_file(MAIN_MENU_PATH)
