extends CanvasLayer
class_name HUD

static var instance: HUD

# --- RESOURCE PATHS ---
const FONT_PATH: String = "res://assets/fonts/Pix32.ttf"

# --- THEME COLORS ---
const COLOR_SANITY_NORMAL: Color = Color(0.3, 0.7, 0.85, 0.9)
const COLOR_SANITY_LABEL: Color = Color(0.7, 0.85, 0.9)
const COLOR_CRITICAL_PULSE: Color = Color(1.0, 0.2, 0.2)
const COLOR_PROMPT_GOLD: Color = Color(0.95, 0.82, 0.25)
const COLOR_PANEL_BG: Color = Color(0.05, 0.06, 0.09, 0.88)
const COLOR_PANEL_BORDER: Color = Color(0.2, 0.25, 0.35, 0.8)

const COLOR_STAMINA_FILL: Color = Color(0.9, 0.75, 0.2, 0.95)
const COLOR_STAMINA_EXHAUSTED: Color = Color(0.8, 0.2, 0.2, 0.9)
const COLOR_STAMINA_BG: Color = Color(0.05, 0.06, 0.08, 0.6)

# --- DIMENSIONS & TIMINGS ---
const HUD_LAYER_INDEX: int = 10
const SANITY_BAR_SIZE: Vector2 = Vector2(96, 6)
const STAMINA_BAR_HEIGHT: float = 3.0
const TOUCH_BTN_SIZE: Vector2 = Vector2(40, 40)
const PULSE_DURATION: float = 0.4

const JOYSTICK_BASE_RADIUS: float = 42.0
const JOYSTICK_KNOB_RADIUS: float = 16.0
const JOYSTICK_MAX_DISTANCE: float = 28.0
const JOYSTICK_DEADZONE: float = 0.12

var custom_font: FontFile
var sanity_bar: ProgressBar
var lbl_sanity: Label
var prompt_container: PanelContainer
var lbl_prompt: Label
var stamina_bar: ProgressBar
var stamina_fill_style: StyleBoxFlat
var sanity_pulse_tween: Tween

var joystick_base: Panel
var joystick_knob: Panel
var joystick_touch_index: int = -1
var joystick_center: Vector2 = Vector2.ZERO

# --- UI MODALS & MENUS ---
var pause_modal: PauseModal
var inventory_modal: InventoryModal
var dialogue_box: DialogueBox

var btn_bag: GameMenuButton
var hotbar_slots_ui: Array[PanelContainer] = []

var btn_talk_prompt: GameMenuButton
var current_talk_callable: Callable


func _enter_tree() -> void:
	instance = self


func _ready() -> void:
	layer = HUD_LAYER_INDEX

	if ResourceLoader.exists(FONT_PATH):
		custom_font = load(FONT_PATH)

	_build_sanity_hud()
	_build_stamina_bottom_bar()
	_build_interaction_prompt()
	_build_virtual_joystick()
	_build_touch_controls()
	
	_build_top_right_menu()
	_build_talk_prompt()
	
	_init_modals()

	if SaveManager:
		SaveManager.sanity_changed.connect(_on_sanity_changed)
		SaveManager.sanity_critical.connect(_on_sanity_critical)
		var init_sanity: float = SaveManager.get_current_sanity() if SaveManager.has_method("get_current_sanity") else SaveManager.MAX_SANITY
		_on_sanity_changed(init_sanity, SaveManager.MAX_SANITY)
		
	var inv_mgr: Node = get_node_or_null("/root/InventoryManager")
	if inv_mgr:
		inv_mgr.hotbar_updated.connect(_refresh_hotbar)
		_refresh_hotbar()


func _process(_delta: float) -> void:
	if stamina_bar:
		stamina_bar.value = Player.current_stamina
		if Player.current_stamina <= 0.0:
			stamina_fill_style.bg_color = COLOR_STAMINA_EXHAUSTED
		elif Player.current_stamina >= 25.0:
			stamina_fill_style.bg_color = COLOR_STAMINA_FILL

	if InteractionManager and InteractionManager.active_interactable != null:
		var target: Node2D = InteractionManager.active_interactable
		var target_name: String = "INTERACT"

		if "station_name" in target:
			target_name = target.station_name
		elif "door_name" in target:
			target_name = target.door_name

		show_prompt("PRESS [E] // " + target_name)
	else:
		hide_prompt()


