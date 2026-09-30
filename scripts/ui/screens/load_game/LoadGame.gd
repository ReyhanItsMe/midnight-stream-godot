extends Control

# --- RESOURCE PATHS ---
const BG_PATH: String = "res://assets/ui/backgrounds/load-game/background-load-game.png"
const BG_FALLBACK_PATH: String = "res://assets/ui/backgrounds/setting/background-setting.png"
const MENU_BUTTON_SCENE: PackedScene = preload("res://scenes/ui/components/MenuButton.tscn")
const INFO_MODAL_SCENE: PackedScene = preload("res://scenes/ui/components/InfoModal.tscn")

# --- NAVIGATION PATHS ---
const BACK_SCENE_PATH: String = "res://scenes/ui/screens/main_menu/MainMenu.tscn"

# --- UI TEXTS ---
const TEXT_HEADER: String = "BROADCAST ARCHIVES // RECOVERY LOG"
const TEXT_BTN_LOAD: String = "LOAD LOG"
const TEXT_BTN_DELETE: String = "DELETE"
const TEXT_BTN_BACK: String = "< BACK"

# --- COLORS ---
const COLOR_GOLD: Color = Color(0.95, 0.82, 0.25)
const COLOR_WHITE: Color = Color(0.92, 0.94, 0.96)
const COLOR_DIM_TEXT: Color = Color(0.42, 0.46, 0.54)
const COLOR_CARD_BG_ACTIVE: Color = Color(0.06, 0.07, 0.11, 0.94)
const COLOR_CARD_BG_IDLE: Color = Color(0.05, 0.06, 0.09, 0.75)
const COLOR_BORDER_IDLE: Color = Color(0.22, 0.25, 0.32, 0.8)
const COLOR_SCROLL_TRACK: Color = Color(0.12, 0.14, 0.18, 0.9)

# --- CONSTANTS & DIMENSIONS ---
const MAX_SLOTS: int = 20
const SCROLL_TRACK_HEIGHT: float = 96.0
const SCROLL_THUMB_HEIGHT: float = 14.0
const CARDS_CONTAINER_WIDTH: float = 280.0
const FADE_DURATION: float = 0.35
const SLOT_FADE_TIME: float = 0.16

var selected_slot: int = 1
var slot_tween: Tween
var thumb_tween: Tween

var lbl_slot_counter: Label
var scroll_thumb: ColorRect
var slot_cards: Array[Dictionary] = []
var info_modal: InfoModal

