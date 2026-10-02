class_name InventoryItemDetail
extends PanelContainer

signal action_requested(action: String)

const COL_BG_CARD: Color = Color(0.08, 0.09, 0.14, 1.0)
const COL_BORDER_GOLD: Color = Color(0.95, 0.82, 0.25, 0.95)
const COL_BORDER_SLATE: Color = Color(0.24, 0.28, 0.38, 0.85)
const COL_TEXT_WHITE: Color = Color(0.94, 0.95, 0.98, 1.0)
const COL_TEXT_MUTED: Color = Color(0.50, 0.55, 0.66, 1.0)
const COL_WEIGHT_LIGHT: Color = Color(0.25, 0.88, 0.45, 1.0)

var preview_icon: TextureRect
var preview_fallback_lbl: Label
var detail_name_lbl: Label
var detail_meta_lbl: Label
var detail_desc_lbl: Label
var desc_scroll: ScrollContainer
var feedback_status_lbl: Label

var btn_use: GameMenuButton
var btn_equip: GameMenuButton
var btn_hotbar: GameMenuButton
var btn_drop: GameMenuButton

func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var st := StyleBoxFlat.new()
	st.bg_color = COL_BG_CARD
	st.set_border_width_all(1)
	st.border_color = COL_BORDER_SLATE
	add_theme_stylebox_override("panel", st)

	var right_margin := MarginContainer.new()
	right_margin.add_theme_constant_override("margin_left", 8)
	right_margin.add_theme_constant_override("margin_right", 8)
	right_margin.add_theme_constant_override("margin_top", 8)
	right_margin.add_theme_constant_override("margin_bottom", 8)
	add_child(right_margin)

	var right_vbox := VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 5)
	right_margin.add_child(right_vbox)

	_build_header(right_vbox)
	_build_description(right_vbox)
	_build_actions(right_vbox)

func _build_header(parent: VBoxContainer) -> void:
	var top_hbox := HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 8)
	parent.add_child(top_hbox)

	var icon_frame := PanelContainer.new()
	icon_frame.custom_minimum_size = Vector2(46, 46)
	icon_frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var icon_st := StyleBoxFlat.new()
	icon_st.bg_color = Color(0.04, 0.05, 0.08, 1.0)
	icon_st.set_border_width_all(1)
	icon_st.border_color = COL_BORDER_GOLD
	icon_st.content_margin_left = 4
	icon_st.content_margin_right = 4
	icon_st.content_margin_top = 4
	icon_st.content_margin_bottom = 4
	icon_frame.add_theme_stylebox_override("panel", icon_st)
	top_hbox.add_child(icon_frame)

	preview_icon = TextureRect.new()
	preview_icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_frame.add_child(preview_icon)

	preview_fallback_lbl = Label.new()
	preview_fallback_lbl.text = "--"
	preview_fallback_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_fallback_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_font(preview_fallback_lbl, 3, 11, COL_TEXT_MUTED)
	icon_frame.add_child(preview_fallback_lbl)

	var title_meta_vbox := VBoxContainer.new()
	title_meta_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_meta_vbox.add_theme_constant_override("separation", 2)
	top_hbox.add_child(title_meta_vbox)

	detail_name_lbl = Label.new()
	detail_name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_font(detail_name_lbl, 1, 9, COL_BORDER_GOLD)
	title_meta_vbox.add_child(detail_name_lbl)

	detail_meta_lbl = Label.new()
	_apply_font(detail_meta_lbl, 3, 8, COL_TEXT_MUTED)
	title_meta_vbox.add_child(detail_meta_lbl)

	feedback_status_lbl = Label.new()
	feedback_status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_status_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(feedback_status_lbl, 2, 8, COL_WEIGHT_LIGHT)
	title_meta_vbox.add_child(feedback_status_lbl)

func _build_description(parent: VBoxContainer) -> void:
	var desc_row := HBoxContainer.new()
	desc_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc_row.add_theme_constant_override("separation", 4)
	parent.add_child(desc_row)

	desc_scroll = ScrollContainer.new()
	desc_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	
	var vbar := desc_scroll.get_v_scroll_bar()
	vbar.custom_minimum_size.x = 4
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.04, 0.05, 0.08, 0.9)
	var grab := StyleBoxFlat.new()
	grab.bg_color = COL_BORDER_GOLD
	vbar.add_theme_stylebox_override("scroll", bg)
	vbar.add_theme_stylebox_override("grabber", grab)
	desc_row.add_child(desc_scroll)

	detail_desc_lbl = Label.new()
	detail_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(detail_desc_lbl, 0, 8, COL_TEXT_WHITE)
	desc_scroll.add_child(detail_desc_lbl)

	var nav_vbox := VBoxContainer.new()
	nav_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	desc_row.add_child(nav_vbox)

	var btn_up := GameMenuButton.new()
	btn_up.text = "▲"
	btn_up.set_dimensions(16, 20)
	btn_up.font_size_override = 7
	btn_up.set_variant(GameMenuButton.Variant.DEFAULT)
	btn_up.pressed.connect(func(): desc_scroll.scroll_vertical = maxi(0, desc_scroll.scroll_vertical - 20))
	nav_vbox.add_child(btn_up)

	var btn_down := GameMenuButton.new()
	btn_down.text = "▼"
	btn_down.set_dimensions(16, 20)
	btn_down.font_size_override = 7
	btn_down.set_variant(GameMenuButton.Variant.DEFAULT)
	btn_down.pressed.connect(func(): desc_scroll.scroll_vertical += 20)
	nav_vbox.add_child(btn_down)

