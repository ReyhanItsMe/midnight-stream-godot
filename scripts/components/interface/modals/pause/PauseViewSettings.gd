class_name PauseViewSettings
extends VBoxContainer

signal back_requested

var bgm_pct: int = 20
var sfx_pct: int = 100
var screen_shake_on: bool = true
var flash_power_mode: int = 1

var row_bgm: Control
var row_sfx: Control
var row_shake: Control
var row_flash: Control

func _init() -> void:
	custom_minimum_size = Vector2(310, 0)
	add_theme_constant_override("separation", 0)

	_build_header("STREAM & AUDIO SETTINGS")

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 16)
	margin.add_child(body)
	add_child(margin)

	row_bgm = StepperSettingRow.new("BGM VOLUME", "20%")
	row_bgm.connect("value_decreased", func(): _step_bgm(-10))
	row_bgm.connect("value_increased", func(): _step_bgm(10))
	body.add_child(row_bgm)

	row_sfx = StepperSettingRow.new("SFX VOLUME", "100%")
	row_sfx.connect("value_decreased", func(): _step_sfx(-10))
	row_sfx.connect("value_increased", func(): _step_sfx(10))
	body.add_child(row_sfx)

	row_shake = StepperSettingRow.new("SCREEN SHAKE", "ON")
	row_shake.connect("value_decreased", _toggle_shake)
	row_shake.connect("value_increased", _toggle_shake)
	body.add_child(row_shake)

	row_flash = StepperSettingRow.new("FLASHLIGHT BEAM", "NORM")
	row_flash.connect("value_decreased", func(): _step_flash(-1))
	row_flash.connect("value_increased", func(): _step_flash(1))
	body.add_child(row_flash)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 4)
	body.add_child(spacer)

	var btn_back := GameMenuButton.new()
	btn_back.text = "< BACK TO PAUSE"
	btn_back.set_dimensions(196, 24)
	btn_back.font_size_override = 9
	btn_back.set_variant(GameMenuButton.Variant.DEFAULT)
	btn_back.pressed.connect(func(): back_requested.emit())
	body.add_child(btn_back)

func sync_and_refresh() -> void:
	var save_mgr: Node = get_node_or_null("/root/SaveManager")
	if save_mgr and save_mgr.get("current_data") and save_mgr.current_data.has("settings"):
		var s: Dictionary = save_mgr.current_data["settings"]
		var raw_bgm = s.get("bgm_volume", 0.2)
		var raw_sfx = s.get("sfx_volume", 1.0)
		var f_bgm: float = float(raw_bgm) if float(raw_bgm) <= 1.0 else float(raw_bgm) / 100.0
		var f_sfx: float = float(raw_sfx) if float(raw_sfx) <= 1.0 else float(raw_sfx) / 100.0
		bgm_pct = clampi(roundi(f_bgm * 10.0) * 10, 0, 100)
		sfx_pct = clampi(roundi(f_sfx * 10.0) * 10, 0, 100)
		screen_shake_on = bool(s.get("screen_shake_enabled", true))
	else:
		var bus_bgm_idx := AudioServer.get_bus_index("BGM")
		if bus_bgm_idx != -1:
			var lin := db_to_linear(AudioServer.get_bus_volume_db(bus_bgm_idx))
			bgm_pct = clampi(roundi(lin * 10.0) * 10, 0, 100)
		else:
			bgm_pct = 20
	_update_labels()

func _step_bgm(delta_pct: int) -> void:
	bgm_pct = clampi(bgm_pct + delta_pct, 0, 100)
	var bus_idx := AudioServer.get_bus_index("BGM")
	if bus_idx != -1:
		AudioServer.set_bus_mute(bus_idx, bgm_pct == 0)
		AudioServer.set_bus_volume_db(bus_idx, -80.0 if bgm_pct == 0 else linear_to_db(float(bgm_pct) / 100.0))

	_save_settings_val("bgm_volume", float(bgm_pct) / 100.0)
	_update_labels()

func _step_sfx(delta_pct: int) -> void:
	sfx_pct = clampi(sfx_pct + delta_pct, 0, 100)
	var bus_idx := AudioServer.get_bus_index("SFX")
	if bus_idx != -1:
		AudioServer.set_bus_mute(bus_idx, sfx_pct == 0)
		AudioServer.set_bus_volume_db(bus_idx, -80.0 if sfx_pct == 0 else linear_to_db(float(sfx_pct) / 100.0))

	var player_node := get_tree().current_scene.find_child("Player", true, false)
	if player_node and player_node.get("footstep_player"):
		var fp: AudioStreamPlayer = player_node.get("footstep_player")
		fp.volume_db = -80.0 if sfx_pct == 0 else linear_to_db(float(sfx_pct) / 100.0)

	_save_settings_val("sfx_volume", float(sfx_pct) / 100.0)
	_update_labels()

func _toggle_shake() -> void:
	screen_shake_on = not screen_shake_on
	_save_settings_val("screen_shake_enabled", screen_shake_on)
	_update_labels()

func _step_flash(delta_mode: int) -> void:
	flash_power_mode = posmod(flash_power_mode + delta_mode, 3)
	var energies: Array[float] = [0.85, 1.35, 1.85]
	var player_node := get_tree().current_scene.find_child("Player", true, false)
	if player_node and player_node.get("player_lighting"):
		var pl = player_node.get("player_lighting")
		if pl.get("cone_light"):
			pl.cone_light.energy = energies[flash_power_mode]
	_update_labels()

func _save_settings_val(key: String, val: Variant) -> void:
	var save_mgr: Node = get_node_or_null("/root/SaveManager")
	if save_mgr and save_mgr.get("current_data") and save_mgr.current_data.has("settings"):
		save_mgr.current_data["settings"][key] = val
		if save_mgr.has_method("save_settings"):
			save_mgr.save_settings()

func _update_labels() -> void:
	if row_bgm and row_bgm.has_method("set_value_text"):
		row_bgm.set_value_text("%d%%" % bgm_pct)
	if row_sfx and row_sfx.has_method("set_value_text"):
		row_sfx.set_value_text("%d%%" % sfx_pct)
	if row_shake and row_shake.has_method("set_value_text"):
		row_shake.set_value_text("ON" if screen_shake_on else "OFF")
	if row_flash and row_flash.has_method("set_value_text"):
		match flash_power_mode:
			0: row_flash.set_value_text("LOW")
			1: row_flash.set_value_text("NORM")
			2: row_flash.set_value_text("HIGH")

func _build_header(title_str: String) -> void:
	var header_box := PanelContainer.new()
	header_box.custom_minimum_size = Vector2(0, 26)
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.alpha(Palette.BG_SLOT, 1.0)
	style.border_width_bottom = 1
	style.border_color = Palette.alpha(Palette.BORDER_DARK, 0.8)
	header_box.add_theme_stylebox_override("panel", style)

	var lbl := Label.new()
	lbl.text = title_str
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var font_mgr: Node = Engine.get_main_loop().root.get_node_or_null("FontManager") if (Engine.get_main_loop() and Engine.get_main_loop().root) else null
	if font_mgr and font_mgr.has_method("apply"):
		font_mgr.apply(lbl, 1, 10, Palette.GOLD)
	else:
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", Palette.GOLD)
	header_box.add_child(lbl)
	add_child(header_box)
