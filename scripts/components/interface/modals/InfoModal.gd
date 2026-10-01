class_name InfoModal
extends BaseModal

signal confirmed

const COLOR_WHITE: Color = Color(0.92, 0.94, 0.96)
const COLOR_MODAL_HEADER_BG: Color = Color(0.1, 0.12, 0.17, 1.0)
const COLOR_WARNING_RED: Color = Color(0.95, 0.25, 0.25)

var pending_confirm_action: Callable
var lbl_modal_title: Label
var lbl_modal_body: Label
var btn_action: GameMenuButton

func _build_content() -> void:
	# Header Bar
	var header_panel := PanelContainer.new()
	header_panel.custom_minimum_size = Vector2(0, 22)
	var header_style := StyleBoxFlat.new()
	header_style.bg_color = COLOR_MODAL_HEADER_BG
	header_style.content_margin_top = 4
	header_style.content_margin_bottom = 4
	header_panel.add_theme_stylebox_override("panel", header_style)
	content_container.add_child(header_panel)

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
	content_container.add_child(lbl_modal_body)

	# Tombol Aksi Utama
	btn_action = MENU_BUTTON_SCENE.instantiate()
	btn_action.text = "OK"
	btn_action.set_dimensions(100, 20)
	btn_action.set_variant(GameMenuButton.Variant.ACCENT)
	btn_action.pressed.connect(_on_action_pressed)
	content_container.add_child(btn_action)

func popup(title_text: String, message_text: String) -> void:
	pending_confirm_action = Callable()
	set_border_color(COLOR_GOLD)
	FontManager.apply(lbl_modal_title, FontManager.Type.TITLE, 11, COLOR_GOLD)
	btn_action.text = "OK"
	btn_action.set_dimensions(84, 20)
	btn_action.set_variant(GameMenuButton.Variant.ACCENT)
	_show(title_text, message_text)

func popup_confirm(title_text: String, message_text: String, action_btn_text: String, is_danger: bool, on_confirm_callback: Callable) -> void:
	pending_confirm_action = on_confirm_callback
	var theme_color := COLOR_WARNING_RED if is_danger else COLOR_GOLD
	set_border_color(theme_color)
	FontManager.apply(lbl_modal_title, FontManager.Type.TITLE, 11, theme_color)

	btn_action.text = action_btn_text
	btn_action.set_dimensions(110, 20)
	btn_action.set_variant(GameMenuButton.Variant.DANGER if is_danger else GameMenuButton.Variant.ACCENT)
	_show(title_text, message_text)

func _show(title_text: String, message_text: String) -> void:
	lbl_modal_title.text = title_text
	lbl_modal_body.text = message_text
	open_modal()

func _on_action_pressed() -> void:
	if pending_confirm_action.is_valid():
		pending_confirm_action.call()
		confirmed.emit()
	close()
