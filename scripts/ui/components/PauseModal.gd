extends Control
class_name PauseModal

const VIEWPORT_RES: Vector2 = Vector2(640, 360)
const MAIN_MENU_PATH: String = "res://scenes/ui/screens/main_menu/MainMenu.tscn"
const MAX_SLOTS: int = 20

# Warna Palet Sesuai Screenshot
const COL_BG_DARK: Color = Color(0.05, 0.06, 0.09, 0.96)
const COL_HEADER_BG: Color = Color(0.09, 0.10, 0.16, 1.0)
const COL_GOLD: Color = Color(0.95, 0.82, 0.25, 1.0)
const COL_BORDER_GOLD: Color = Color(0.65, 0.55, 0.22, 0.85)
const COL_BORDER_SLATE: Color = Color(0.28, 0.31, 0.40, 0.9)
const COL_TEXT_WHITE: Color = Color(0.92, 0.94, 0.97, 1.0)
const COL_TEXT_MUTED: Color = Color(0.48, 0.52, 0.62, 1.0)

# Node Utama
var btn_pause_hud: GameMenuButton
var overlay_bg: ColorRect
var modal_wrapper: VBoxContainer
var card_panel: PanelContainer
var btn_floating_close: GameMenuButton

# 4 Sub-View
var view_main: VBoxContainer
var view_load: VBoxContainer
var view_settings: VBoxContainer
var view_warning: VBoxContainer

# State & Node Load Log
var selected_slot: int = 1
var lbl_slot_counter: Label
var load_scroll: ScrollContainer
var slot_list_vbox: VBoxContainer
var btn_action_load: GameMenuButton
var btn_action_delete: GameMenuButton

# State & Node Settings
var bgm_pct: int = 20
var sfx_pct: int = 100
var screen_shake_on: bool = true
var flash_power_mode: int = 1 # 0: LOW, 1: NORM, 2: HIGH

var lbl_val_bgm: Label
var lbl_val_sfx: Label
var lbl_val_shake: Label
var lbl_val_flash: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	position = Vector2.ZERO
	size = VIEWPORT_RES
	custom_minimum_size = VIEWPORT_RES
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_sync_initial_audio()
	_build_hud_pause_button()
	_build_modal_structure()
	_show_view("none")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if overlay_bg.visible:
			resume_game()
		else:
			open_pause_menu()
		get_viewport().set_input_as_handled()


# ==============================================================================
# 1. TOMBOL PAUSE HUD (TENGAH ATAS - DENGAN TEKS)
# ==============================================================================

func _build_hud_pause_button() -> void:
	btn_pause_hud = GameMenuButton.new()
	btn_pause_hud.text = "|| PAUSE"
	btn_pause_hud.set_dimensions(68, 22)
	btn_pause_hud.font_size_override = 9
	btn_pause_hud.set_variant(GameMenuButton.Variant.DEFAULT)
	
	btn_pause_hud.set_anchors_preset(Control.PRESET_CENTER_TOP)
	btn_pause_hud.grow_horizontal = Control.GROW_DIRECTION_BOTH
	btn_pause_hud.offset_top = 10
	btn_pause_hud.pressed.connect(open_pause_menu)
	add_child(btn_pause_hud)


# ==============================================================================
# 2. STRUKTUR MODAL UTAMA (SESUAI KONFIRMASI LOG & ARCHIVES)
# ==============================================================================

func _build_modal_structure() -> void:
	overlay_bg = ColorRect.new()
	overlay_bg.color = Color(0.01, 0.01, 0.02, 0.84)
	overlay_bg.position = Vector2.ZERO
	overlay_bg.size = VIEWPORT_RES
	overlay_bg.custom_minimum_size = VIEWPORT_RES
	overlay_bg.visible = false
	add_child(overlay_bg)

	var center := CenterContainer.new()
	center.position = Vector2.ZERO
	center.size = VIEWPORT_RES
	center.custom_minimum_size = VIEWPORT_RES
	overlay_bg.add_child(center)

	modal_wrapper = VBoxContainer.new()
	modal_wrapper.add_theme_constant_override("separation", 6)
	modal_wrapper.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(modal_wrapper)

	card_panel = PanelContainer.new()
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = COL_BG_DARK
	card_style.set_border_width_all(1)
	card_style.border_color = COL_BORDER_GOLD
	card_panel.add_theme_stylebox_override("panel", card_style)
	modal_wrapper.add_child(card_panel)

	var content_stack := MarginContainer.new()
	card_panel.add_child(content_stack)

	_build_view_main(content_stack)
	_build_view_load(content_stack)
	_build_view_settings(content_stack)
	_build_view_warning(content_stack)

	btn_floating_close = GameMenuButton.new()
	btn_floating_close.text = "X"
	btn_floating_close.set_dimensions(22, 20)
	btn_floating_close.font_size_override = 9
	btn_floating_close.set_variant(GameMenuButton.Variant.DANGER)
	btn_floating_close.pressed.connect(func():
		if view_main.visible:
			resume_game()
		else:
			_show_view("main")
	)
	modal_wrapper.add_child(btn_floating_close)


