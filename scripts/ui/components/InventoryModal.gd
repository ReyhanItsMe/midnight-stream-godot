extends Control
class_name InventoryModal

static var is_inventory_open: bool = false

const VIEWPORT_RES: Vector2 = Vector2(640, 360)
const MODAL_SIZE: Vector2 = Vector2(530, 294)

const COL_BACKDROP: Color = Color(0.01, 0.01, 0.03, 0.84)
const COL_BG_MODAL: Color = Color(0.05, 0.06, 0.10, 0.98)
const COL_BG_CARD: Color = Color(0.08, 0.09, 0.14, 1.0)
const COL_BG_SLOT_EMPTY: Color = Color(0.06, 0.07, 0.11, 0.75)
const COL_BG_SLOT_SELECTED: Color = Color(0.15, 0.14, 0.10, 1.0)

const COL_BORDER_GOLD: Color = Color(0.95, 0.82, 0.25, 0.95)
const COL_BORDER_SLATE: Color = Color(0.24, 0.28, 0.38, 0.85)
const COL_TEXT_WHITE: Color = Color(0.94, 0.95, 0.98, 1.0)
const COL_TEXT_MUTED: Color = Color(0.50, 0.55, 0.66, 1.0)

const COL_WEIGHT_LIGHT: Color = Color(0.25, 0.88, 0.45, 1.0)
const COL_WEIGHT_MED: Color = Color(0.95, 0.78, 0.20, 1.0)
const COL_WEIGHT_HEAVY: Color = Color(0.95, 0.28, 0.28, 1.0)

var hud_bag_btn: GameMenuButton

var backdrop: ColorRect
var main_box: PanelContainer

var weight_label: Label
var weight_status_badge: Label
var weight_bar_fill: ColorRect

var slot_list_vbox: VBoxContainer
var slot_buttons: Array[Button] = []
var selected_slot_idx: int = 0

var preview_icon: TextureRect
var preview_fallback_lbl: Label
var detail_name_lbl: Label
var detail_meta_lbl: Label
var detail_desc_lbl: Label
var feedback_status_lbl: Label

var hotbar_slots_ui: Array[PanelContainer] = []

var btn_use: GameMenuButton
var btn_hotbar: GameMenuButton
var btn_drop: GameMenuButton

var _debug_item_cycle: Array[String] = [
	"kunci_bangsal_perunggu",
	"baterai_senter",
	"kunci_emas_kepala",
	"kunci_kutukan_mata",
	"peralatan_berat"
]
var _debug_idx: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	position = Vector2.ZERO
	size = VIEWPORT_RES
	custom_minimum_size = VIEWPORT_RES
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_build_hud_bag_button()
	_build_modal_ui()

	var inv_mgr: Node = get_node_or_null("/root/InventoryManager")
	if inv_mgr:
		inv_mgr.inventory_updated.connect(_refresh_ui)
		inv_mgr.hotbar_updated.connect(_refresh_ui)

	_close_modal_instant()


func _unhandled_input(event: InputEvent) -> void:
	if DialogueBox.is_dialogue_open and not is_inventory_open:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB or event.keycode == KEY_I:
			if is_inventory_open:
				close()
			elif not get_tree().paused:
				open()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE and is_inventory_open:
			close()
			get_viewport().set_input_as_handled()


func _build_hud_bag_button() -> void:
	hud_bag_btn = GameMenuButton.new()
	add_child(hud_bag_btn)
	
	hud_bag_btn.text = "[ TAS ]"
	hud_bag_btn.set_dimensions(62, 22)
	hud_bag_btn.font_size_override = 9
	hud_bag_btn.set_variant(GameMenuButton.Variant.DEFAULT)
	hud_bag_btn.position = Vector2(490, 10)
	hud_bag_btn.pressed.connect(func():
		if not DialogueBox.is_dialogue_open:
			open()
	)


