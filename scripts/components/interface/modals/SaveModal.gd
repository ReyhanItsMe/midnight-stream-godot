## Jendela antarmuka perekaman data untuk 20 Slot Archive di Save Point.
##
## Cara pakai:
##   var save_ui = SaveModal.new()
##   add_child(save_ui)
##   save_ui.open() # Membuka slot 1 dan merefresh status arsip
##   save_ui.save_completed.connect(func(slot): print("Tersimpan di slot: ", slot))
class_name SaveModal
extends BaseModal

signal save_completed(slot_idx: int)

var current_slot: int = 1
var lbl_slot_info: Label
var lbl_slot_status: Label
var btn_save: GameMenuButton
var info_modal_instance: InfoModal
var info_modal_scene: PackedScene

func _ready() -> void:
	box_size = Vector2(250, 130)
	_load_modal_resources()
	super._ready()

	# Instansiasi InfoModal sebagai popup konfirmasi penimpaan data
	if info_modal_scene:
		info_modal_instance = info_modal_scene.instantiate()
		add_child(info_modal_instance)

func _load_modal_resources() -> void:
	var modal_path: String = ScenePaths.UIComponents.INFO_MODAL
	if ResourceLoader.exists(modal_path):
		info_modal_scene = load(modal_path)
	else:
		push_error("[SaveModal] InfoModal scene tidak ditemukan di: " + modal_path)

func _build_content() -> void:
	# 1. Header Bar
	var header_bar := PanelContainer.new()
	header_bar.custom_minimum_size = Vector2(0, 20)
	var header_style := StyleBoxFlat.new()
	header_style.bg_color = Palette.alpha(Palette.BG_SLOT, 0.95)
	header_bar.add_theme_stylebox_override("panel", header_style)
	content_container.add_child(header_bar)

	var lbl_title := Label.new()
	lbl_title.text = "TERMINAL REKAMAN // SAVE LOG"
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_font(lbl_title, 10, Palette.GOLD)
	header_bar.add_child(lbl_title)

	# 2. Stepper Pemilih Slot (▲ / ▼)
	var stepper_hbox := HBoxContainer.new()
	stepper_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	stepper_hbox.add_theme_constant_override("separation", 10)
	content_container.add_child(stepper_hbox)

	var btn_prev: GameMenuButton = menu_button_scene.instantiate()
	btn_prev.text = "▲"
	btn_prev.set_dimensions(26, 22)
	btn_prev.pressed.connect(func(): _cycle_slot(-1))
	stepper_hbox.add_child(btn_prev)

	lbl_slot_info = Label.new()
	lbl_slot_info.text = "SLOT 01 / 20"
	lbl_slot_info.custom_minimum_size = Vector2(90, 0)
	lbl_slot_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_font(lbl_slot_info, 10, Palette.WHITE)
	stepper_hbox.add_child(lbl_slot_info)

	var btn_next: GameMenuButton = menu_button_scene.instantiate()
	btn_next.text = "▼"
	btn_next.set_dimensions(26, 22)
	btn_next.pressed.connect(func(): _cycle_slot(1))
	stepper_hbox.add_child(btn_next)

	# 3. Label Status Slot
	lbl_slot_status = Label.new()
	lbl_slot_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_slot_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_slot_status.custom_minimum_size = Vector2(230, 24)
	_apply_font(lbl_slot_status, 8, Palette.TEXT_MUTED)
	content_container.add_child(lbl_slot_status)

	# 4. Tombol Aksi Simpan
	btn_save = menu_button_scene.instantiate()
	btn_save.text = "SIMPAN REKAMAN"
	btn_save.set_dimensions(140, 22)
	btn_save.set_variant(GameMenuButton.Variant.ACCENT)
	btn_save.pressed.connect(_on_save_button_pressed)
	content_container.add_child(btn_save)

## Kompatibilitas dengan pemanggil lama (HUD/Save Station)
func open() -> void:
	current_slot = 1
	_refresh_slot_display()
	open_modal()

func _cycle_slot(delta_val: int) -> void:
	var save_mgr = _get_save_manager()
	var max_slots: int = save_mgr.MAX_SLOTS if (save_mgr and "MAX_SLOTS" in save_mgr) else 20
	current_slot = clampi(current_slot + delta_val, 1, max_slots)
	_refresh_slot_display()

func _refresh_slot_display() -> void:
	var save_mgr = _get_save_manager()
	var max_slots: int = save_mgr.MAX_SLOTS if (save_mgr and "MAX_SLOTS" in save_mgr) else 20
	lbl_slot_info.text = "SLOT %02d / %02d" % [current_slot, max_slots]

	if save_mgr and save_mgr.has_method("has_slot_file") and save_mgr.has_slot_file(current_slot):
		var summary: String = save_mgr.get_slot_summary(current_slot) if save_mgr.has_method("get_slot_summary") else ""
		lbl_slot_status.text = "STATUS: TERISI\n" + summary
		lbl_slot_status.modulate = Palette.GOLD
	else:
		lbl_slot_status.text = "STATUS: KOSONG\n(Siap merekam data baru)"
		lbl_slot_status.modulate = Palette.TEXT_MUTED

func _on_save_button_pressed() -> void:
	var save_mgr = _get_save_manager()
	if save_mgr and save_mgr.has_method("has_slot_file") and save_mgr.has_slot_file(current_slot):
		if info_modal_instance:
			info_modal_instance.popup_confirm(
				"PERINGATAN TIMPA DATA",
				"Slot ini sudah memiliki rekaman.\nYakin ingin menimpa rekaman lama?",
				"YA, TIMPA",
				true,
				_execute_save
			)
	else:
		_execute_save()

func _execute_save() -> void:
	var save_mgr = _get_save_manager()
	if save_mgr and save_mgr.has_method("save_to_slot"):
		save_mgr.save_to_slot(current_slot)

	_refresh_slot_display()
	lbl_slot_status.text = "BERHASIL MENYIMPAN REKAMAN!"
	lbl_slot_status.modulate = Color(0.3, 0.9, 0.4)
	save_completed.emit(current_slot)

func _get_save_manager() -> Node:
	var root_node = Engine.get_main_loop().root if Engine.get_main_loop() else null
	return root_node.get_node_or_null("SaveManager") if root_node else null

func _apply_font(lbl: Label, f_size: int, col: Color) -> void:
	var root_node = Engine.get_main_loop().root if Engine.get_main_loop() else null
	var font_mgr = root_node.get_node_or_null("FontManager") if root_node else null
	if font_mgr and font_mgr.has_method("apply"):
		font_mgr.apply(lbl, 1, f_size, col)
	else:
		lbl.add_theme_font_size_override("font_size", f_size)
		lbl.add_theme_color_override("font_color", col)