# ==============================================================================
# SUB-VIEW 1: PAUSE UTAMA (GAYA MAIN MENU)
# ==============================================================================

func _build_view_main(parent: Node) -> void:
	view_main = VBoxContainer.new()
	view_main.custom_minimum_size = Vector2(250, 0)
	view_main.add_theme_constant_override("separation", 0)
	parent.add_child(view_main)

	view_main.add_child(_create_modal_header("STREAM PAUSED // INTERMISSION"))

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	var body_margin := _wrap_with_padding(body, 18, 14, 18, 16)
	view_main.add_child(body_margin)

	var btn_resume := _make_game_btn("RESUME STREAM", 196, 24, GameMenuButton.Variant.DEFAULT)
	btn_resume.pressed.connect(resume_game)
	body.add_child(btn_resume)

	var btn_load := _make_game_btn("LOAD LOG", 196, 24, GameMenuButton.Variant.DEFAULT)
	btn_load.pressed.connect(func():
		_refresh_load_slots()
		_show_view("load")
	)
	body.add_child(btn_load)

	var btn_settings := _make_game_btn("SETTINGS", 196, 24, GameMenuButton.Variant.DEFAULT)
	btn_settings.pressed.connect(func():
		_sync_initial_audio()
		_refresh_settings_ui()
		_show_view("settings")
	)
	body.add_child(btn_settings)

	var btn_menu := _make_game_btn("BACK TO MENU", 196, 24, GameMenuButton.Variant.DANGER)
	btn_menu.pressed.connect(func(): _show_view("warning"))
	body.add_child(btn_menu)


# ==============================================================================
# SUB-VIEW 2: LOAD LOG (BROADCAST ARCHIVES // RECOVERY LOG)
# ==============================================================================

func _build_view_load(parent: Node) -> void:
	view_load = VBoxContainer.new()
	view_load.custom_minimum_size = Vector2(360, 0)
	view_load.add_theme_constant_override("separation", 0)
	parent.add_child(view_load)

	view_load.add_child(_create_modal_header("BROADCAST ARCHIVES // RECOVERY LOG"))

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	var body_margin := _wrap_with_padding(body, 16, 10, 16, 14)
	view_load.add_child(body_margin)

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
	_style_gold_scrollbar(load_scroll)
	list_hbox.add_child(load_scroll)

	slot_list_vbox = VBoxContainer.new()
	slot_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot_list_vbox.add_theme_constant_override("separation", 5)
	load_scroll.add_child(slot_list_vbox)

	var nav_vbox := VBoxContainer.new()
	nav_vbox.add_theme_constant_override("separation", 4)
	nav_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	list_hbox.add_child(nav_vbox)

	var btn_up := _make_game_btn("▲", 24, 24, GameMenuButton.Variant.DEFAULT)
	btn_up.font_size_override = 8
	btn_up.pressed.connect(func():
		load_scroll.scroll_vertical = max(0, load_scroll.scroll_vertical - 36)
	)
	nav_vbox.add_child(btn_up)

	var btn_down := _make_game_btn("▼", 24, 24, GameMenuButton.Variant.DEFAULT)
	btn_down.font_size_override = 8
	btn_down.pressed.connect(func():
		load_scroll.scroll_vertical += 36
	)
	nav_vbox.add_child(btn_down)

	var action_hbox := HBoxContainer.new()
	action_hbox.add_theme_constant_override("separation", 8)
	action_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_child(action_hbox)

	btn_action_load = _make_game_btn("LOAD LOG", 92, 22, GameMenuButton.Variant.DEFAULT)
	btn_action_load.font_size_override = 9
	btn_action_load.pressed.connect(_execute_load_selected_slot)
	action_hbox.add_child(btn_action_load)

	btn_action_delete = _make_game_btn("DELETE", 82, 22, GameMenuButton.Variant.DANGER)
	btn_action_delete.font_size_override = 9
	btn_action_delete.pressed.connect(_delete_selected_slot)
	action_hbox.add_child(btn_action_delete)

	var btn_back := _make_game_btn("< BACK", 76, 22, GameMenuButton.Variant.DEFAULT)
	btn_back.font_size_override = 9
	btn_back.pressed.connect(func(): _show_view("main"))
	action_hbox.add_child(btn_back)


