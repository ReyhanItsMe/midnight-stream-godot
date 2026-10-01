class_name PauseViewLoad
extends VBoxContainer

signal back_requested
signal load_executed

const MAX_SLOTS: int = 20
const COL_HEADER_BG: Color = Color(0.09, 0.10, 0.16, 1.0)
const COL_GOLD: Color = Color(0.95, 0.82, 0.25, 1.0)
const COL_BORDER_GOLD: Color = Color(0.65, 0.55, 0.22, 0.85)
const COL_BORDER_SLATE: Color = Color(0.28, 0.31, 0.40, 0.9)
const COL_TEXT_WHITE: Color = Color(0.92, 0.94, 0.97, 1.0)
const COL_TEXT_MUTED: Color = Color(0.48, 0.52, 0.62, 1.0)

var selected_slot: int = 1
var lbl_slot_counter: Label
var load_scroll: ScrollContainer
var slot_list_vbox: VBoxContainer
var btn_action_load: GameMenuButton
var btn_action_delete: GameMenuButton

func _init() -> void:
	custom_minimum_size = Vector2(360, 0)
	add_theme_constant_override("separation", 0)

	_build_header("BROADCAST ARCHIVES // RECOVERY LOG")

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	margin.add_child(body)
	add_child(margin)

	lbl_slot_counter = _make_label("SLOT 01 / %02d" % MAX_SLOTS, 8, COL_TEXT_MUTED)
	lbl_slot_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(lbl_slot_counter)

	var list_hbox := HBoxContainer.new()
	list_hbox.add_theme_constant_override("separation", 6)
	list_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_child(list_hbox)

	load_scroll = ScrollContainer.new()
	load_scroll.custom_minimum_size = Vector2(288, 74)
	load_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	load_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	_style_scrollbar(load_scroll)
	list_hbox.add_child(load_scroll)

	slot_list_vbox = VBoxContainer.new()
	slot_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot_list_vbox.add_theme_constant_override("separation", 5)
	load_scroll.add_child(slot_list_vbox)

	var nav_vbox := VBoxContainer.new()
	nav_vbox.add_theme_constant_override("separation", 4)
	nav_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	list_hbox.add_child(nav_vbox)

	var btn_up := _make_btn("▲", 24, 24, GameMenuButton.Variant.DEFAULT)
	btn_up.font_size_override = 8
	btn_up.pressed.connect(func(): load_scroll.scroll_vertical = max(0, load_scroll.scroll_vertical - 36))
	nav_vbox.add_child(btn_up)

	var btn_down := _make_btn("▼", 24, 24, GameMenuButton.Variant.DEFAULT)
	btn_down.font_size_override = 8
	btn_down.pressed.connect(func(): load_scroll.scroll_vertical += 36)
	nav_vbox.add_child(btn_down)

	var action_hbox := HBoxContainer.new()
	action_hbox.add_theme_constant_override("separation", 8)
	action_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_child(action_hbox)

	btn_action_load = _make_btn("LOAD LOG", 92, 22, GameMenuButton.Variant.DEFAULT)
	btn_action_load.pressed.connect(_on_load_pressed)
	action_hbox.add_child(btn_action_load)

	btn_action_delete = _make_btn("DELETE", 82, 22, GameMenuButton.Variant.DANGER)
	btn_action_delete.pressed.connect(_on_delete_pressed)
	action_hbox.add_child(btn_action_delete)

	var btn_back := _make_btn("< BACK", 76, 22, GameMenuButton.Variant.DEFAULT)
	btn_back.pressed.connect(func(): back_requested.emit())
	action_hbox.add_child(btn_back)

func refresh_slots() -> void:
	for c in slot_list_vbox.get_children():
		c.queue_free()

	for slot_idx in range(1, MAX_SLOTS + 1):
		var info := _get_slot_data(slot_idx)
		var exists: bool = info.get("exists", false)
		var is_sel: bool = (slot_idx == selected_slot)

		var row := PanelContainer.new()
		row.custom_minimum_size = Vector2(272, 32)
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0.08, 0.09, 0.14, 0.95) if exists else Color(0.05, 0.06, 0.09, 0.7)
		st.set_border_width_all(1)
		st.border_color = COL_GOLD if is_sel else (COL_BORDER_SLATE if exists else Color(0.18, 0.20, 0.26, 0.6))
		row.add_theme_stylebox_override("panel", st)

		var m := MarginContainer.new()
		m.add_theme_constant_override("margin_left", 5)
		m.add_theme_constant_override("margin_right", 8)
		m.add_theme_constant_override("margin_top", 4)
		m.add_theme_constant_override("margin_bottom", 4)
		row.add_child(m)

		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 8)
		m.add_child(hb)

		var badge := PanelContainer.new()
		badge.custom_minimum_size = Vector2(32, 22)
		var b_st := StyleBoxFlat.new()
		b_st.bg_color = Color(0.10, 0.11, 0.16, 1.0)
		b_st.set_border_width_all(1)
		b_st.border_color = COL_GOLD if (exists and is_sel) else COL_BORDER_SLATE
		badge.add_theme_stylebox_override("panel", b_st)

		var lbl_n := _make_label("#%d" % slot_idx, 8, COL_GOLD if exists else COL_TEXT_MUTED)
		lbl_n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_n.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.add_child(lbl_n)
		hb.add_child(badge)

		var summary_str: String = "EMPTY ARCHIVE SLOT"
		if exists:
			var loc: String = info.get("location", "CHAPTER 1 // SANATORIUM DAHLIA")
			var t_str: String = info.get("timestamp", "")
			summary_str = "%s (%s)" % [loc, t_str] if t_str != "" else loc

		var lbl_d := _make_label(summary_str, 8, COL_TEXT_WHITE if exists else COL_TEXT_MUTED)
		lbl_d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_d.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_d.clip_text = true
		hb.add_child(lbl_d)

		var click_btn := Button.new()
		click_btn.flat = true
		click_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		click_btn.pressed.connect(func():
			selected_slot = slot_idx
			refresh_slots()
		)
		row.add_child(click_btn)
		slot_list_vbox.add_child(row)

	lbl_slot_counter.text = "SLOT %02d / %02d" % [selected_slot, MAX_SLOTS]
	var sel_info := _get_slot_data(selected_slot)
	var sel_exists: bool = sel_info.get("exists", false)
	btn_action_load.disabled = not sel_exists
	btn_action_delete.disabled = not sel_exists
	btn_action_load.modulate.a = 1.0 if sel_exists else 0.45
	btn_action_delete.modulate.a = 1.0 if sel_exists else 0.45