func _build_actions(parent: VBoxContainer) -> void:
	var action_hbox := HBoxContainer.new()
	action_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	action_hbox.add_theme_constant_override("separation", 5)
	parent.add_child(action_hbox)

	btn_use = _make_btn("GUNAKAN", 56, GameMenuButton.Variant.ACCENT, "use")
	action_hbox.add_child(btn_use)

	btn_equip = _make_btn("PEGANG", 56, GameMenuButton.Variant.DEFAULT, "equip")
	action_hbox.add_child(btn_equip)

	btn_hotbar = _make_btn("KE SAKU", 70, GameMenuButton.Variant.DEFAULT, "hotbar")
	action_hbox.add_child(btn_hotbar)

	btn_drop = _make_btn("BUANG", 48, GameMenuButton.Variant.DANGER, "drop")
	action_hbox.add_child(btn_drop)

func _make_btn(txt: String, w: float, variant: GameMenuButton.Variant, act: String) -> GameMenuButton:
	var btn := GameMenuButton.new()
	btn.text = txt
	btn.set_dimensions(w, 22)
	btn.font_size_override = 8
	btn.set_variant(variant)
	btn.pressed.connect(func(): action_requested.emit(act))
	return btn

func refresh(inv_mgr: Node, selected_idx: int, equipped_id: String) -> void:
	if not inv_mgr: return
	
	var sel_slot: Dictionary = inv_mgr.inventory[selected_idx]
	if sel_slot.has("id"):
		var id_str: String = sel_slot["id"]
		var meta: Dictionary = inv_mgr.get_item_meta(id_str)
		detail_name_lbl.text = meta.get("name", "ITEM").to_upper()

		var item_type_int: int = meta.get("type", 0)
		var type_str: String = _get_type_label(item_type_int, inv_mgr)
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

		var in_hotbar: bool = false
		for hb in inv_mgr.hotbar:
			if hb.has("id") and hb["id"] == id_str:
				in_hotbar = true
				break
		btn_hotbar.text = "LEPAS SAKU" if in_hotbar else "KE SAKU"

		# TOOL = 0, CONSUMABLE = 1 (Tergantung mapping di InventoryManager)
		var can_equip: bool = (item_type_int == 0 or item_type_int == 1)
		btn_equip.disabled = not can_equip
		btn_equip.text = "LEPAS" if (equipped_id == id_str) else "PEGANG"

		btn_use.disabled = false
		btn_hotbar.disabled = false
		btn_drop.disabled = false
	else:
		detail_name_lbl.text = "SLOT #%d KOSONG" % (selected_idx + 1)
		detail_meta_lbl.text = "TIPE: -  |  BOBOT: 0.0 KG"
		detail_desc_lbl.text = "Tidak ada barang di slot ini."
		preview_icon.visible = false
		preview_fallback_lbl.visible = true
		preview_fallback_lbl.text = "--"

		btn_use.disabled = true
		btn_equip.disabled = true
		btn_hotbar.disabled = true
		btn_drop.disabled = true
		btn_equip.text = "PEGANG"
		btn_hotbar.text = "KE SAKU"

func set_feedback(msg: String) -> void:
	feedback_status_lbl.text = msg

func _get_type_label(t: int, inv_mgr: Node) -> String:
	if not inv_mgr or not ("ItemType" in inv_mgr): return "ALAT"
	var type_enum = inv_mgr.ItemType
	match t:
		type_enum.KEY: return "KUNCI"
		type_enum.CONSUMABLE: return "KONSUMSI"
		type_enum.DOCUMENT: return "DOKUMEN"
		_: return "ALAT"

func _apply_font(lbl: Control, type: int, f_size: int, col: Color) -> void:
	var root_node = Engine.get_main_loop().root if Engine.get_main_loop() else null
	var font_mgr = root_node.get_node_or_null("FontManager") if root_node else null
	if font_mgr and font_mgr.has_method("apply"):
		font_mgr.apply(lbl, type, f_size, col)
	else:
		lbl.add_theme_font_size_override("font_size", f_size)
		lbl.add_theme_color_override("font_color", col)