func _build_modal_ui() -> void:
	var font_mgr: Node = get_node_or_null("/root/FontManager")

	backdrop = ColorRect.new()
	backdrop.position = Vector2.ZERO
	backdrop.size = VIEWPORT_RES
	backdrop.color = COL_BACKDROP
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	main_box = PanelContainer.new()
	main_box.custom_minimum_size = MODAL_SIZE
	main_box.size = MODAL_SIZE
	main_box.position = (VIEWPORT_RES - MODAL_SIZE) * 0.5
	var box_style := StyleBoxFlat.new()
	box_style.bg_color = COL_BG_MODAL
	box_style.set_border_width_all(1)
	box_style.border_color = COL_BORDER_GOLD
	main_box.add_theme_stylebox_override("panel", box_style)
	backdrop.add_child(main_box)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	main_box.add_child(margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 8)
	margin.add_child(root_vbox)

	var header_hbox := HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 10)
	root_vbox.add_child(header_hbox)

	var title_lbl := Label.new()
	title_lbl.text = "STREAMER BAG // EQUIPMENT"
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if font_mgr:
		font_mgr.apply(title_lbl, font_mgr.Type.TITLE, 15, COL_BORDER_GOLD)
	header_hbox.add_child(title_lbl)

	var weight_vbox := VBoxContainer.new()
	weight_vbox.add_theme_constant_override("separation", 2)
	header_hbox.add_child(weight_vbox)

	var weight_top_row := HBoxContainer.new()
	weight_top_row.add_theme_constant_override("separation", 8)
	weight_vbox.add_child(weight_top_row)

	weight_label = Label.new()
	weight_label.text = "BEBAN: 0.0 / 15.0 KG"
	if font_mgr:
		font_mgr.apply(weight_label, font_mgr.Type.DIGITAL, 10, COL_TEXT_WHITE)
	weight_top_row.add_child(weight_label)

	weight_status_badge = Label.new()
	weight_status_badge.text = "[ RINGAN ]"
	if font_mgr:
		font_mgr.apply(weight_status_badge, font_mgr.Type.BODY_BOLD, 8, COL_WEIGHT_LIGHT)
	weight_top_row.add_child(weight_status_badge)

	var bar_bg := ColorRect.new()
	bar_bg.custom_minimum_size = Vector2(150, 5)
	bar_bg.color = Color(0.12, 0.14, 0.20, 1.0)
	weight_vbox.add_child(bar_bg)

	weight_bar_fill = ColorRect.new()
	weight_bar_fill.position = Vector2.ZERO
	weight_bar_fill.size = Vector2(0, 5)
	weight_bar_fill.color = COL_WEIGHT_LIGHT
	bar_bg.add_child(weight_bar_fill)

	var divider_top := ColorRect.new()
	divider_top.custom_minimum_size = Vector2(0, 1)
	divider_top.color = COL_BORDER_SLATE
	root_vbox.add_child(divider_top)

	var body_hbox := HBoxContainer.new()
	body_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_hbox.add_theme_constant_override("separation", 12)
	root_vbox.add_child(body_hbox)

	var left_col := VBoxContainer.new()
	left_col.custom_minimum_size = Vector2(236, 0)
	left_col.add_theme_constant_override("separation", 4)
	body_hbox.add_child(left_col)

	var list_caption := Label.new()
	list_caption.text = "KAPASITAS TAS (8 SLOT)"
	if font_mgr:
		font_mgr.apply(list_caption, font_mgr.Type.RETRO_ALT, 8, COL_TEXT_MUTED)
	left_col.add_child(list_caption)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_style_scrollbar(scroll)
	left_col.add_child(scroll)

	slot_list_vbox = VBoxContainer.new()
	slot_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot_list_vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(slot_list_vbox)

	_create_slot_rows()

	var right_panel := PanelContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var right_style := StyleBoxFlat.new()
	right_style.bg_color = COL_BG_CARD
	right_style.set_border_width_all(1)
	right_style.border_color = COL_BORDER_SLATE
	right_panel.add_theme_stylebox_override("panel", right_style)
	body_hbox.add_child(right_panel)

	var right_margin := MarginContainer.new()
	right_margin.add_theme_constant_override("margin_left", 10)
	right_margin.add_theme_constant_override("margin_right", 10)
	right_margin.add_theme_constant_override("margin_top", 8)
	right_margin.add_theme_constant_override("margin_bottom", 8)
	right_panel.add_child(right_margin)

	var right_vbox := VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 6)
	right_margin.add_child(right_vbox)

	var inspect_top_hbox := HBoxContainer.new()
	inspect_top_hbox.add_theme_constant_override("separation", 10)
	right_vbox.add_child(inspect_top_hbox)

	var icon_frame := PanelContainer.new()
	icon_frame.custom_minimum_size = Vector2(52, 52)
	var icon_frame_st := StyleBoxFlat.new()
	icon_frame_st.bg_color = Color(0.04, 0.05, 0.08, 1.0)
	icon_frame_st.set_border_width_all(1)
	icon_frame_st.border_color = COL_BORDER_GOLD
	icon_frame.add_theme_stylebox_override("panel", icon_frame_st)
	inspect_top_hbox.add_child(icon_frame)

	preview_icon = TextureRect.new()
	preview_icon.custom_minimum_size = Vector2(44, 44)
	preview_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_frame.add_child(preview_icon)

	preview_fallback_lbl = Label.new()
	preview_fallback_lbl.text = "--"
	preview_fallback_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_fallback_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if font_mgr:
		font_mgr.apply(preview_fallback_lbl, font_mgr.Type.DIGITAL, 12, COL_TEXT_MUTED)
	icon_frame.add_child(preview_fallback_lbl)

	var title_meta_vbox := VBoxContainer.new()
	title_meta_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_meta_vbox.add_theme_constant_override("separation", 3)
	inspect_top_hbox.add_child(title_meta_vbox)

	detail_name_lbl = Label.new()
	detail_name_lbl.text = "PILIH SLOT BARANG"
	detail_name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if font_mgr:
		font_mgr.apply(detail_name_lbl, font_mgr.Type.BODY_BOLD, 10, COL_BORDER_GOLD)
	title_meta_vbox.add_child(detail_name_lbl)

	detail_meta_lbl = Label.new()
	detail_meta_lbl.text = "TIPE: -  |  BERAT: 0.0 KG"
	if font_mgr:
		font_mgr.apply(detail_meta_lbl, font_mgr.Type.DIGITAL, 9, COL_TEXT_MUTED)
	title_meta_vbox.add_child(detail_meta_lbl)

	feedback_status_lbl = Label.new()
	feedback_status_lbl.text = ""
	if font_mgr:
		font_mgr.apply(feedback_status_lbl, font_mgr.Type.RETRO_ALT, 8, COL_WEIGHT_LIGHT)
	title_meta_vbox.add_child(feedback_status_lbl)

	detail_desc_lbl = Label.new()
	detail_desc_lbl.text = "Sentuh salah satu slot di sebelah kiri untuk memeriksa detail peralatan atau memasangnya ke Hotbar."
	detail_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if font_mgr:
		font_mgr.apply(detail_desc_lbl, font_mgr.Type.BODY, 9, COL_TEXT_WHITE)
	right_vbox.add_child(detail_desc_lbl)

	var hb_header := Label.new()
	hb_header.text = "QUICK-SLOT HOTBAR (3 SLOT AKTIF):"
	if font_mgr:
		font_mgr.apply(hb_header, font_mgr.Type.RETRO_ALT, 8, COL_TEXT_MUTED)
	right_vbox.add_child(hb_header)

	var hb_hbox := HBoxContainer.new()
	hb_hbox.add_theme_constant_override("separation", 6)
	right_vbox.add_child(hb_hbox)

	hotbar_slots_ui.clear()
	for i in range(InventoryManager.MAX_HOTBAR):
		var hb_box := _create_hotbar_mini_box(i)
		hotbar_slots_ui.append(hb_box)
		hb_hbox.add_child(hb_box)

	var action_hbox := HBoxContainer.new()
	action_hbox.add_theme_constant_override("separation", 6)
	right_vbox.add_child(action_hbox)

	btn_use = GameMenuButton.new()
	action_hbox.add_child(btn_use)
	btn_use.text = "GUNAKAN"
	btn_use.set_dimensions(76, 22)
	btn_use.font_size_override = 8
	btn_use.set_variant(GameMenuButton.Variant.ACCENT)
	btn_use.pressed.connect(_on_use_pressed)

	btn_hotbar = GameMenuButton.new()
	action_hbox.add_child(btn_hotbar)
	btn_hotbar.text = "KE HOTBAR"
	btn_hotbar.set_dimensions(82, 22)
	btn_hotbar.font_size_override = 8
	btn_hotbar.set_variant(GameMenuButton.Variant.DEFAULT)
	btn_hotbar.pressed.connect(_on_hotbar_pressed)

	btn_drop = GameMenuButton.new()
	action_hbox.add_child(btn_drop)
	btn_drop.text = "BUANG"
	btn_drop.set_dimensions(62, 22)
	btn_drop.font_size_override = 8
	btn_drop.set_variant(GameMenuButton.Variant.DANGER)
	btn_drop.pressed.connect(_on_drop_pressed)

	var divider_bot := ColorRect.new()
	divider_bot.custom_minimum_size = Vector2(0, 1)
	divider_bot.color = COL_BORDER_SLATE
	root_vbox.add_child(divider_bot)

	var footer_hbox := HBoxContainer.new()
	footer_hbox.add_theme_constant_override("separation", 10)
	root_vbox.add_child(footer_hbox)

	var btn_test_add := GameMenuButton.new()
	footer_hbox.add_child(btn_test_add)
	btn_test_add.text = "+ TES AMBIL ITEM"
	btn_test_add.set_dimensions(130, 24)
	btn_test_add.font_size_override = 8
	btn_test_add.set_variant(GameMenuButton.Variant.DEFAULT)
	btn_test_add.pressed.connect(_on_debug_add_item)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer_hbox.add_child(spacer)

	var btn_close := GameMenuButton.new()
	footer_hbox.add_child(btn_close)
	btn_close.text = "TUTUP TAS [ESC]"
	btn_close.set_dimensions(130, 24)
	btn_close.font_size_override = 9
	btn_close.set_variant(GameMenuButton.Variant.ACCENT)
	btn_close.pressed.connect(close)


