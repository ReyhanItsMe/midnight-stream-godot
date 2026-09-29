extends Control
class_name InfoModal

signal confirmed
signal closed

const FONT_PATH: String = "res://assets/fonts/Pix32.ttf"
const MENU_BUTTON_SCENE: PackedScene = preload("res://scenes/ui/components/MenuButton.tscn")

const COLOR_GOLD: Color = Color(0.95, 0.82, 0.25)
const COLOR_WHITE: Color = Color(0.92, 0.94, 0.96)
const COLOR_MODAL_BG: Color = Color(0.05, 0.06, 0.09, 0.98)
const COLOR_MODAL_HEADER_BG: Color = Color(0.1, 0.12, 0.17, 1.0)
const COLOR_RED_CLOSE: Color = Color(0.85, 0.22, 0.22)

var custom_font: FontFile
var modal_tween: Tween

var modal_container: VBoxContainer
var lbl_modal_title: Label
var lbl_modal_body: Label

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	modulate.a = 0.0

	if ResourceLoader.exists(FONT_PATH):
		custom_font = load(FONT_PATH)

	_build_ui()


func _build_ui() -> void:
	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.0, 0.0, 0.0, 0.65)
	add_child(dimmer)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	modal_container = VBoxContainer.new()
	modal_container.alignment = BoxContainer.ALIGNMENT_CENTER
	modal_container.add_theme_constant_override("separation", 8)
	center.add_child(modal_container)

	var modal_box := PanelContainer.new()
	modal_box.custom_minimum_size = Vector2(260, 115)
	var box_style := StyleBoxFlat.new()
	box_style.bg_color = COLOR_MODAL_BG
	box_style.set_border_width_all(1)
	box_style.border_color = COLOR_GOLD
	modal_box.add_theme_stylebox_override("panel", box_style)
	modal_container.add_child(modal_box)

	var box_vbox := VBoxContainer.new()
	box_vbox.add_theme_constant_override("separation", 10)
	modal_box.add_child(box_vbox)

	var header_panel := PanelContainer.new()
	header_panel.custom_minimum_size = Vector2(0, 22)
	var header_style := StyleBoxFlat.new()
	header_style.bg_color = COLOR_MODAL_HEADER_BG
	header_style.content_margin_top = 4
	header_style.content_margin_bottom = 4
	header_panel.add_theme_stylebox_override("panel", header_style)
	box_vbox.add_child(header_panel)

	lbl_modal_title = Label.new()
	lbl_modal_title.text = "EMPTY LOG"
	lbl_modal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	apply_font(lbl_modal_title, 10, COLOR_GOLD)
	header_panel.add_child(lbl_modal_title)

	lbl_modal_body = Label.new()
	lbl_modal_body.text = ""
	lbl_modal_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_modal_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_modal_body.custom_minimum_size = Vector2(230, 34)
	apply_font(lbl_modal_body, 9, COLOR_WHITE)
	box_vbox.add_child(lbl_modal_body)

	var btn_ok: GameMenuButton = MENU_BUTTON_SCENE.instantiate()
	btn_ok.text = "OK"
	btn_ok.set_dimensions(84, 20)
	btn_ok.set_variant(GameMenuButton.Variant.ACCENT)
	btn_ok.pressed.connect(func():
		confirmed.emit()
		close()
	)
	box_vbox.add_child(btn_ok)

	var pad_bottom := Control.new()
	pad_bottom.custom_minimum_size = Vector2(0, 2)
	box_vbox.add_child(pad_bottom)

	var btn_close_x: GameMenuButton = MENU_BUTTON_SCENE.instantiate()
	btn_close_x.text = "X"
	btn_close_x.set_dimensions(24, 24)
	btn_close_x.set_variant(GameMenuButton.Variant.DANGER)
	_style_round_close_button(btn_close_x)
	btn_close_x.pressed.connect(close)
	modal_container.add_child(btn_close_x)


func popup(title_text: String, message_text: String) -> void:
	lbl_modal_title.text = title_text
	lbl_modal_body.text = message_text
	visible = true
	modal_container.scale = Vector2(0.92, 0.92)
	modal_container.pivot_offset = modal_container.size / 2.0

	if modal_tween and modal_tween.is_valid():
		modal_tween.kill()

	modal_tween = create_tween().set_parallel(true)
	modal_tween.tween_property(self, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_SINE)
	modal_tween.tween_property(modal_container, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func close() -> void:
	if modal_tween and modal_tween.is_valid():
		modal_tween.kill()

	modal_tween = create_tween()
	modal_tween.tween_property(self, "modulate:a", 0.0, 0.14).set_trans(Tween.TRANS_SINE)
	modal_tween.tween_callback(func():
		visible = false
		closed.emit()
	)


func _style_round_close_button(btn: GameMenuButton) -> void:
	var round_normal := StyleBoxFlat.new()
	round_normal.bg_color = Color(0.1, 0.05, 0.07, 0.9)
	round_normal.set_border_width_all(1)
	round_normal.border_color = COLOR_RED_CLOSE
	round_normal.set_corner_radius_all(12)

	var round_hover := round_normal.duplicate()
	round_hover.bg_color = Color(0.25, 0.06, 0.08, 0.98)
	round_hover.border_color = Color(1.0, 0.35, 0.35)

	btn.add_theme_color_override("font_color", COLOR_RED_CLOSE)
	btn.add_theme_stylebox_override("normal", round_normal)
	btn.add_theme_stylebox_override("hover", round_hover)
	btn.add_theme_stylebox_override("pressed", round_hover)
	btn.add_theme_stylebox_override("focus", round_normal)


func apply_font(lbl: Label, font_size: int, color: Color) -> void:
	if custom_font:
		lbl.add_theme_font_override("font", custom_font)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
