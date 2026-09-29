extends Control
class_name InfoModal

signal confirmed
signal closed

const MENU_BUTTON_SCENE: PackedScene = preload("res://scenes/ui/components/MenuButton.tscn")

const COLOR_GOLD: Color = Color(0.95, 0.82, 0.25)
const COLOR_WHITE: Color = Color(0.92, 0.94, 0.96)
const COLOR_MODAL_BG: Color = Color(0.05, 0.06, 0.09, 0.98)
const COLOR_MODAL_HEADER_BG: Color = Color(0.1, 0.12, 0.17, 1.0)
const COLOR_RED_CLOSE: Color = Color(0.85, 0.22, 0.22)
const COLOR_WARNING_RED: Color = Color(0.95, 0.25, 0.25)

const BOX_WIDTH: float = 260.0
const BOX_HEIGHT: float = 118.0

var modal_tween: Tween
var pending_confirm_action: Callable

var modal_box: PanelContainer
var header_panel: PanelContainer
var lbl_modal_title: Label
var lbl_modal_body: Label
var btn_action: GameMenuButton
var btn_close_x: GameMenuButton

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	modulate.a = 0.0
	_build_ui()


func _build_ui() -> void:
	# 1. Dimmer Gelap Layar
	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.0, 0.0, 0.0, 0.72)
	add_child(dimmer)

	# 2. CenterContainer MURNI HANYA UNTUK KOTAK MODAL (Pasti Center di Layar)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	modal_box = PanelContainer.new()
	modal_box.custom_minimum_size = Vector2(BOX_WIDTH, BOX_HEIGHT)
	var box_style := StyleBoxFlat.new()
	box_style.bg_color = COLOR_MODAL_BG
	box_style.set_border_width_all(1)
	box_style.border_color = COLOR_GOLD
	modal_box.add_theme_stylebox_override("panel", box_style)
	center.add_child(modal_box)

	var box_vbox := VBoxContainer.new()
	box_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	box_vbox.add_theme_constant_override("separation", 8)
	modal_box.add_child(box_vbox)

	# Header Bar
	header_panel = PanelContainer.new()
	header_panel.custom_minimum_size = Vector2(0, 22)
	var header_style := StyleBoxFlat.new()
	header_style.bg_color = COLOR_MODAL_HEADER_BG
	header_style.content_margin_top = 4
	header_style.content_margin_bottom = 4
	header_panel.add_theme_stylebox_override("panel", header_style)
	box_vbox.add_child(header_panel)

	lbl_modal_title = Label.new()
	lbl_modal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontManager.apply(lbl_modal_title, FontManager.Type.TITLE, 11, COLOR_GOLD)
	header_panel.add_child(lbl_modal_title)

	# Body Teks
	lbl_modal_body = Label.new()
	lbl_modal_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_modal_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_modal_body.custom_minimum_size = Vector2(230, 36)
	FontManager.apply(lbl_modal_body, FontManager.Type.BODY, 9, COLOR_WHITE)
	box_vbox.add_child(lbl_modal_body)

	# HANYA 1 TOMBOL AKSI UTAMA DI DALAM BOX
	btn_action = MENU_BUTTON_SCENE.instantiate()
	btn_action.text = "OK"
	btn_action.set_dimensions(100, 20)
	btn_action.set_variant(GameMenuButton.Variant.ACCENT)
	btn_action.pressed.connect(_on_action_pressed)
	box_vbox.add_child(btn_action)

	# 3. TOMBOL [X] MELAYANG DI BAWAH KOTAK MODAL (TIDAK MENGGESER POSISI CENTER)
	btn_close_x = MENU_BUTTON_SCENE.instantiate()
	btn_close_x.text = "X"
	btn_close_x.set_dimensions(24, 24)
	btn_close_x.set_variant(GameMenuButton.Variant.DANGER)
	_style_round_close_button(btn_close_x)

	# Set titik jangkar tepat di tengah bawah kotak
	btn_close_x.anchor_left = 0.5
	btn_close_x.anchor_right = 0.5
	btn_close_x.anchor_top = 0.5
	btn_close_x.anchor_bottom = 0.5
	btn_close_x.offset_left = -12.0
	btn_close_x.offset_right = 12.0
	btn_close_x.offset_top = (BOX_HEIGHT / 2.0) + 10.0
	btn_close_x.offset_bottom = (BOX_HEIGHT / 2.0) + 34.0
	btn_close_x.pressed.connect(close)
	add_child(btn_close_x)


# ==============================================================================
# METODE PEMANGGILAN
# ==============================================================================

## Popup informasi / peringatan biasa (1 Tombol "OK")
func popup(title_text: String, message_text: String) -> void:
	pending_confirm_action = Callable()
	_apply_box_border_color(COLOR_GOLD)
	FontManager.apply(lbl_modal_title, FontManager.Type.TITLE, 11, COLOR_GOLD)
	btn_action.text = "OK"
	btn_action.set_dimensions(84, 20)
	btn_action.set_variant(GameMenuButton.Variant.ACCENT)
	_open_dialog(title_text, message_text)


## Popup konfirmasi (1 Tombol aksi kustom + tombol X di bawah sebagai batal)
func popup_confirm(title_text: String, message_text: String, action_btn_text: String, is_danger: bool, on_confirm_callback: Callable) -> void:
	pending_confirm_action = on_confirm_callback
	var theme_color := COLOR_WARNING_RED if is_danger else COLOR_GOLD
	_apply_box_border_color(theme_color)
	FontManager.apply(lbl_modal_title, FontManager.Type.TITLE, 11, theme_color)

	btn_action.text = action_btn_text
	btn_action.set_dimensions(110, 20)
	btn_action.set_variant(GameMenuButton.Variant.DANGER if is_danger else GameMenuButton.Variant.ACCENT)

	_open_dialog(title_text, message_text)


func _open_dialog(title_text: String, message_text: String) -> void:
	lbl_modal_title.text = title_text
	lbl_modal_body.text = message_text
	visible = true

	modal_box.scale = Vector2(0.92, 0.92)
	modal_box.pivot_offset = modal_box.custom_minimum_size / 2.0

	if modal_tween and modal_tween.is_valid():
		modal_tween.kill()

	modal_tween = create_tween().set_parallel(true)
	modal_tween.tween_property(self, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_SINE)
	modal_tween.tween_property(modal_box, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func close() -> void:
	if modal_tween and modal_tween.is_valid():
		modal_tween.kill()

	modal_tween = create_tween()
	modal_tween.tween_property(self, "modulate:a", 0.0, 0.12).set_trans(Tween.TRANS_SINE)
	modal_tween.tween_callback(func():
		visible = false
		closed.emit()
	)


func _on_action_pressed() -> void:
	if pending_confirm_action.is_valid():
		pending_confirm_action.call()
		confirmed.emit()
	close()


func _apply_box_border_color(color: Color) -> void:
	var style: StyleBoxFlat = modal_box.get_theme_stylebox("panel").duplicate()
	style.border_color = color
	modal_box.add_theme_stylebox_override("panel", style)


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