# ==============================================================================
# SUB-VIEW 3: SETTINGS
# ==============================================================================

func _build_view_settings(parent: Node) -> void:
	view_settings = VBoxContainer.new()
	view_settings.custom_minimum_size = Vector2(310, 0)
	view_settings.add_theme_constant_override("separation", 0)
	parent.add_child(view_settings)

	view_settings.add_child(_create_modal_header("STREAM & AUDIO SETTINGS"))

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	var body_margin := _wrap_with_padding(body, 20, 14, 20, 16)
	view_settings.add_child(body_margin)

	var r_bgm := _create_stepper_row("BGM VOLUME", func(): _step_bgm(-10), func(): _step_bgm(10))
	lbl_val_bgm = r_bgm["label"]
	body.add_child(r_bgm["node"])

	var r_sfx := _create_stepper_row("SFX VOLUME", func(): _step_sfx(-10), func(): _step_sfx(10))
	lbl_val_sfx = r_sfx["label"]
	body.add_child(r_sfx["node"])

	var r_shake := _create_stepper_row("SCREEN SHAKE", _toggle_shake, _toggle_shake)
	lbl_val_shake = r_shake["label"]
	body.add_child(r_shake["node"])

	var r_flash := _create_stepper_row("FLASHLIGHT BEAM", func(): _step_flash(-1), func(): _step_flash(1))
	lbl_val_flash = r_flash["label"]
	body.add_child(r_flash["node"])

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 4)
	body.add_child(spacer)

	var btn_back := _make_game_btn("< BACK TO PAUSE", 196, 24, GameMenuButton.Variant.DEFAULT)
	btn_back.pressed.connect(func(): _show_view("main"))
	body.add_child(btn_back)


func _create_stepper_row(title_text: String, on_minus: Callable, on_plus: Callable) -> Dictionary:
	var hbox := HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(250, 22)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var lbl_title := _make_label(title_text, 9, COL_TEXT_WHITE)
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(lbl_title)

	var controls_hbox := HBoxContainer.new()
	controls_hbox.add_theme_constant_override("separation", 6)
	hbox.add_child(controls_hbox)

	var btn_min := _make_game_btn("-", 22, 20, GameMenuButton.Variant.ACCENT)
	btn_min.font_size_override = 9
	btn_min.pressed.connect(on_minus)
	controls_hbox.add_child(btn_min)

	var lbl_val := _make_label("100%", 9, COL_GOLD)
	lbl_val.custom_minimum_size = Vector2(44, 20)
	lbl_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_val.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	controls_hbox.add_child(lbl_val)

	var btn_plus := _make_game_btn("+", 22, 20, GameMenuButton.Variant.ACCENT)
	btn_plus.font_size_override = 9
	btn_plus.pressed.connect(on_plus)
	controls_hbox.add_child(btn_plus)

	return {"node": hbox, "label": lbl_val}


# ==============================================================================
# SUB-VIEW 4: WARNING BACK TO MENU
# ==============================================================================

