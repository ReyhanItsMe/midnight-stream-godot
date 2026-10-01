class_name PauseViewMain
extends VBoxContainer

signal resume_requested
signal load_requested
signal settings_requested
signal exit_requested

const COL_HEADER_BG: Color = Color(0.09, 0.10, 0.16, 1.0)
const COL_GOLD: Color = Color(0.95, 0.82, 0.25, 1.0)

func _init() -> void:
	custom_minimum_size = Vector2(250, 0)
	add_theme_constant_override("separation", 0)

	_build_header("STREAM PAUSED // INTERMISSION")

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	margin.add_child(body)
	add_child(margin)

	var btn_resume := _build_btn("RESUME STREAM", GameMenuButton.Variant.DEFAULT)
	btn_resume.pressed.connect(func(): resume_requested.emit())
	body.add_child(btn_resume)

	var btn_load := _build_btn("LOAD LOG", GameMenuButton.Variant.DEFAULT)
	btn_load.pressed.connect(func(): load_requested.emit())
	body.add_child(btn_load)

	var btn_settings := _build_btn("SETTINGS", GameMenuButton.Variant.DEFAULT)
	btn_settings.pressed.connect(func(): settings_requested.emit())
	body.add_child(btn_settings)

	var btn_exit := _build_btn("BACK TO MENU", GameMenuButton.Variant.DANGER)
	btn_exit.pressed.connect(func(): exit_requested.emit())
	body.add_child(btn_exit)

func _build_btn(txt: String, variant: GameMenuButton.Variant) -> GameMenuButton:
	var btn := GameMenuButton.new()
	btn.text = txt
	btn.set_dimensions(196, 24)
	btn.font_size_override = 9
	btn.set_variant(variant)
	return btn

func _build_header(title_str: String) -> void:
	var header_box := PanelContainer.new()
	header_box.custom_minimum_size = Vector2(0, 26)
	var style := StyleBoxFlat.new()
	style.bg_color = COL_HEADER_BG
	style.border_width_bottom = 1
	style.border_color = Color(0.20, 0.22, 0.30, 1.0)
	header_box.add_theme_stylebox_override("panel", style)

	var lbl := Label.new()
	lbl.text = title_str
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_font(lbl, 10, COL_GOLD)
	header_box.add_child(lbl)
	add_child(header_box)

func _apply_font(lbl: Label, f_size: int, col: Color) -> void:
	var font_mgr: Node = Engine.get_main_loop().root.get_node_or_null("FontManager") if (Engine.get_main_loop() and Engine.get_main_loop().root) else null
	if font_mgr and font_mgr.has_method("apply"):
		font_mgr.apply(lbl, font_mgr.Type.BODY_BOLD, f_size, col)
	else:
		lbl.add_theme_font_size_override("font_size", f_size)
		lbl.add_theme_color_override("font_color", col)