func _create_slot_rows() -> void:
	var font_mgr: Node = get_node_or_null("/root/FontManager")
	slot_buttons.clear()

	for i in range(InventoryManager.MAX_SLOTS):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(218, 24)
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if font_mgr:
			font_mgr.apply(btn, font_mgr.Type.BODY_BOLD, 9, COL_TEXT_WHITE)

		var idx: int = i
		btn.pressed.connect(func():
			selected_slot_idx = idx
			feedback_status_lbl.text = ""
			_refresh_ui()
		)
		slot_list_vbox.add_child(btn)
		slot_buttons.append(btn)


func _create_hotbar_mini_box(hb_idx: int) -> PanelContainer:
	var font_mgr: Node = get_node_or_null("/root/FontManager")
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(74, 26)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.04, 0.05, 0.08, 1.0)
	st.set_border_width_all(1)
	st.border_color = COL_BORDER_SLATE
	box.add_theme_stylebox_override("panel", st)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)
	box.add_child(hbox)

	var num_lbl := Label.new()
	num_lbl.text = " [%d]" % (hb_idx + 1)
	if font_mgr:
		font_mgr.apply(num_lbl, font_mgr.Type.DIGITAL, 9, COL_BORDER_GOLD)
	hbox.add_child(num_lbl)

	var icon_rect := TextureRect.new()
	icon_rect.name = "HbIcon"
	icon_rect.custom_minimum_size = Vector2(18, 18)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(icon_rect)

	var name_lbl := Label.new()
	name_lbl.name = "HbLabel"
	name_lbl.text = "KOSONG"
	name_lbl.clip_text = true
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if font_mgr:
		font_mgr.apply(name_lbl, font_mgr.Type.BODY, 8, COL_TEXT_MUTED)
	hbox.add_child(name_lbl)

	return box


