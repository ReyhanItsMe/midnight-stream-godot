class_name InventorySlotList
extends VBoxContainer

signal slot_selected(idx: int)

const COL_BG_SLOT_EMPTY: Color = Color(0.06, 0.07, 0.11, 0.75)
const COL_BG_SLOT_SELECTED: Color = Color(0.15, 0.14, 0.10, 1.0)
const COL_BORDER_GOLD: Color = Color(0.95, 0.82, 0.25, 0.95)
const COL_BORDER_SLATE: Color = Color(0.24, 0.28, 0.38, 0.85)
const COL_TEXT_WHITE: Color = Color(0.94, 0.95, 0.98, 1.0)
const COL_TEXT_MUTED: Color = Color(0.50, 0.55, 0.66, 1.0)

var slot_scroll: ScrollContainer
var slot_list_vbox: VBoxContainer
var slot_buttons: Array[Button] = []

func _init() -> void:
	custom_minimum_size = Vector2(246, 0)
	add_theme_constant_override("separation", 4)

	var list_caption := Label.new()
	list_caption.text = "KAPASITAS TAS (8 SLOT)"
	_apply_font(list_caption, 2, 8, COL_TEXT_MUTED)
	add_child(list_caption)

	var slot_area_hbox := HBoxContainer.new()
	slot_area_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	slot_area_hbox.add_theme_constant_override("separation", 4)
	add_child(slot_area_hbox)

	var slot_nav_vbox := VBoxContainer.new()
	slot_nav_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	slot_nav_vbox.add_theme_constant_override("separation", 4)
	slot_area_hbox.add_child(slot_nav_vbox)

	var btn_up := GameMenuButton.new()
	btn_up.text = "▲"
	btn_up.set_dimensions(18, 22)
	btn_up.font_size_override = 7
	btn_up.set_variant(GameMenuButton.Variant.DEFAULT)
	btn_up.pressed.connect(func(): slot_scroll.scroll_vertical = maxi(0, slot_scroll.scroll_vertical - 30))
	slot_nav_vbox.add_child(btn_up)

	var btn_down := GameMenuButton.new()
	btn_down.text = "▼"
	btn_down.set_dimensions(18, 22)
	btn_down.font_size_override = 7
	btn_down.set_variant(GameMenuButton.Variant.DEFAULT)
	btn_down.pressed.connect(func(): slot_scroll.scroll_vertical += 30)
	slot_nav_vbox.add_child(btn_down)

	slot_scroll = ScrollContainer.new()
	slot_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	slot_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	slot_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	slot_area_hbox.add_child(slot_scroll)

	slot_list_vbox = VBoxContainer.new()
	slot_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot_list_vbox.add_theme_constant_override("separation", 3)
	slot_scroll.add_child(slot_list_vbox)

	_build_slot_buttons()

func _build_slot_buttons() -> void:
	# Asumsi MAX_SLOTS = 8
	for i in range(8):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(216, 22)
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		var idx: int = i
		btn.pressed.connect(func(): slot_selected.emit(idx))
		slot_list_vbox.add_child(btn)
		slot_buttons.append(btn)

func refresh(inv_mgr: Node, selected_idx: int) -> void:
	if not inv_mgr or not inv_mgr.get("inventory"): return
	
	for i in range(slot_buttons.size()):
		var btn: Button = slot_buttons[i]
		var slot_data: Dictionary = inv_mgr.inventory[i]
		var is_sel: bool = (i == selected_idx)

		var st := StyleBoxFlat.new()
		st.bg_color = COL_BG_SLOT_SELECTED if is_sel else COL_BG_SLOT_EMPTY
		st.set_border_width_all(1)
		st.border_color = COL_BORDER_GOLD if is_sel else COL_BORDER_SLATE
		st.content_margin_left = 6
		st.content_margin_right = 6
		btn.add_theme_stylebox_override("normal", st)
		btn.add_theme_stylebox_override("hover", st)
		btn.add_theme_stylebox_override("pressed", st)

		if slot_data.has("id"):
			var meta: Dictionary = inv_mgr.get_item_meta(slot_data["id"]) if inv_mgr.has_method("get_item_meta") else {}
			var item_name: String = meta.get("name", slot_data["id"])
			var amt: int = int(slot_data.get("amount", 1))
			var w_total: float = float(meta.get("weight", 0.0)) * amt
			btn.text = "#%d  %s (x%d)  [%.1fkg]" % [i + 1, item_name, amt, w_total]
			_apply_font(btn, 1, 8, COL_BORDER_GOLD if is_sel else COL_TEXT_WHITE)
		else:
			btn.text = "#%d  [ SLOT KOSONG ]" % (i + 1)
			_apply_font(btn, 1, 8, COL_TEXT_MUTED)

func _apply_font(lbl: Control, type: int, f_size: int, col: Color) -> void:
	var root_node = Engine.get_main_loop().root if Engine.get_main_loop() else null
	var font_mgr = root_node.get_node_or_null("FontManager") if root_node else null
	if font_mgr and font_mgr.has_method("apply"):
		font_mgr.apply(lbl, type, f_size, col)
	else:
		lbl.add_theme_font_size_override("font_size", f_size)
		lbl.add_theme_color_override("font_color", col)
