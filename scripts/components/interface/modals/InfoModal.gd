## Modal serbaguna untuk pesan informasi tunggal atau konfirmasi aksi (Yes/No - OK/Batal).
##
## Cara pakai (Pesan Info Biasa):
##   info_modal.popup("INFO ARSIP", "Pintu gerbang timur berhasil dibuka.")
##
## Cara pakai (Konfirmasi Bahaya / Timpa Data):
##   info_modal.popup_confirm("HAPUS DATA", "Yakin ingin menghapus slot?", "HAPUS", true, func():
##       SaveManager.delete_slot(1)
##   )
class_name InfoModal
extends BaseModal

signal confirmed

var pending_confirm_action: Callable
var lbl_modal_title: Label
var lbl_modal_body: Label
var btn_action: GameMenuButton

func _build_content() -> void:
	# Header Bar
	var header_panel := PanelContainer.new()
	header_panel.custom_minimum_size = Vector2(0, 22)
	var header_style := StyleBoxFlat.new()
	header_style.bg_color = Palette.alpha(Palette.SLATE_DARK, 0.95)
	header_style.content_margin_top = 4
	header_style.content_margin_bottom = 4
	header_panel.add_theme_stylebox_override("panel", header_style)
	content_container.add_child(header_panel)

	lbl_modal_title = Label.new()
	lbl_modal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontManager.apply(lbl_modal_title, FontManager.Type.TITLE, 11, Palette.GOLD)
	header_panel.add_child(lbl_modal_title)

	# Body Teks
	lbl_modal_body = Label.new()
	lbl_modal_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_modal_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_modal_body.custom_minimum_size = Vector2(230, 36)
	FontManager.apply(lbl_modal_body, FontManager.Type.BODY, 9, Palette.WHITE_OFF)
	content_container.add_child(lbl_modal_body)

	# Tombol Aksi Utama (mengambil PackedScene dari BaseModal)
	if menu_button_scene:
		btn_action = menu_button_scene.instantiate()
		btn_action.text = "OK"
		btn_action.set_dimensions(100, 20)
		btn_action.set_variant(GameMenuButton.Variant.ACCENT)
		btn_action.pressed.connect(_on_action_pressed)
		content_container.add_child(btn_action)

func popup(title_text: String, message_text: String) -> void:
	pending_confirm_action = Callable()
	set_border_color(Palette.GOLD)
	FontManager.apply(lbl_modal_title, FontManager.Type.TITLE, 11, Palette.GOLD)
	if btn_action:
		btn_action.text = "OK"
		btn_action.set_dimensions(84, 20)
		btn_action.set_variant(GameMenuButton.Variant.ACCENT)
	_show(title_text, message_text)

func popup_confirm(title_text: String, message_text: String, action_btn_text: String, is_danger: bool, on_confirm_callback: Callable) -> void:
	pending_confirm_action = on_confirm_callback
	var theme_color: Color = Palette.RED if is_danger else Palette.GOLD
	set_border_color(theme_color)
	FontManager.apply(lbl_modal_title, FontManager.Type.TITLE, 11, theme_color)

	if btn_action:
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