func _ready() -> void:
	AudioManager.play_menu_bgm()

	# 1. Background
	var bg := TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	if ResourceLoader.exists(BG_PATH):
		bg.texture = load(BG_PATH)
	elif ResourceLoader.exists(BG_FALLBACK_PATH):
		bg.texture = load(BG_FALLBACK_PATH)
	add_child(bg)

	# 2. Area Kanan
	var right_area := CenterContainer.new()
	right_area.anchor_left = 0.23
	right_area.anchor_top = 0.0
	right_area.anchor_right = 1.0
	right_area.anchor_bottom = 1.0
	add_child(right_area)

	var main_vbox := VBoxContainer.new()
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_theme_constant_override("separation", 6)
	right_area.add_child(main_vbox)

	# Header Judul
	var header_lbl := Label.new()
	header_lbl.text = TEXT_HEADER
	header_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontManager.apply(header_lbl, FontManager.Type.TITLE, 14, COLOR_GOLD)
	main_vbox.add_child(header_lbl)

	# Indikator Slot Counter (SLOT 01 / 20)
	lbl_slot_counter = Label.new()
	lbl_slot_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontManager.apply(lbl_slot_counter, FontManager.Type.DIGITAL, 11, COLOR_WHITE)
	main_vbox.add_child(lbl_slot_counter)

	var top_spacer := Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 4)
	main_vbox.add_child(top_spacer)

	# 3. Area Tengah: Slot Tetap + Scrollbar & Tombol Panah Statis di Kanan
	var middle_hbox := HBoxContainer.new()
	middle_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	middle_hbox.add_theme_constant_override("separation", 10)
	main_vbox.add_child(middle_hbox)

	var cards_vbox := VBoxContainer.new()
	cards_vbox.custom_minimum_size = Vector2(CARDS_CONTAINER_WIDTH, 110)
	cards_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_vbox.add_theme_constant_override("separation", 6)
	middle_hbox.add_child(cards_vbox)

	slot_cards.append(_create_slot_card(cards_vbox, false))
	slot_cards.append(_create_slot_card(cards_vbox, true))
	slot_cards.append(_create_slot_card(cards_vbox, false))

	# Scrollbar Track
	var scroll_track := ColorRect.new()
	scroll_track.custom_minimum_size = Vector2(4, SCROLL_TRACK_HEIGHT)
	scroll_track.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	scroll_track.color = COLOR_SCROLL_TRACK
	middle_hbox.add_child(scroll_track)

	scroll_thumb = ColorRect.new()
	scroll_thumb.size = Vector2(4, SCROLL_THUMB_HEIGHT)
	scroll_thumb.color = COLOR_GOLD
	scroll_track.add_child(scroll_thumb)

	# Tombol Panah
	var nav_vbox := VBoxContainer.new()
	nav_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	nav_vbox.add_theme_constant_override("separation", 8)
	middle_hbox.add_child(nav_vbox)

	var btn_up: GameMenuButton = MENU_BUTTON_SCENE.instantiate()
	btn_up.text = "▲"
	btn_up.set_dimensions(28, 28)
	btn_up.pressed.connect(func(): _scroll_slot(-1))
	nav_vbox.add_child(btn_up)

	var btn_down: GameMenuButton = MENU_BUTTON_SCENE.instantiate()
	btn_down.text = "▼"
	btn_down.set_dimensions(28, 28)
	btn_down.pressed.connect(func(): _scroll_slot(1))
	nav_vbox.add_child(btn_down)

	var bottom_spacer := Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 8)
	main_vbox.add_child(bottom_spacer)

	# 4. Tombol Aksi Bawah
	var action_hbox := HBoxContainer.new()
	action_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	action_hbox.add_theme_constant_override("separation", 10)
	main_vbox.add_child(action_hbox)

	var btn_load: GameMenuButton = MENU_BUTTON_SCENE.instantiate()
	btn_load.text = TEXT_BTN_LOAD
	btn_load.set_dimensions(96, 24)
	btn_load.pressed.connect(_on_load_pressed)
	action_hbox.add_child(btn_load)

	var btn_delete: GameMenuButton = MENU_BUTTON_SCENE.instantiate()
	btn_delete.text = TEXT_BTN_DELETE
	btn_delete.set_dimensions(84, 24)
	btn_delete.set_variant(GameMenuButton.Variant.DANGER)
	btn_delete.pressed.connect(_on_delete_pressed)
	action_hbox.add_child(btn_delete)

	var btn_back: GameMenuButton = MENU_BUTTON_SCENE.instantiate()
	btn_back.text = TEXT_BTN_BACK
	btn_back.set_dimensions(74, 24)
	btn_back.pressed.connect(_on_back_pressed)
	action_hbox.add_child(btn_back)

	# 5. Pasang InfoModal
	info_modal = INFO_MODAL_SCENE.instantiate()
	add_child(info_modal)

	_refresh_slots_display(false)


func _create_slot_card(parent: VBoxContainer, is_center_active: bool) -> Dictionary:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(CARDS_CONTAINER_WIDTH, 34 if is_center_active else 26)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_CARD_BG_ACTIVE if is_center_active else COLOR_CARD_BG_IDLE
	style.set_border_width_all(1)
	style.border_color = COLOR_GOLD if is_center_active else COLOR_BORDER_IDLE
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	hbox.add_theme_constant_override("separation", 8)
	panel.add_child(hbox)

	var badge_panel := PanelContainer.new()
	badge_panel.custom_minimum_size = Vector2(34, 22) if is_center_active else Vector2(28, 18)
	badge_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color(0.04, 0.05, 0.08, 0.9)
	badge_style.set_border_width_all(1)
	badge_style.border_color = COLOR_GOLD if is_center_active else COLOR_BORDER_IDLE
	badge_panel.add_theme_stylebox_override("panel", badge_style)
	hbox.add_child(badge_panel)

	var lbl_num := Label.new()
	lbl_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	FontManager.apply(lbl_num, FontManager.Type.DIGITAL, 10 if is_center_active else 8, COLOR_GOLD if is_center_active else COLOR_DIM_TEXT)
	badge_panel.add_child(lbl_num)

	var lbl_desc := Label.new()
	lbl_desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_desc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_desc.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	FontManager.apply(lbl_desc, FontManager.Type.BODY, 9 if is_center_active else 8, COLOR_DIM_TEXT)
	hbox.add_child(lbl_desc)

	return {
		"panel": panel,
		"hbox": hbox,
		"lbl_num": lbl_num,
		"lbl_desc": lbl_desc,
		"is_center": is_center_active,
		"visible_state": false
	}


func _scroll_slot(direction: int) -> void:
	var target_slot := clampi(selected_slot + direction, 1, MAX_SLOTS)
	if target_slot == selected_slot:
		return
	selected_slot = target_slot
	_refresh_slots_display(true)