func _init_modals() -> void:
	dialogue_box = DialogueBox.new()
	dialogue_box.name = "DialogueBox"
	dialogue_box.z_index = 5
	add_child(dialogue_box)

	inventory_modal = InventoryModal.new()
	inventory_modal.name = "InventoryModal"
	inventory_modal.z_index = 9
	add_child(inventory_modal)
	
	if inventory_modal.get("hud_bag_btn") != null:
		inventory_modal.hud_bag_btn.queue_free()
		inventory_modal.hud_bag_btn = self.btn_bag

	pause_modal = PauseModal.new()
	pause_modal.name = "PauseModal"
	pause_modal.z_index = 10
	add_child(pause_modal)


func _build_top_right_menu() -> void:
	var hbox := HBoxContainer.new()
	
	# Menggunakan anchor agar selalu di ujung kanan
	hbox.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	hbox.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	hbox.offset_right = -12
	hbox.offset_top = 10
	
	hbox.alignment = BoxContainer.ALIGNMENT_END
	hbox.add_theme_constant_override("separation", 8)
	add_child(hbox)
	
	var hotbar_hbox := HBoxContainer.new()
	hotbar_hbox.add_theme_constant_override("separation", 4)
	hbox.add_child(hotbar_hbox)
	
	hotbar_slots_ui.clear()
	for i in range(3):
		var box := PanelContainer.new()
		box.custom_minimum_size = Vector2(26, 26)
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0.04, 0.05, 0.08, 0.8)
		st.set_border_width_all(1)
		st.border_color = COLOR_PANEL_BORDER
		box.add_theme_stylebox_override("panel", st)
		
		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		box.add_child(icon)
		
		hotbar_hbox.add_child(box)
		hotbar_slots_ui.append(box)
	
	btn_bag = GameMenuButton.new()
	# FIX: Add child sebelum mengatur properti
	hbox.add_child(btn_bag)
	
	btn_bag.text = "[ TAS ]"
	btn_bag.set_dimensions(54, 26)
	btn_bag.font_size_override = 9
	btn_bag.set_variant(GameMenuButton.Variant.DEFAULT)
	btn_bag.pressed.connect(func():
		if inventory_modal and not dialogue_box.is_active:
			if inventory_modal.has_method("open"):
				inventory_modal.open()
	)


func _refresh_hotbar() -> void:
	var inv_mgr: Node = get_node_or_null("/root/InventoryManager")
	if not inv_mgr: return
	
	for i in range(hotbar_slots_ui.size()):
		var box: PanelContainer = hotbar_slots_ui[i]
		var icon: TextureRect = box.get_node("Icon")
		
		if i < inv_mgr.hotbar.size() and inv_mgr.hotbar[i].has("id"):
			var item_id: String = inv_mgr.hotbar[i]["id"]
			var meta: Dictionary = inv_mgr.get_item_meta(item_id)
			var path: String = meta.get("icon_path", "")
			if path != "" and ResourceLoader.exists(path):
				icon.texture = load(path)
			else:
				icon.texture = null
			box.get_theme_stylebox("panel").border_color = COLOR_PROMPT_GOLD
		else:
			icon.texture = null
			box.get_theme_stylebox("panel").border_color = COLOR_PANEL_BORDER


func _build_talk_prompt() -> void:
	btn_talk_prompt = GameMenuButton.new()
	add_child(btn_talk_prompt)
	
	btn_talk_prompt.text = "[ E ] AJAK BICARA"
	btn_talk_prompt.set_dimensions(136, 24)
	btn_talk_prompt.font_size_override = 9
	btn_talk_prompt.set_variant(GameMenuButton.Variant.ACCENT)
	btn_talk_prompt.position = Vector2((640 - 136) / 2.0, 295)
	btn_talk_prompt.visible = false
	btn_talk_prompt.modulate.a = 0.0
	btn_talk_prompt.pressed.connect(func():
		if current_talk_callable.is_valid():
			current_talk_callable.call()
	)