func _build_view_warning(parent: Node) -> void:
	view_warning = VBoxContainer.new()
	view_warning.custom_minimum_size = Vector2(280, 0)
	view_warning.add_theme_constant_override("separation", 0)
	parent.add_child(view_warning)

	view_warning.add_child(_create_modal_header("KONFIRMASI KELUAR STREAM"))

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	var body_margin := _wrap_with_padding(body, 18, 12, 18, 14)
	view_warning.add_child(body_margin)

	var msg1 := _make_label("Yakin ingin mengakhiri sesi dan kembali ke Studio?", 9, COL_TEXT_WHITE)
	msg1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(msg1)

	var msg2 := _make_label(
		"REKAMAN TERAKHIR HANYA DISIMPAN DI TERMINAL REKAMAN (SAVE POINT) TERAKHIR KAMU.",
		8,
		COL_GOLD
	)
	msg2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg2.custom_minimum_size = Vector2(240, 28)
	body.add_child(msg2)

	var btn_confirm := _make_game_btn("YA, KEMBALI KE STUDIO", 150, 22, GameMenuButton.Variant.ACCENT)
	btn_confirm.font_size_override = 9
	btn_confirm.pressed.connect(_confirm_back_to_menu)
	body.add_child(btn_confirm)


# ==============================================================================
# LOGIKA DAFTAR SLOT
# ==============================================================================

func _refresh_load_slots() -> void:
	for child in slot_list_vbox.get_children():
		child.queue_free()

	for slot_idx in range(1, MAX_SLOTS + 1):
		var info := _get_slot_data(slot_idx)
		var exists: bool = info.get("exists", false)
		var is_sel: bool = (slot_idx == selected_slot)

		var row_panel := PanelContainer.new()
		row_panel.custom_minimum_size = Vector2(272, 32)

		var row_style := StyleBoxFlat.new()
		row_style.bg_color = Color(0.08, 0.09, 0.14, 0.95) if exists else Color(0.05, 0.06, 0.09, 0.7)
		row_style.set_border_width_all(1)
		if is_sel:
			row_style.border_color = COL_GOLD
		else:
			row_style.border_color = COL_BORDER_SLATE if exists else Color(0.18, 0.20, 0.26, 0.6)
		row_panel.add_theme_stylebox_override("panel", row_style)

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 5)
		margin.add_theme_constant_override("margin_right", 8)
		margin.add_theme_constant_override("margin_top", 4)
		margin.add_theme_constant_override("margin_bottom", 4)
		row_panel.add_child(margin)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		margin.add_child(hbox)

		var badge := PanelContainer.new()
		badge.custom_minimum_size = Vector2(32, 22)
		var badge_style := StyleBoxFlat.new()
		badge_style.bg_color = Color(0.10, 0.11, 0.16, 1.0)
		badge_style.set_border_width_all(1)
		badge_style.border_color = COL_GOLD if (exists and is_sel) else COL_BORDER_SLATE
		badge.add_theme_stylebox_override("panel", badge_style)

		var lbl_num := _make_label("#%d" % slot_idx, 8, COL_GOLD if exists else COL_TEXT_MUTED)
		lbl_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.add_child(lbl_num)
		hbox.add_child(badge)

		var summary_str: String = "EMPTY ARCHIVE SLOT"
		if exists:
			var loc: String = info.get("location", "CHAPTER 1 // SANATORIUM DAHLIA")
			var t_str: String = info.get("timestamp", "")
			summary_str = "%s (%s)" % [loc, t_str] if t_str != "" else loc

		var lbl_desc := _make_label(summary_str, 8, COL_TEXT_WHITE if exists else COL_TEXT_MUTED)
		lbl_desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_desc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_desc.clip_text = true
		hbox.add_child(lbl_desc)

		var click_btn := Button.new()
		click_btn.flat = true
		click_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		click_btn.pressed.connect(func():
			selected_slot = slot_idx
			_refresh_load_slots()
		)
		row_panel.add_child(click_btn)

		slot_list_vbox.add_child(row_panel)

	lbl_slot_counter.text = "SLOT %02d / %02d" % [selected_slot, MAX_SLOTS]
	var sel_info := _get_slot_data(selected_slot)
	var sel_exists: bool = sel_info.get("exists", false)
	btn_action_load.disabled = not sel_exists
	btn_action_delete.disabled = not sel_exists
	btn_action_load.modulate.a = 1.0 if sel_exists else 0.45
	btn_action_delete.modulate.a = 1.0 if sel_exists else 0.45


func _get_slot_data(slot_idx: int) -> Dictionary:
	if SaveManager and SaveManager.has_method("get_slot_info"):
		return SaveManager.get_slot_info(slot_idx)

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