func _refresh_slots_display(animate: bool) -> void:
	lbl_slot_counter.text = "SLOT %02d / %02d" % [selected_slot, MAX_SLOTS]

	var ratio: float = float(selected_slot - 1) / float(MAX_SLOTS - 1)
	var target_thumb_y: float = ratio * (SCROLL_TRACK_HEIGHT - SCROLL_THUMB_HEIGHT)
	if animate:
		if thumb_tween and thumb_tween.is_valid():
			thumb_tween.kill()
		thumb_tween = create_tween()
		thumb_tween.tween_property(scroll_thumb, "position:y", target_thumb_y, SLOT_FADE_TIME).set_trans(Tween.TRANS_SINE)
	else:
		scroll_thumb.position.y = target_thumb_y

	if slot_tween and slot_tween.is_valid():
		slot_tween.kill()

	if animate:
		slot_tween = create_tween().set_parallel(true)

	var offsets: Array[int] = [-1, 0, 1]
	for i in range(3):
		var card: Dictionary = slot_cards[i]
		var panel: PanelContainer = card["panel"]
		var hbox: HBoxContainer = card["hbox"]
		var lbl_num: Label = card["lbl_num"]
		var lbl_desc: Label = card["lbl_desc"]
		var slot_idx: int = selected_slot + offsets[i]
		var is_valid_slot: bool = (slot_idx >= 1 and slot_idx <= MAX_SLOTS)

		if not is_valid_slot:
			if animate and card["visible_state"]:
				slot_tween.tween_property(panel, "modulate:a", 0.0, SLOT_FADE_TIME).set_trans(Tween.TRANS_SINE)
			else:
				panel.modulate.a = 0.0
			card["visible_state"] = false
		else:
			var summary_text: String = SaveManager.get_slot_summary(slot_idx)
			var has_data: bool = SaveManager.has_slot_file(slot_idx)
			var target_panel_alpha: float = 1.0 if card["is_center"] else 0.75
			var desc_color: Color = COLOR_WHITE if (has_data and card["is_center"]) else COLOR_DIM_TEXT

			if animate:
				if not card["visible_state"]:
					lbl_num.text = "#%d" % slot_idx
					lbl_desc.text = summary_text
					FontManager.apply(lbl_desc, FontManager.Type.BODY, 9 if card["is_center"] else 8, desc_color)
					panel.modulate.a = 0.0
					hbox.modulate.a = 1.0
					slot_tween.tween_property(panel, "modulate:a", target_panel_alpha, SLOT_FADE_TIME).set_trans(Tween.TRANS_SINE)
				else:
					hbox.modulate.a = 0.2
					lbl_num.text = "#%d" % slot_idx
					lbl_desc.text = summary_text
					FontManager.apply(lbl_desc, FontManager.Type.BODY, 9 if card["is_center"] else 8, desc_color)
					slot_tween.tween_property(panel, "modulate:a", target_panel_alpha, SLOT_FADE_TIME)
					slot_tween.tween_property(hbox, "modulate:a", 1.0, SLOT_FADE_TIME).set_trans(Tween.TRANS_SINE)
			else:
				lbl_num.text = "#%d" % slot_idx
				lbl_desc.text = summary_text
				FontManager.apply(lbl_desc, FontManager.Type.BODY, 9 if card["is_center"] else 8, desc_color)
				panel.modulate.a = target_panel_alpha
				hbox.modulate.a = 1.0

			card["visible_state"] = true


# ==============================================================================
# EVENT HANDLERS
# ==============================================================================

func _on_load_pressed() -> void:
	if not SaveManager.has_slot_file(selected_slot):
		info_modal.popup("EMPTY LOG", "Slot #%d masih kosong. Tidak ada sinyal rekaman." % selected_slot)
		return

	var summary: String = SaveManager.get_slot_summary(selected_slot)
	info_modal.popup_confirm(
		"KONFIRMASI MUAT LOG",
		"Yakin ingin memuat rekaman ini?\n%s" % summary,
		"YA, MUAT",
		false,
		func():
			if SaveManager.load_from_slot(selected_slot):
				AudioManager.stop_bgm(0.4)
				var target_scene_path: String = SaveManager.get_saved_scene_path()
				# Pindah scene via loading screen beranimasi
				TransitionManager.change_scene_with_loading(target_scene_path)
	)


func _on_delete_pressed() -> void:
	if not SaveManager.has_slot_file(selected_slot):
		info_modal.popup("EMPTY LOG", "Slot #%d masih kosong. Tidak ada data untuk dihapus." % selected_slot)
		return

	info_modal.popup_confirm(
		"PERINGATAN HAPUS DATA",
		"Yakin ingin menghapus Slot #%d?\nData yang dihapus TIDAK DAPAT DIURUNGKAN!" % selected_slot,
		"YA, HAPUS",
		true,
		func():
			SaveManager.delete_slot(selected_slot)
			_refresh_slots_display(true)
			info_modal.popup("ARCHIVE DELETED", "Rekaman pada Slot #%d telah dimusnahkan secara permanen." % selected_slot)
	)


func _on_back_pressed() -> void:
	TransitionManager.change_scene(BACK_SCENE_PATH, FADE_DURATION)