func set_talk_prompt_visible(show_btn: bool, callable: Callable = Callable()) -> void:
	if not btn_talk_prompt: return
	
	if show_btn and (not dialogue_box or not dialogue_box.is_active):
		current_talk_callable = callable
		btn_talk_prompt.visible = true
		var tw := create_tween()
		tw.tween_property(btn_talk_prompt, "modulate:a", 1.0, 0.15)
	else:
		var tw := create_tween()
		tw.tween_property(btn_talk_prompt, "modulate:a", 0.0, 0.12)
		tw.tween_callback(func(): btn_talk_prompt.visible = false)


func start_dialogue(lines: Array[Dictionary], callback: Callable = Callable()) -> void:
	if dialogue_box:
		set_talk_prompt_visible(false)
		dialogue_box.start_dialogue(lines)
		if callback.is_valid():
			if not dialogue_box.dialogue_finished.is_connected(callback):
				dialogue_box.dialogue_finished.connect(callback, CONNECT_ONE_SHOT)


func _input(event: InputEvent) -> void:
	if not joystick_base:
		return

	joystick_center = joystick_base.global_position + Vector2(JOYSTICK_BASE_RADIUS, JOYSTICK_BASE_RADIUS)

	if event is InputEventScreenTouch:
		if event.pressed and joystick_touch_index == -1:
			if event.position.distance_to(joystick_center) <= JOYSTICK_BASE_RADIUS * 1.35:
				joystick_touch_index = event.index
				_update_joystick_vector(event.position)
		elif not event.pressed and event.index == joystick_touch_index:
			_reset_joystick()

	elif event is InputEventScreenDrag:
		if event.index == joystick_touch_index:
			_update_joystick_vector(event.position)

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and joystick_touch_index == -1:
			if event.position.distance_to(joystick_center) <= JOYSTICK_BASE_RADIUS * 1.35:
				joystick_touch_index = 99
				_update_joystick_vector(event.position)
		elif not event.pressed and joystick_touch_index == 99:
			_reset_joystick()

	elif event is InputEventMouseMotion and joystick_touch_index == 99:
		_update_joystick_vector(event.position)


func _update_joystick_vector(touch_pos: Vector2) -> void:
	var delta_vec: Vector2 = touch_pos - joystick_center
	var dist: float = delta_vec.length()
	var clamped_offset: Vector2 = delta_vec.limit_length(JOYSTICK_MAX_DISTANCE)

	joystick_knob.position = Vector2(
		JOYSTICK_BASE_RADIUS - JOYSTICK_KNOB_RADIUS,
		JOYSTICK_BASE_RADIUS - JOYSTICK_KNOB_RADIUS
	) + clamped_offset

	var norm_strength: float = clampf(dist / JOYSTICK_MAX_DISTANCE, 0.0, 1.0)
	if norm_strength > JOYSTICK_DEADZONE:
		Player.joystick_vector = delta_vec.normalized() * norm_strength
	else:
		Player.joystick_vector = Vector2.ZERO


func _reset_joystick() -> void:
	joystick_touch_index = -1
	Player.joystick_vector = Vector2.ZERO
	if joystick_knob:
		var tween := create_tween()
		tween.tween_property(
			joystick_knob,
			"position",
			Vector2(JOYSTICK_BASE_RADIUS - JOYSTICK_KNOB_RADIUS, JOYSTICK_BASE_RADIUS - JOYSTICK_KNOB_RADIUS),
			0.08
		).set_trans(Tween.TRANS_QUAD)