func _execute_load_selected_slot() -> void:
	var info := _get_slot_data(selected_slot)
	if not info.get("exists", false):
		return

	get_tree().paused = false
	overlay_bg.visible = false
	btn_pause_hud.visible = true

	if SaveManager and SaveManager.has_method("load_game"):
		SaveManager.load_game(selected_slot)
		
		var target_scene: String = ""
		if SaveManager.has_method("get_saved_scene_path"):
			target_scene = SaveManager.get_saved_scene_path()
		else:
			target_scene = SaveManager.current_data.get("meta", {}).get("scene_path", "")

		if target_scene != "" and ResourceLoader.exists(target_scene):
			TransitionManager.change_scene_with_loading(target_scene)
		else:
			TransitionManager.change_scene_with_loading(get_tree().current_scene.scene_file_path)
	else:
		get_tree().reload_current_scene()


func _delete_selected_slot() -> void:
	if SaveManager and SaveManager.has_method("delete_slot"):
		SaveManager.delete_slot(selected_slot)
	else:
		var path := "user://save_slot_%d.json" % selected_slot
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	_refresh_load_slots()


# ==============================================================================
# LOGIKA SETTINGS STEPPER (SINKRONISASI BGM & SFX RESMI)
# ==============================================================================

func _sync_initial_audio() -> void:
	# Prioritaskan pembacaan dari SaveManager settings agar nilai persis
	if SaveManager and SaveManager.current_data.has("settings"):
		var s: Dictionary = SaveManager.current_data["settings"]
		var raw_bgm = s.get("bgm_volume", 0.2)
		var raw_sfx = s.get("sfx_volume", 1.0)
		
		var f_bgm: float = float(raw_bgm) if float(raw_bgm) <= 1.0 else float(raw_bgm) / 100.0
		var f_sfx: float = float(raw_sfx) if float(raw_sfx) <= 1.0 else float(raw_sfx) / 100.0
		
		bgm_pct = clampi(roundi(f_bgm * 10.0) * 10, 0, 100)
		sfx_pct = clampi(roundi(f_sfx * 10.0) * 10, 0, 100)
		screen_shake_on = bool(s.get("screen_shake_enabled", true))
	else:
		# Fallback ke bus BGM AudioServer (BUKAN index 0 Master)
		var bus_bgm_idx := AudioServer.get_bus_index("BGM")
		if bus_bgm_idx != -1:
			var lin := db_to_linear(AudioServer.get_bus_volume_db(bus_bgm_idx))
			bgm_pct = clampi(roundi(lin * 10.0) * 10, 0, 100)
		else:
			bgm_pct = 20


func _step_bgm(delta_pct: int) -> void:
	bgm_pct = clampi(bgm_pct + delta_pct, 0, 100)
	var bus_idx := AudioServer.get_bus_index("BGM")
	if bus_idx != -1:
		if bgm_pct == 0:
			AudioServer.set_bus_mute(bus_idx, true)
			AudioServer.set_bus_volume_db(bus_idx, -80.0)
		else:
			AudioServer.set_bus_mute(bus_idx, false)
			AudioServer.set_bus_volume_db(bus_idx, linear_to_db(float(bgm_pct) / 100.0))

	# Simpan perubahan volume ke SaveManager
	if SaveManager and SaveManager.current_data.has("settings"):
		SaveManager.current_data["settings"]["bgm_volume"] = float(bgm_pct) / 100.0
		SaveManager.save_settings()

	_refresh_settings_ui()


func _step_sfx(delta_pct: int) -> void:
	sfx_pct = clampi(sfx_pct + delta_pct, 0, 100)
	var bus_idx := AudioServer.get_bus_index("SFX")
	if bus_idx != -1:
		if sfx_pct == 0:
			AudioServer.set_bus_mute(bus_idx, true)
			AudioServer.set_bus_volume_db(bus_idx, -80.0)
		else:
			AudioServer.set_bus_mute(bus_idx, false)
			AudioServer.set_bus_volume_db(bus_idx, linear_to_db(float(sfx_pct) / 100.0))

	var player_node := get_tree().current_scene.find_child("Player", true, false)
	if player_node and player_node.get("footstep_player"):
		var fp: AudioStreamPlayer = player_node.get("footstep_player")
		fp.volume_db = -80.0 if sfx_pct == 0 else linear_to_db(float(sfx_pct) / 100.0)

	# Simpan perubahan volume ke SaveManager
	if SaveManager and SaveManager.current_data.has("settings"):
		SaveManager.current_data["settings"]["sfx_volume"] = float(sfx_pct) / 100.0
		SaveManager.save_settings()

	_refresh_settings_ui()


