class_name VirtualControls
extends Control

const TOUCH_BTN_SIZE: Vector2 = Vector2(48, 48)
const JOYSTICK_BASE_RADIUS: float = 46.0
const JOYSTICK_KNOB_RADIUS: float = 18.0
const JOYSTICK_MAX_DISTANCE: float = 34.0
const JOYSTICK_DEADZONE: float = 0.12

var joystick_base: Panel
var joystick_knob: Panel
var joystick_touch_index: int = -1
var joystick_center: Vector2 = Vector2.ZERO
var player_ref: Node = null

var btn_touch_interact: Button
var btn_touch_run: Button

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	_build_floating_joystick()
	_build_touch_buttons()
	
	get_viewport().size_changed.connect(_reposition_buttons)
	call_deferred("_reposition_buttons")

func _process(_delta: float) -> void:
	if not player_ref or not is_instance_valid(player_ref):
		# Cari Player di scene saat ini (apapun nama scene induknya)
		var current_sc := get_tree().current_scene
		if current_sc:
			player_ref = current_sc.find_child("Player", true, false)

## Membangun joystick floating
func _build_floating_joystick() -> void:
	var base_diameter: float = JOYSTICK_BASE_RADIUS * 2.0
	var knob_diameter: float = JOYSTICK_KNOB_RADIUS * 2.0
	
	joystick_base = Panel.new()
	joystick_base.custom_minimum_size = Vector2(base_diameter, base_diameter)
	joystick_base.size = Vector2(base_diameter, base_diameter)
	joystick_base.visible = false
	
	var base_style := StyleBoxFlat.new()
	base_style.bg_color = Palette.BLACK_MODAL
	base_style.set_border_width_all(2)
	base_style.border_color = Palette.SLATE
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
	knob_style.bg_color = Palette.WHITE
	knob_style.set_border_width_all(1)
	knob_style.border_color = Palette.GOLD
	knob_style.set_corner_radius_all(int(JOYSTICK_KNOB_RADIUS))
	joystick_knob.add_theme_stylebox_override("panel", knob_style)
	joystick_base.add_child(joystick_knob)

## Membangun tombol bulat dengan efek tekan halus (tanpa kotak seleksi)
func _build_touch_buttons() -> void:
	# Style bulat normal dasar
	var round_normal := StyleBoxFlat.new()
	round_normal.bg_color = Palette.BLACK_MODAL
	round_normal.set_border_width_all(2)
	round_normal.border_color = Palette.SLATE
	round_normal.set_corner_radius_all(int(TOUCH_BTN_SIZE.x / 2.0))

	# Style bulat saat ditekan (sedikit lebih gelap dan menyusut rapi)
	var round_pressed := round_normal.duplicate()
	round_pressed.bg_color = Color(0.12, 0.14, 0.20, 0.95)

	# Style kosong untuk menghilangkan garis kotak seleksi (focus outline)
	var empty_focus := StyleBoxEmpty.new()

	# --- 1. Tombol E ---
	btn_touch_interact = Button.new()
	btn_touch_interact.text = "E"
	btn_touch_interact.custom_minimum_size = TOUCH_BTN_SIZE
	btn_touch_interact.size = TOUCH_BTN_SIZE
	btn_touch_interact.focus_mode = Control.FOCUS_NONE # Hapus kotak seleksi fokus
	btn_touch_interact.pivot_offset = TOUCH_BTN_SIZE / 2.0
	
	btn_touch_interact.add_theme_stylebox_override("normal", round_normal)
	btn_touch_interact.add_theme_stylebox_override("hover", round_normal)
	btn_touch_interact.add_theme_stylebox_override("pressed", round_pressed)
	btn_touch_interact.add_theme_stylebox_override("focus", empty_focus)
	
	FontManager.apply(btn_touch_interact, FontManager.Type.BODY_BOLD, 14, Palette.WHITE)
	
	# Efek visual tekan (skala mengecil saat ditekan)
	btn_touch_interact.button_down.connect(func():
		var tw := create_tween()
		tw.tween_property(btn_touch_interact, "scale", Vector2(0.9, 0.9), 0.05)
	)
	btn_touch_interact.button_up.connect(func():
		var tw := create_tween()
		tw.tween_property(btn_touch_interact, "scale", Vector2.ONE, 0.08)
	)
	btn_touch_interact.pressed.connect(func():
		if InteractionManager:
			InteractionManager.trigger_interact()
	)
	add_child(btn_touch_interact)

	# --- 2. Tombol RUN ---
	btn_touch_run = Button.new()
	btn_touch_run.text = "RUN"
	btn_touch_run.custom_minimum_size = TOUCH_BTN_SIZE
	btn_touch_run.size = TOUCH_BTN_SIZE
	btn_touch_run.focus_mode = Control.FOCUS_NONE # Hapus kotak seleksi fokus
	btn_touch_run.pivot_offset = TOUCH_BTN_SIZE / 2.0

	var run_normal := round_normal.duplicate()
	run_normal.border_color = Palette.YELLOW
	var run_pressed := round_pressed.duplicate()
	run_pressed.border_color = Palette.YELLOW
	run_pressed.bg_color = Color(0.25, 0.20, 0.05, 0.9)

	btn_touch_run.add_theme_stylebox_override("normal", run_normal)
	btn_touch_run.add_theme_stylebox_override("hover", run_normal)
	btn_touch_run.add_theme_stylebox_override("pressed", run_pressed)
	btn_touch_run.add_theme_stylebox_override("focus", empty_focus)

	FontManager.apply(btn_touch_run, FontManager.Type.BODY_BOLD, 10, Palette.YELLOW)

	btn_touch_run.button_down.connect(func():
		var tw := create_tween()
		tw.tween_property(btn_touch_run, "scale", Vector2(0.9, 0.9), 0.05)
		if player_ref:
			player_ref.set("is_sprint_pressed", true)
	)
	btn_touch_run.button_up.connect(func():
		var tw := create_tween()
		tw.tween_property(btn_touch_run, "scale", Vector2.ONE, 0.08)
		if player_ref:
			player_ref.set("is_sprint_pressed", false)
	)
	add_child(btn_touch_run)

