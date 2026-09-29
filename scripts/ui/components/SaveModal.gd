extends Control
class_name SaveModal

signal save_completed(slot_idx: int)
signal modal_closed

const FONT_PATH: String = "res://assets/fonts/Pix32.ttf"
const MENU_BUTTON_SCENE: PackedScene = preload("res://scenes/ui/components/MenuButton.tscn")

const COLOR_GOLD: Color = Color(0.95, 0.82, 0.25)
const COLOR_WHITE: Color = Color(0.92, 0.94, 0.96)
const COLOR_MODAL_BG: Color = Color(0.05, 0.06, 0.09, 0.98)
const COLOR_HEADER_BG: Color = Color(0.1, 0.12, 0.17, 1.0)
const COLOR_WARNING_RED: Color = Color(0.95, 0.25, 0.25)

var custom_font: FontFile
var current_slot: int = 1

var main_container: VBoxContainer
var lbl_slot_info: Label
var lbl_slot_status: Label

# Overwrite Dialog Elements
var overwrite_overlay: Control
var overwrite_container: VBoxContainer

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	modulate.a = 0.0

	if ResourceLoader.exists(FONT_PATH):
		custom_font = load(FONT_PATH)

	_build_main_save_dialog()
	_build_overwrite_dialog()


func open() -> void:
	current_slot = 1
	_refresh_slot_display()
	visible = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.15)


func close() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.12)
	tw.tween_callback(func():
		visible = false
		modal_closed.emit()
	)


# ==============================================================================
# MAIN SAVE DIALOG
# ==============================================================================

func _build_main_save_dialog() -> void:
	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.72)
	add_child(dimmer)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	main_container = VBoxContainer.new()
	main_container.alignment = BoxContainer.ALIGNMENT_CENTER
	main_container.add_theme_constant_override("separation", 8)
	center.add_child(main_container)

	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(250, 130)
	var box_style := StyleBoxFlat.new()
	box_style.bg_color = COLOR_MODAL_BG
	box_style.set_border_width_all(1)
	box_style.border_color = COLOR_GOLD
	box.add_theme_stylebox_override("panel", box_style)
	main_container.add_child(box)

	var box_vbox := VBoxContainer.new()
	box_vbox.add_theme_constant_override("separation", 8)
	box.add_child(box_vbox)

	# Header Title
	var header_bar := PanelContainer.new()
	header_bar.custom_minimum_size = Vector2(0, 20)
	var header_style := StyleBoxFlat.new()
	header_style.bg_color = COLOR_HEADER_BG
	header_bar.add_theme_stylebox_override("panel", header_style)
	box_vbox.add_child(header_bar)

	var lbl_title := Label.new()
	lbl_title.text = "TERMINAL REKAMAN // SAVE LOG"
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	apply_font(lbl_title, 10, COLOR_GOLD)
	header_bar.add_child(lbl_title)

	# Slot Selector Stepper (1-20)
	var stepper_hbox := HBoxContainer.new()
	stepper_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	stepper_hbox.add_theme_constant_override("separation", 10)
	box_vbox.add_child(stepper_hbox)

	var btn_prev: GameMenuButton = MENU_BUTTON_SCENE.instantiate()
	btn_prev.text = "▲"
	btn_prev.set_dimensions(26, 22)
	btn_prev.pressed.connect(func(): _cycle_slot(-1))
	stepper_hbox.add_child(btn_prev)

	lbl_slot_info = Label.new()
	lbl_slot_info.text = "SLOT 01 / 20"
	lbl_slot_info.custom_minimum_size = Vector2(90, 0)
	lbl_slot_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	apply_font(lbl_slot_info, 10, COLOR_WHITE)
	stepper_hbox.add_child(lbl_slot_info)

	var btn_next: GameMenuButton = MENU_BUTTON_SCENE.instantiate()
	btn_next.text = "▼"
	btn_next.set_dimensions(26, 22)
	btn_next.pressed.connect(func(): _cycle_slot(1))
	stepper_hbox.add_child(btn_next)

	# Status Description
	lbl_slot_status = Label.new()
	lbl_slot_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_slot_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_slot_status.custom_minimum_size = Vector2(230, 24)
	apply_font(lbl_slot_status, 8, Color(0.7, 0.75, 0.8))
	box_vbox.add_child(lbl_slot_status)

	# Action Save Button
	var btn_save: GameMenuButton = MENU_BUTTON_SCENE.instantiate()
	btn_save.text = "SIMPAN REKAMAN"
	btn_save.set_dimensions(140, 22)
	btn_save.set_variant(GameMenuButton.Variant.ACCENT)
	btn_save.pressed.connect(_on_save_button_pressed)
	box_vbox.add_child(btn_save)

	# Close [X] Button Under the Box
	var btn_close: GameMenuButton = MENU_BUTTON_SCENE.instantiate()
	btn_close.text = "X"
	btn_close.set_dimensions(24, 24)
	btn_close.set_variant(GameMenuButton.Variant.DANGER)
	_style_round_close_btn(btn_close)
	btn_close.pressed.connect(close)
	main_container.add_child(btn_close)