func _refresh_ui() -> void:
	var inv_mgr: Node = get_node_or_null("/root/InventoryManager")
	var font_mgr: Node = get_node_or_null("/root/FontManager")
	if not inv_mgr:
		return

	var cur_w: float = inv_mgr.current_weight
	var max_w: float = inv_mgr.MAX_WEIGHT
	weight_label.text = "BEBAN: %.1f / %.1f KG" % [cur_w, max_w]

	var ratio: float = clampf(cur_w / max_w, 0.0, 1.0)
	weight_bar_fill.size.x = 150.0 * ratio

	var lvl: String = inv_mgr.get_encumbrance_level()
	var w_col: Color = COL_WEIGHT_LIGHT
	var w_txt: String = "[ RINGAN ]"
	if lvl == "HEAVY":
		w_col = COL_WEIGHT_HEAVY
		w_txt = "[ BERAT / LAMBAT ]"
	elif lvl == "MEDIUM":
		w_col = COL_WEIGHT_MED
		w_txt = "[ SEDANG ]"

	weight_bar_fill.color = w_col
	weight_status_badge.text = w_txt
	if font_mgr:
		font_mgr.apply(weight_status_badge, font_mgr.Type.BODY_BOLD, 8, w_col)

	for i in range(slot_buttons.size()):
		var btn: Button = slot_buttons[i]
		var slot_data: Dictionary = inv_mgr.inventory[i]
		var is_sel: bool = (i == selected_slot_idx)

		var st := StyleBoxFlat.new()
		st.bg_color = COL_BG_SLOT_SELECTED if is_sel else COL_BG_SLOT_EMPTY
		st.set_border_width_all(1)
		st.border_color = COL_BORDER_GOLD if is_sel else COL_BORDER_SLATE
		st.content_margin_left = 8
		st.content_margin_right = 8
		btn.add_theme_stylebox_override("normal", st)
		btn.add_theme_stylebox_override("hover", st)
		btn.add_theme_stylebox_override("pressed", st)

		if slot_data.has("id"):
			var meta: Dictionary = inv_mgr.get_item_meta(slot_data["id"])
			var item_name: String = meta.get("name", slot_data["id"])
			var amt: int = int(slot_data.get("amount", 1))
			var w_total: float = float(meta.get("weight", 0.0)) * amt
			btn.text = "#%d  %s (x%d)  [%.1fkg]" % [i + 1, item_name, amt, w_total]
			if font_mgr:
				font_mgr.apply(btn, font_mgr.Type.BODY_BOLD, 9, COL_BORDER_GOLD if is_sel else COL_TEXT_WHITE)
		else:
			btn.text = "#%d  [ SLOT KOSONG ]" % (i + 1)
			if font_mgr:
				font_mgr.apply(btn, font_mgr.Type.BODY, 9, COL_TEXT_MUTED)

	var sel_slot: Dictionary = inv_mgr.inventory[selected_slot_idx]
	if sel_slot.has("id"):
		var id_str: String = sel_slot["id"]
		var meta: Dictionary = inv_mgr.get_item_meta(id_str)
		detail_name_lbl.text = meta.get("name", "ITEM").to_upper()

		var type_str: String = _get_type_label(meta.get("type", 0))
		var unit_w: float = float(meta.get("weight", 0.0))
		detail_meta_lbl.text = "TIPE: %s  |  BOBOT: %.1f KG / UNIT" % [type_str, unit_w]
		detail_desc_lbl.text = meta.get("desc", "-")

		var icon_path: String = meta.get("icon_path", "")
		if icon_path != "" and ResourceLoader.exists(icon_path):
			preview_icon.texture = load(icon_path)
			preview_icon.visible = true
			preview_fallback_lbl.visible = false
		else:
			preview_icon.visible = false
			preview_fallback_lbl.visible = true
			preview_fallback_lbl.text = type_str.left(3)

		btn_use.disabled = false
		btn_hotbar.disabled = false
		btn_drop.disabled = false
	else:
		detail_name_lbl.text = "SLOT #%d KOSONG" % (selected_slot_idx + 1)
		detail_meta_lbl.text = "TIPE: -  |  BOBOT: 0.0 KG"
		detail_desc_lbl.text = "Tidak ada barang di slot ini. Tekan tombol '+ TES AMBIL ITEM' di kiri bawah untuk menguji masuknya kunci dan peralatan ke dalam tas."
		preview_icon.visible = false
		preview_fallback_lbl.visible = true
		preview_fallback_lbl.text = "--"

		btn_use.disabled = true
		btn_hotbar.disabled = true
		btn_drop.disabled = true

	for i in range(hotbar_slots_ui.size()):
		var box: PanelContainer = hotbar_slots_ui[i]
		var hbox: HBoxContainer = box.get_child(0)
		var ic: TextureRect = hbox.get_node("HbIcon")
		var lb: Label = hbox.get_node("HbLabel")
		var hb_data: Dictionary = inv_mgr.hotbar[i]

		if hb_data.has("id"):
			var meta: Dictionary = inv_mgr.get_item_meta(hb_data["id"])
			var icon_p: String = meta.get("icon_path", "")
			ic.texture = load(icon_p) if (icon_p != "" and ResourceLoader.exists(icon_p)) else null
			lb.text = meta.get("name", "ITEM").left(7)
			if font_mgr:
				font_mgr.apply(lb, font_mgr.Type.BODY_BOLD, 8, COL_TEXT_WHITE)
		else:
			ic.texture = null
			lb.text = "KOSONG"
			if font_mgr:
				font_mgr.apply(lb, font_mgr.Type.BODY, 8, COL_TEXT_MUTED)