func _toggle_shake() -> void:
	screen_shake_on = not screen_shake_on
	if SaveManager and SaveManager.current_data.has("settings"):
		SaveManager.current_data["settings"]["screen_shake_enabled"] = screen_shake_on
		SaveManager.save_settings()
	_refresh_settings_ui()


func _step_flash(delta_mode: int) -> void:
	flash_power_mode = posmod(flash_power_mode + delta_mode, 3)
	var energies: Array[float] = [0.85, 1.35, 1.85]
	var player_node := get_tree().current_scene.find_child("Player", true, false)
	if player_node and player_node.get("player_lighting"):
		var pl = player_node.get("player_lighting")
		if pl.get("cone_light"):
			pl.cone_light.energy = energies[flash_power_mode]
	_refresh_settings_ui()


func _refresh_settings_ui() -> void:
	if lbl_val_bgm:
		lbl_val_bgm.text = "%d%%" % bgm_pct
	if lbl_val_sfx:
		lbl_val_sfx.text = "%d%%" % sfx_pct
	if lbl_val_shake:
		lbl_val_shake.text = "ON" if screen_shake_on else "OFF"
	if lbl_val_flash:
		match flash_power_mode:
			0: lbl_val_flash.text = "LOW"
			1: lbl_val_flash.text = "NORM"
			2: lbl_val_flash.text = "HIGH"


# ==============================================================================
# NAVIGASI PAUSE & KELUAR
# ==============================================================================

func open_pause_menu() -> void:
	get_tree().paused = true
	Player.joystick_vector = Vector2.ZERO
	Player.is_sprint_pressed = false
	btn_pause_hud.visible = false
	overlay_bg.visible = true
	_show_view("main")


func resume_game() -> void:
	overlay_bg.visible = false
	btn_pause_hud.visible = true
	get_tree().paused = false


func _show_view(view_name: String) -> void:
	view_main.visible = (view_name == "main")
	view_load.visible = (view_name == "load")
	view_settings.visible = (view_name == "settings")
	view_warning.visible = (view_name == "warning")


func _confirm_back_to_menu() -> void:
	get_tree().paused = false
	var fade_canvas := get_tree().root.get_node_or_null("FadeCanvas")
	if fade_canvas:
		fade_canvas.queue_free()

	if TransitionManager and TransitionManager.has_method("change_scene"):
		TransitionManager.change_scene(MAIN_MENU_PATH)
	else:
		get_tree().change_scene_to_file(MAIN_MENU_PATH)


# ==============================================================================
# HELPER UI BUILDERS (DENGAN FONTMANAGER & GAMEMENUBUTTON)
# ==============================================================================

func _create_modal_header(title_str: String) -> PanelContainer:
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
	return header_box


func _wrap_with_padding(child_node: Control, l: int, t: int, r: int, b: int) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", l)
	m.add_theme_constant_override("margin_top", t)
	m.add_theme_constant_override("margin_right", r)
	m.add_theme_constant_override("margin_bottom", b)
	m.add_child(child_node)
	return m


func _make_game_btn(txt: String, w: float, h: float, variant_type: GameMenuButton.Variant) -> GameMenuButton:
	var btn := GameMenuButton.new()
	btn.text = txt
	btn.set_dimensions(w, h)
	btn.font_size_override = 9
	btn.set_variant(variant_type)
	return btn


func _make_label(txt: String, f_size: int, col: Color) -> Label:
	var lbl := Label.new()
	lbl.text = txt
	if Engine.has_singleton("FontManager") or get_node_or_null("/root/FontManager") != null:
		FontManager.apply(lbl, FontManager.Type.BODY_BOLD, f_size, col)
	else:
		lbl.add_theme_font_size_override("font_size", f_size)
		lbl.add_theme_color_override("font_color", col)
	return lbl


func _style_gold_scrollbar(scroll: ScrollContainer) -> void:
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