func _build_virtual_joystick() -> void:
	var base_diameter: float = JOYSTICK_BASE_RADIUS * 2.0
	var knob_diameter: float = JOYSTICK_KNOB_RADIUS * 2.0

	joystick_base = Panel.new()
	joystick_base.custom_minimum_size = Vector2(base_diameter, base_diameter)
	joystick_base.size = Vector2(base_diameter, base_diameter)
	joystick_base.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	joystick_base.offset_left = 20
	joystick_base.offset_top = -24 - base_diameter
	joystick_base.offset_right = 20 + base_diameter
	joystick_base.offset_bottom = -24

	var base_style := StyleBoxFlat.new()
	base_style.bg_color = Color(0.06, 0.08, 0.12, 0.55)
	base_style.set_border_width_all(1)
	base_style.border_color = Color(0.45, 0.52, 0.65, 0.65)
	base_style.set_corner_radius_all(int(JOYSTICK_BASE_RADIUS))
	joystick_base.add_theme_stylebox_override("panel", base_style)
	add_child(joystick_base)

	joystick_knob = Panel.new()
	joystick_knob.custom_minimum_size = Vector2(knob_diameter, knob_diameter)
	joystick_knob.size = Vector2(knob_diameter, knob_diameter)
	joystick_knob.position = Vector2(
		JOYSTICK_BASE_RADIUS - JOYSTICK_KNOB_RADIUS,
		JOYSTICK_BASE_RADIUS - JOYSTICK_KNOB_RADIUS
	)

	var knob_style := StyleBoxFlat.new()
	knob_style.bg_color = Color(0.85, 0.88, 0.95, 0.75)
	knob_style.set_border_width_all(1)
	knob_style.border_color = COLOR_PROMPT_GOLD
	knob_style.set_corner_radius_all(int(JOYSTICK_KNOB_RADIUS))
	joystick_knob.add_theme_stylebox_override("panel", knob_style)
	joystick_base.add_child(joystick_knob)


func _build_stamina_bottom_bar() -> void:
	stamina_bar = ProgressBar.new()
	stamina_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	stamina_bar.offset_top = -STAMINA_BAR_HEIGHT
	stamina_bar.offset_bottom = 0
	stamina_bar.show_percentage = false
	stamina_bar.min_value = 0.0
	stamina_bar.max_value = Player.MAX_STAMINA
	stamina_bar.value = Player.MAX_STAMINA
	stamina_bar.fill_mode = ProgressBar.FILL_END_TO_BEGIN

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = COLOR_STAMINA_BG

	stamina_fill_style = StyleBoxFlat.new()
	stamina_fill_style.bg_color = COLOR_STAMINA_FILL

	stamina_bar.add_theme_stylebox_override("background", bg_style)
	stamina_bar.add_theme_stylebox_override("fill", stamina_fill_style)
	add_child(stamina_bar)


func _build_touch_controls() -> void:
	var btn_touch_interact := Button.new()
	btn_touch_interact.text = "E"
	btn_touch_interact.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	btn_touch_interact.offset_right = -24
	btn_touch_interact.offset_bottom = -24
	btn_touch_interact.custom_minimum_size = TOUCH_BTN_SIZE
	btn_touch_interact.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	btn_touch_interact.grow_vertical = Control.GROW_DIRECTION_BEGIN

	var round_style := StyleBoxFlat.new()
	round_style.bg_color = Color(0.08, 0.1, 0.14, 0.7)
	round_style.set_border_width_all(1)
	round_style.border_color = Color(0.5, 0.55, 0.65, 0.8)
	round_style.set_corner_radius_all(int(TOUCH_BTN_SIZE.x / 2.0))

	btn_touch_interact.add_theme_stylebox_override("normal", round_style)
	apply_font_btn(btn_touch_interact, 12, Color.WHITE)
	btn_touch_interact.pressed.connect(func():
		if InteractionManager:
			InteractionManager.trigger_interact()
	)
	add_child(btn_touch_interact)

	var btn_touch_run := Button.new()
	btn_touch_run.text = "RUN"
	btn_touch_run.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	btn_touch_run.offset_right = -24
	btn_touch_run.offset_bottom = -24 - TOUCH_BTN_SIZE.y - 12
	btn_touch_run.custom_minimum_size = TOUCH_BTN_SIZE
	btn_touch_run.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	btn_touch_run.grow_vertical = Control.GROW_DIRECTION_BEGIN

	var run_normal := round_style.duplicate()
	run_normal.border_color = Color(0.85, 0.7, 0.2, 0.7)
	btn_touch_run.add_theme_stylebox_override("normal", run_normal)
	apply_font_btn(btn_touch_run, 8, Color(0.95, 0.85, 0.4))

	btn_touch_run.button_down.connect(func(): Player.is_sprint_pressed = true)
	btn_touch_run.button_up.connect(func(): Player.is_sprint_pressed = false)
	add_child(btn_touch_run)