func _get_type_label(t: int) -> String:
	match t:
		InventoryManager.ItemType.KEY: return "KUNCI"
		InventoryManager.ItemType.CONSUMABLE: return "KONSUMSI"
		InventoryManager.ItemType.DOCUMENT: return "DOKUMEN"
		_: return "ALAT"


func _on_use_pressed() -> void:
	var inv_mgr: Node = get_node_or_null("/root/InventoryManager")
	if inv_mgr:
		feedback_status_lbl.text = inv_mgr.use_item_at_slot(selected_slot_idx)
		_refresh_ui()


func _on_hotbar_pressed() -> void:
	var inv_mgr: Node = get_node_or_null("/root/InventoryManager")
	if inv_mgr:
		feedback_status_lbl.text = inv_mgr.assign_to_hotbar(selected_slot_idx)
		_refresh_ui()


func _on_drop_pressed() -> void:
	var inv_mgr: Node = get_node_or_null("/root/InventoryManager")
	if inv_mgr and inv_mgr.remove_item_at_slot(selected_slot_idx, 1):
		feedback_status_lbl.text = "1x barang dikeluarkan dari tas."
		_refresh_ui()


func _on_debug_add_item() -> void:
	var inv_mgr: Node = get_node_or_null("/root/InventoryManager")
	if not inv_mgr:
		return

	var item_id: String = _debug_item_cycle[_debug_idx % _debug_item_cycle.size()]
	_debug_idx += 1

	if inv_mgr.add_item(item_id, 1):
		var meta: Dictionary = inv_mgr.get_item_meta(item_id)
		feedback_status_lbl.text = "+ Diambil: " + meta.get("name", item_id)
	else:
		feedback_status_lbl.text = "GAGAL: Tas penuh atau beban > 15 KG!"
	_refresh_ui()