func _get_slot_data(slot_idx: int) -> Dictionary:
	var save_mgr: Node = get_node_or_null("/root/SaveManager")
	if save_mgr and save_mgr.has_method("get_slot_info"):
		return save_mgr.get_slot_info(slot_idx)

	var path := "user://save_slot_%d.json" % slot_idx
	if FileAccess.file_exists(path):
		var f := FileAccess.open(path, FileAccess.READ)
		if f:
			var data = JSON.parse_string(f.get_as_text())
			if typeof(data) == TYPE_DICTIONARY:
				return {
					"exists": true,
					"location": data.get("station_name", data.get("chapter", "CHAPTER 1 // SANATORIUM DAHLIA")),
					"timestamp": data.get("timestamp", "")
				}
	return {"exists": false}

func _on_load_pressed() -> void:
	var info := _get_slot_data(selected_slot)
	if not info.get("exists", false):
		return

	load_executed.emit()
	var save_mgr: Node = get_node_or_null("/root/SaveManager")
	var trans_mgr: Node = get_node_or_null("/root/TransitionManager")

	if save_mgr and save_mgr.has_method("load_game"):
		save_mgr.load_game(selected_slot)
		var target_scene: String = save_mgr.get_saved_scene_path() if save_mgr.has_method("get_saved_scene_path") else save_mgr.current_data.get("meta", {}).get("scene_path", "")

		if target_scene != "" and ResourceLoader.exists(target_scene) and trans_mgr:
			trans_mgr.change_scene_with_loading(target_scene)
		elif trans_mgr:
			trans_mgr.change_scene_with_loading(get_tree().current_scene.scene_file_path)
	else:
		get_tree().reload_current_scene()

func _on_delete_pressed() -> void:
	var save_mgr: Node = get_node_or_null("/root/SaveManager")
	if save_mgr and save_mgr.has_method("delete_slot"):
		save_mgr.delete_slot(selected_slot)
	else:
		var path := "user://save_slot_%d.json" % selected_slot
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	refresh_slots()

func _style_scrollbar(scroll: ScrollContainer) -> void:
	var vbar := scroll.get_v_scroll_bar()
	if not vbar:
		return
	vbar.custom_minimum_size.x = 4
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = COL_GOLD
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.12, 0.14, 0.20, 0.9)
	vbar.add_theme_stylebox_override("scroll", track)
	vbar.add_theme_stylebox_override("grabber", grabber)
	vbar.add_theme_stylebox_override("grabber_highlight", grabber)
	vbar.add_theme_stylebox_override("grabber_pressed", grabber)

func _make_btn(txt: String, w: float, h: float, variant: GameMenuButton.Variant) -> GameMenuButton:
	var btn := GameMenuButton.new()
	btn.text = txt
	btn.set_dimensions(w, h)
	btn.font_size_override = 9
	btn.set_variant(variant)
	return btn

func _make_label(txt: String, f_size: int, col: Color) -> Label:
	var lbl := Label.new()
	lbl.text = txt
	var font_mgr: Node = Engine.get_main_loop().root.get_node_or_null("FontManager") if (Engine.get_main_loop() and Engine.get_main_loop().root) else null
	if font_mgr and font_mgr.has_method("apply"):
		font_mgr.apply(lbl, font_mgr.Type.BODY_BOLD, f_size, col)
	else:
		lbl.add_theme_font_size_override("font_size", f_size)
		lbl.add_theme_color_override("font_color", col)
	return lbl

func _build_header(title_str: String) -> void:
	var header_box := PanelContainer.new()
	header_box.custom_minimum_size = Vector2(0, 26)
	var style := StyleBoxFlat.new()
	style.bg_color = COL_HEADER_BG
	style.border_width_bottom = 1
	style.border_color = Color(0.20, 0.22, 0.30, 1.0)
	header_box.add_theme_stylebox_override("panel", style)

	var lbl := _make_label(title_str, 10, COL_GOLD)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header_box.add_child(lbl)
	add_child(header_box)
