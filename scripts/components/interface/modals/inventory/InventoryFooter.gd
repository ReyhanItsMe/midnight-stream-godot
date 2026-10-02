class_name InventoryFooter
extends HBoxContainer

signal hotbar_selected(hb_idx: int)
signal close_requested

const COL_BORDER_GOLD: Color = Color(0.95, 0.82, 0.25, 0.95)
const COL_BORDER_SLATE: Color = Color(0.24, 0.28, 0.38, 0.85)
const COL_TEXT_WHITE: Color = Color(0.94, 0.95, 0.98, 1.0)
const COL_TEXT_MUTED: Color = Color(0.50, 0.55, 0.66, 1.0)
const COL_WEIGHT_LIGHT: Color = Color(0.25, 0.88, 0.45, 1.0)

const HOTBAR_SLOTS: int = 4 # samakan dengan MAX_HOTBAR di InventoryManager

var hand_icon_rect: TextureRect
var hand_name_lbl: Label
var hotbar_slots_ui: Array[PanelContainer] = []

func _init() -> void:
	add_theme_constant_override("separation", 4)
	alignment = BoxContainer.ALIGNMENT_BEGIN

	# Tangan (Equipped)
	var hand_caption := Label.new()
	hand_caption.text = "DIPEGANG:"
	_apply_font(hand_caption, 3, 9, COL_WEIGHT_LIGHT)
	add_child(hand_caption)

	var hand_box := PanelContainer.new()
	hand_box.custom_minimum_size = Vector2(66, 24)
	var hand_st := StyleBoxFlat.new()
	hand_st.bg_color = Color(0.06, 0.09, 0.07, 1.0)
	hand_st.set_border_width_all(1)
	hand_st.border_color = COL_WEIGHT_LIGHT
	hand_box.add_theme_stylebox_override("panel", hand_st)
	add_child(hand_box)
	
	var hand_box_hbox := HBoxContainer.new()
	hand_box_hbox.add_theme_constant_override("separation", 3)
	hand_box.add_child(hand_box_hbox)
	
	hand_icon_rect = TextureRect.new()
	hand_icon_rect.custom_minimum_size = Vector2(16, 16)
	hand_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hand_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hand_box_hbox.add_child(hand_icon_rect)
	
	hand_name_lbl = Label.new()
	hand_name_lbl.clip_text = true
	hand_name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(hand_name_lbl, 0, 7, COL_TEXT_MUTED)
	hand_box_hbox.add_child(hand_name_lbl)
	
	var vertical_sep := ColorRect.new()
	vertical_sep.custom_minimum_size = Vector2(1, 16)
	vertical_sep.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vertical_sep.color = COL_BORDER_SLATE
	add_child(vertical_sep)

	# Hotbar
	var hb_caption := Label.new()
	hb_caption.text = "SAKU CEPAT:"
	_apply_font(hb_caption, 3, 9, COL_BORDER_GOLD)
	add_child(hb_caption)

	for i in range(HOTBAR_SLOTS):
		var hb_box := _create_hotbar_mini_box(i)
		hotbar_slots_ui.append(hb_box)
		add_child(hb_box)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(spacer)

	var btn_close := GameMenuButton.new()
	btn_close.text = "TUTUP TAS [ESC]"
	btn_close.set_dimensions(102, 24)
	btn_close.font_size_override = 9
	btn_close.set_variant(GameMenuButton.Variant.ACCENT)
	btn_close.pressed.connect(func(): close_requested.emit())
	add_child(btn_close)

func _create_hotbar_mini_box(hb_idx: int) -> PanelContainer:
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(62, 24)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.04, 0.05, 0.08, 1.0)
	st.set_border_width_all(1)
	st.border_color = COL_BORDER_SLATE
	box.add_theme_stylebox_override("panel", st)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 2)
	box.add_child(hbox)

	var num_lbl := Label.new()
	num_lbl.text = "[%d]" % (hb_idx + 1)
	_apply_font(num_lbl, 3, 8, COL_BORDER_GOLD)
	hbox.add_child(num_lbl)

	var icon_rect := TextureRect.new()
	icon_rect.name = "HbIcon"
	icon_rect.custom_minimum_size = Vector2(14, 14)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(icon_rect)

	var name_lbl := Label.new()
	name_lbl.name = "HbLabel"
	name_lbl.clip_text = true
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(name_lbl, 0, 7, COL_TEXT_MUTED)
	hbox.add_child(name_lbl)

	var click_btn := Button.new()
	click_btn.flat = true
	click_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	click_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	click_btn.pressed.connect(func(): hotbar_selected.emit(hb_idx))
	box.add_child(click_btn)

	return box

func refresh(inv_mgr: Node, equipped_id: String) -> void:
	if not inv_mgr: return

	# Tangan (Equipped)
	if equipped_id != "":
		var meta: Dictionary = inv_mgr.get_item_meta(equipped_id) if inv_mgr.has_method("get_item_meta") else {}
		var icon_path: String = meta.get("icon_path", "")
		hand_icon_rect.texture = load(icon_path) if ResourceLoader.exists(icon_path) else null
		hand_name_lbl.text = meta.get("name", "ITEM").left(6)
		_apply_font(hand_name_lbl, 1, 7, COL_WEIGHT_LIGHT)
	else:
		hand_icon_rect.texture = null
		hand_name_lbl.text = "KOSONG"
		_apply_font(hand_name_lbl, 0, 7, COL_TEXT_MUTED)

	# Hotbar
	for i in range(hotbar_slots_ui.size()):
		if i >= inv_mgr.hotbar.size(): break
		
		var box: PanelContainer = hotbar_slots_ui[i]
		var hbox: HBoxContainer = box.get_child(0)
		var ic: TextureRect = hbox.get_node("HbIcon")
		var lb: Label = hbox.get_node("HbLabel")
		var hb_data: Dictionary = inv_mgr.hotbar[i]

		if hb_data.has("id"):
			var meta: Dictionary = inv_mgr.get_item_meta(hb_data["id"])
			var icon_p: String = meta.get("icon_path", "")
			ic.texture = load(icon_p) if (icon_p != "" and ResourceLoader.exists(icon_p)) else null
			lb.text = meta.get("name", "ITEM").left(6)
			_apply_font(lb, 1, 7, COL_TEXT_WHITE)
		else:
			ic.texture = null
			lb.text = "---"
			_apply_font(lb, 0, 7, COL_TEXT_MUTED)

func _apply_font(lbl: Control, type: int, f_size: int, col: Color) -> void:
	var root_node = Engine.get_main_loop().root if Engine.get_main_loop() else null
	var font_mgr = root_node.get_node_or_null("FontManager") if root_node else null
	if font_mgr and font_mgr.has_method("apply"):
		font_mgr.apply(lbl, type, f_size, col)
	else:
		lbl.add_theme_font_size_override("font_size", f_size)
		lbl.add_theme_color_override("font_color", col)