func open() -> void:
	if is_inventory_open:
		return
	is_inventory_open = true
	get_tree().paused = true
	hud_bag_btn.visible = false
	feedback_status_lbl.text = ""
	_refresh_ui()

	backdrop.visible = true
	backdrop.modulate.a = 0.0
	main_box.scale = Vector2(0.95, 0.95)
	main_box.pivot_offset = MODAL_SIZE * 0.5

	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	tw.tween_property(backdrop, "modulate:a", 1.0, 0.16)
	tw.tween_property(main_box, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func close() -> void:
	if not is_inventory_open:
		return
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	tw.tween_property(backdrop, "modulate:a", 0.0, 0.14)
	tw.tween_property(main_box, "scale", Vector2(0.95, 0.95), 0.14)
	tw.chain().tween_callback(_close_modal_instant)


func _close_modal_instant() -> void:
	backdrop.visible = false
	is_inventory_open = false
	if hud_bag_btn:
		hud_bag_btn.visible = true
	if get_tree():
		get_tree().paused = false


func _style_scrollbar(scroll: ScrollContainer) -> void:
	var vbar: VScrollBar = scroll.get_v_scroll_bar()
	if not vbar:
		return
	vbar.custom_minimum_size.x = 5
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.04, 0.05, 0.08, 0.9)
	var grab := StyleBoxFlat.new()
	grab.bg_color = COL_BORDER_GOLD
	vbar.add_theme_stylebox_override("scroll", bg)
	vbar.add_theme_stylebox_override("grabber", grab)
	vbar.add_theme_stylebox_override("grabber_highlight", grab)
	vbar.add_theme_stylebox_override("grabber_pressed", grab)