## Menaruh posisi tombol di pojok kanan bawah
func _reposition_buttons() -> void:
	var vp_size: Vector2 = get_viewport_rect().size
	if vp_size == Vector2.ZERO:
		vp_size = Vector2(640, 360)
		
	if is_instance_valid(btn_touch_interact):
		btn_touch_interact.position = Vector2(
			vp_size.x - TOUCH_BTN_SIZE.x - 20,
			vp_size.y - TOUCH_BTN_SIZE.y - 20
		)
		
	if is_instance_valid(btn_touch_run):
		btn_touch_run.position = Vector2(
			vp_size.x - TOUCH_BTN_SIZE.x - 20,
			vp_size.y - (TOUCH_BTN_SIZE.y * 2) - 30
		)

## Input handling
func _input(event: InputEvent) -> void:
	var vp_width: float = get_viewport_rect().size.x
	var left_zone_limit: float = vp_width * 0.55
	
	if event is InputEventScreenTouch:
		if event.pressed and joystick_touch_index == -1:
			if event.position.x <= left_zone_limit:
				joystick_touch_index = event.index
				_spawn_joystick_at(event.position)
		elif not event.pressed and event.index == joystick_touch_index:
			_hide_joystick()
			
	elif event is InputEventScreenDrag:
		if event.index == joystick_touch_index:
			_update_joystick_vector(event.position)
			
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and joystick_touch_index == -1:
			if event.position.x <= left_zone_limit:
				joystick_touch_index = 99
				_spawn_joystick_at(event.position)
		elif not event.pressed and joystick_touch_index == 99:
			_hide_joystick()
			
	elif event is InputEventMouseMotion and joystick_touch_index == 99:
		_update_joystick_vector(event.position)

func _spawn_joystick_at(pos: Vector2) -> void:
	joystick_center = pos
	joystick_base.global_position = pos - Vector2(JOYSTICK_BASE_RADIUS, JOYSTICK_BASE_RADIUS)
	joystick_knob.position = Vector2(
		JOYSTICK_BASE_RADIUS - JOYSTICK_KNOB_RADIUS,
		JOYSTICK_BASE_RADIUS - JOYSTICK_KNOB_RADIUS
	)
	joystick_base.visible = true

func _update_joystick_vector(touch_pos: Vector2) -> void:
	var delta_vec: Vector2 = touch_pos - joystick_center
	var dist: float = delta_vec.length()
	var clamped_offset: Vector2 = delta_vec.limit_length(JOYSTICK_MAX_DISTANCE)
	
	# Geser knob secara lokal di dalam base
	joystick_knob.position = Vector2(
		JOYSTICK_BASE_RADIUS - JOYSTICK_KNOB_RADIUS,
		JOYSTICK_BASE_RADIUS - JOYSTICK_KNOB_RADIUS
	) + clamped_offset
	
	var norm_strength: float = clampf(dist / JOYSTICK_MAX_DISTANCE, 0.0, 1.0)
	if norm_strength > JOYSTICK_DEADZONE:
		var move_vec := delta_vec.normalized() * norm_strength
		if player_ref:
			player_ref.set("joystick_vector", move_vec)
	else:
		if player_ref:
			player_ref.set("joystick_vector", Vector2.ZERO)

func _hide_joystick() -> void:
	joystick_touch_index = -1
	if player_ref:
		player_ref.set("joystick_vector", Vector2.ZERO)
	joystick_base.visible = false