# ==============================================================================
# OVERWRITE CONFIRMATION MODAL
# ==============================================================================

func _build_overwrite_dialog() -> void:
	overwrite_overlay = Control.new()
	overwrite_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overwrite_overlay.visible = false
	overwrite_overlay.modulate.a = 0.0
	add_child(overwrite_overlay)

	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.82)
	overwrite_overlay.add_child(dimmer)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overwrite_overlay.add_child(center)

	overwrite_container = VBoxContainer.new()
	overwrite_container.alignment = BoxContainer.ALIGNMENT_CENTER
	overwrite_container.add_theme_constant_override("separation", 8)
	center.add_child(overwrite_container)

	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(230, 105)
	var box_style := StyleBoxFlat.new()
	box_style.bg_color = COLOR_MODAL_BG
	box_style.set_border_width_all(1)
	box_style.border_color = COLOR_WARNING_RED
	box.add_theme_stylebox_override("panel", box_style)
	overwrite_container.add_child(box)

	var box_vbox := VBoxContainer.new()
	box_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	box_vbox.add_theme_constant_override("separation", 8)
	box.add_child(box_vbox)

	var lbl_alert_title := Label.new()
	lbl_alert_title.text = "PERINGATAN TIMPA DATA"
	lbl_alert_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	apply_font(lbl_alert_title, 10, COLOR_WARNING_RED)
	box_vbox.add_child(lbl_alert_title)

	var lbl_alert_msg := Label.new()
	lbl_alert_msg.text = "Slot ini sudah memiliki rekaman.\nYakin ingin menimpa rekaman lama?"
	lbl_alert_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	apply_font(lbl_alert_msg, 8, COLOR_WHITE)
	box_vbox.add_child(lbl_alert_msg)

	var btn_hbox := HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 10)
	box_vbox.add_child(btn_hbox)

	var btn_yes: GameMenuButton = MENU_BUTTON_SCENE.instantiate()
	btn_yes.text = "YA, TIMPA"
	btn_yes.set_dimensions(76, 20)
	btn_yes.set_variant(GameMenuButton.Variant.DANGER)
	btn_yes.pressed.connect(_execute_save)
	btn_hbox.add_child(btn_yes)

	var btn_no: GameMenuButton = MENU_BUTTON_SCENE.instantiate()
	btn_no.text = "BATAL"
	btn_no.set_dimensions(60, 20)
	btn_no.pressed.connect(_close_overwrite_dialog)
	btn_hbox.add_child(btn_no)


# ==============================================================================
# LOGIC & EVENTS
# ==============================================================================

func _cycle_slot(delta_val: int) -> void:
	current_slot = clampi(current_slot + delta_val, 1, SaveManager.MAX_SLOTS)
	_refresh_slot_display()


func _refresh_slot_display() -> void:
	lbl_slot_info.text = "SLOT %02d / %02d" % [current_slot, SaveManager.MAX_SLOTS]
	if SaveManager.has_slot_file(current_slot):
		lbl_slot_status.text = "STATUS: TERISI\n" + SaveManager.get_slot_summary(current_slot)
		lbl_slot_status.modulate = Color(0.95, 0.85, 0.4)
	else:
		lbl_slot_status.text = "STATUS: KOSONG\n(Siap merekam data baru)"
		lbl_slot_status.modulate = Color(0.6, 0.65, 0.75)


func _on_save_button_pressed() -> void:
	if SaveManager.has_slot_file(current_slot):
		_open_overwrite_dialog()
	else:
		_execute_save()


func _open_overwrite_dialog() -> void:
	overwrite_overlay.visible = true
	var tw := create_tween()
	tw.tween_property(overwrite_overlay, "modulate:a", 1.0, 0.14)


func _close_overwrite_dialog() -> void:
	var tw := create_tween()
	tw.tween_property(overwrite_overlay, "modulate:a", 0.0, 0.1)
	tw.tween_callback(func(): overwrite_overlay.visible = false)


func _execute_save() -> void:
	_close_overwrite_dialog()
	SaveManager.save_to_slot(current_slot)
	_refresh_slot_display()
	lbl_slot_status.text = "BERHASIL MENYIMPAN REKAMAN!"
	lbl_slot_status.modulate = Color(0.3, 0.9, 0.4)
	save_completed.emit(current_slot)


func _style_round_close_btn(btn: GameMenuButton) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.05, 0.07, 0.9)
	style.set_border_width_all(1)
	style.border_color = Color(0.85, 0.22, 0.22)
	style.set_corner_radius_all(12)
	btn.add_theme_stylebox_override("normal", style)


func apply_font(lbl: Label, size_px: int, col: Color) -> void:
	if custom_font:
		lbl.add_theme_font_override("font", custom_font)
	lbl.add_theme_font_size_override("font_size", size_px)
	lbl.add_theme_color_override("font_color", col)