func _build_sanity_hud() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_TOP_LEFT)
	margin.offset_left = 12
	margin.offset_top = 10
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	margin.add_child(vbox)

	lbl_sanity = Label.new()
	lbl_sanity.text = "SANITY // 100%"
	apply_font(lbl_sanity, 8, COLOR_SANITY_LABEL)
	vbox.add_child(lbl_sanity)

	sanity_bar = ProgressBar.new()
	sanity_bar.custom_minimum_size = SANITY_BAR_SIZE
	sanity_bar.show_percentage = false
	sanity_bar.min_value = 0.0
	sanity_bar.max_value = 100.0
	sanity_bar.value = 100.0

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.06, 0.08, 0.12, 0.8)
	bg_style.set_border_width_all(1)
	bg_style.border_color = COLOR_PANEL_BORDER

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = COLOR_SANITY_NORMAL

	sanity_bar.add_theme_stylebox_override("background", bg_style)
	sanity_bar.add_theme_stylebox_override("fill", fill_style)
	vbox.add_child(sanity_bar)


func _build_interaction_prompt() -> void:
	prompt_container = PanelContainer.new()
	prompt_container.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	prompt_container.offset_top = -48
	prompt_container.offset_bottom = -30
	prompt_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	prompt_container.visible = false

	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_PANEL_BG
	style.set_border_width_all(1)
	style.border_color = COLOR_PROMPT_GOLD
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	prompt_container.add_theme_stylebox_override("panel", style)
	add_child(prompt_container)

	lbl_prompt = Label.new()
	lbl_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	apply_font(lbl_prompt, 9, COLOR_PROMPT_GOLD)
	prompt_container.add_child(lbl_prompt)


func show_prompt(text_msg: String) -> void:
	lbl_prompt.text = text_msg
	prompt_container.visible = true


func hide_prompt() -> void:
	prompt_container.visible = false


func _on_sanity_changed(val: float, max_val: float) -> void:
	sanity_bar.value = val
	lbl_sanity.text = "SANITY // %d%%" % int((val / max_val) * 100)


func _on_sanity_critical(is_critical: bool) -> void:
	if is_critical:
		if sanity_pulse_tween and sanity_pulse_tween.is_valid():
			sanity_pulse_tween.kill()
		sanity_pulse_tween = create_tween().set_loops()
		sanity_pulse_tween.tween_property(sanity_bar, "modulate", COLOR_CRITICAL_PULSE, PULSE_DURATION)
		sanity_pulse_tween.tween_property(sanity_bar, "modulate", Color.WHITE, PULSE_DURATION)
	else:
		if sanity_pulse_tween and sanity_pulse_tween.is_valid():
			sanity_pulse_tween.kill()
		sanity_bar.modulate = Color.WHITE


func apply_font(lbl: Label, size_px: int, col: Color) -> void:
	if custom_font:
		lbl.add_theme_font_override("font", custom_font)
	lbl.add_theme_font_size_override("font_size", size_px)
	lbl.add_theme_color_override("font_color", col)


func apply_font_btn(btn: Button, size_px: int, col: Color) -> void:
	if custom_font:
		btn.add_theme_font_override("font", custom_font)
	btn.add_theme_font_size_override("font_size", size_px)
	btn.add_theme_color_override("font_color", col)
