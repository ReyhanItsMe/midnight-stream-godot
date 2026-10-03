## UI Kotak dialog lengkap dengan sistem antrean teks, portrait ekspresi dinamis, dan typewriter.
##
## Cara pakai:
##   var diag = DialogueBox.new()
##   add_child(diag)
##   diag.start_dialogue([
##       {"speaker": "Rian", "text": "Tempat apa ini...", "side": "left", "expression": "bingung", "speed": 32.0},
##       {"speaker": "Misterius", "text": "Jangan mendekat.", "side": "right", "expression": "biasa", "speed": 24.0}
##   ])
##   diag.dialogue_finished.connect(func(): print("Percakapan usai."))
class_name DialogueBox
extends Control

signal dialogue_finished

static var is_dialogue_open: bool = false

const VIEWPORT_RES: Vector2 = Vector2(640, 360)
const DIALOGUE_BOX_SIZE: Vector2 = Vector2(520, 82)
const BOX_TARGET_POS: Vector2 = Vector2(60, 258)
const BOX_HIDDEN_POS: Vector2 = Vector2(60, 276)

const COL_BG_BOX: Color = Color(0.05, 0.06, 0.10, 0.96)
const COL_BORDER_GOLD: Color = Color(0.95, 0.82, 0.25, 0.95)
const COL_TEXT_CONTENT: Color = Color(0.92, 0.94, 0.98, 1.0)

var typewriter: TypewriterEffect
var portrait_left: DialoguePortrait
var portrait_right: DialoguePortrait

var input_blocker: ColorRect
var box_container: Control
var text_label: Label
var continue_indicator: Label
var click_catcher_btn: Button

var dialogue_queue: Array[Dictionary] = []
var is_active: bool = false
var is_closing: bool = false
var box_tween: Tween
var indicator_tween: Tween
var last_speaker_side: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_preset(Control.PRESET_FULL_RECT)
	custom_minimum_size = VIEWPORT_RES
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	typewriter = TypewriterEffect.new()
	typewriter.typing_finished.connect(_on_typing_finished)
	add_child(typewriter)

	_build_ui_structure()
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not is_active or is_closing:
		return

	var is_triggered: bool = false

	# 1. Cek action "interact" hanya jika sudah didaftarkan di InputMap
	if InputMap.has_action("interact") and event.is_action_pressed("interact"):
		is_triggered = true
	# 2. Cek action bawaan Godot (Enter / Spasi)
	elif event.is_action_pressed("ui_accept"):
		is_triggered = true
	# 3. Fallback langsung tombol fisik keyboard E atau Space
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.keycode == KEY_SPACE:
			is_triggered = true

	if is_triggered:
		advance_dialogue()
		get_viewport().set_input_as_handled()

func _build_ui_structure() -> void:
	# 1. Fullscreen Touch / Click Blocker
	input_blocker = ColorRect.new()
	input_blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	input_blocker.color = Color(0, 0, 0, 0.001)
	input_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(input_blocker)

	# 2. Main Box Container
	box_container = Control.new()
	box_container.custom_minimum_size = DIALOGUE_BOX_SIZE
	box_container.size = DIALOGUE_BOX_SIZE
	box_container.position = BOX_HIDDEN_POS
	box_container.modulate.a = 0.0
	add_child(box_container)

	var box_panel := PanelContainer.new()
	box_panel.size = DIALOGUE_BOX_SIZE
	box_panel.custom_minimum_size = DIALOGUE_BOX_SIZE
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = COL_BG_BOX
	panel_style.set_border_width_all(1)
	panel_style.border_color = COL_BORDER_GOLD
	box_panel.add_theme_stylebox_override("panel", panel_style)
	box_container.add_child(box_panel)

	var text_margin := MarginContainer.new()
	text_margin.add_theme_constant_override("margin_left", 18)
	text_margin.add_theme_constant_override("margin_right", 18)
	text_margin.add_theme_constant_override("margin_top", 16)
	text_margin.add_theme_constant_override("margin_bottom", 14)
	box_panel.add_child(text_margin)

	text_label = Label.new()
	text_label.custom_minimum_size = Vector2(480, 48)
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_font(text_label, 10, COL_TEXT_CONTENT, 0)
	text_margin.add_child(text_label)

	continue_indicator = Label.new()
	continue_indicator.text = "▼ KLIK / E"
	continue_indicator.position = Vector2(DIALOGUE_BOX_SIZE.x - 68, DIALOGUE_BOX_SIZE.y - 16)
	continue_indicator.visible = false
	_apply_font(continue_indicator, 8, COL_BORDER_GOLD, 2)
	box_container.add_child(continue_indicator)

	# 3. Portrait Molecules
	portrait_left = DialoguePortrait.new()
	box_container.add_child(portrait_left)

	portrait_right = DialoguePortrait.new()
	box_container.add_child(portrait_right)

	# 4. Click Action Button
	click_catcher_btn = Button.new()
	click_catcher_btn.flat = true
	click_catcher_btn.position = Vector2(0, -36)
	click_catcher_btn.size = Vector2(DIALOGUE_BOX_SIZE.x, DIALOGUE_BOX_SIZE.y + 36)
	click_catcher_btn.focus_mode = Control.FOCUS_NONE
	click_catcher_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	click_catcher_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	click_catcher_btn.pressed.connect(advance_dialogue)
	box_container.add_child(click_catcher_btn)

func start_dialogue(lines: Array[Dictionary]) -> void:
	if lines.is_empty() or is_active:
		return

	is_dialogue_open = true
	dialogue_queue = lines.duplicate()
	is_active = true
	is_closing = false
	last_speaker_side = ""
	visible = true

	# Hentikan gerak player
	var player_cls = get_tree().current_scene.find_child("Player", true, false)
	if player_cls:
		player_cls.set("joystick_vector", Vector2.ZERO)
		player_cls.set("is_sprint_pressed", false)
		player_cls.set("velocity", Vector2.ZERO)

	box_container.position = BOX_HIDDEN_POS
	box_container.modulate.a = 0.0
	if box_tween and box_tween.is_valid():
		box_tween.kill()

	box_tween = create_tween().set_parallel(true)
	box_tween.tween_property(box_container, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	box_tween.tween_property(box_container, "position", BOX_TARGET_POS, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_play_next_line()

func advance_dialogue() -> void:
	if not is_active or is_closing:
		return

	if typewriter.is_active():
		typewriter.finish()
		return

	if not dialogue_queue.is_empty():
		_play_next_line()
	else:
		_close_dialogue()

func _play_next_line() -> void:
	var line: Dictionary = dialogue_queue.pop_front()
	var text_str: String = line.get("text", "")
	var speaker: String = line.get("speaker", "Rian")
	var side: String = line.get("side", "left")
	var expr: String = line.get("expression", "biasa")
	var speed: float = line.get("speed", 36.0)

	_update_portraits(speaker, side, expr)
	_stop_indicator_blink()
	typewriter.start_typing(text_label, text_str, speed)

func _update_portraits(speaker: String, side: String, expression: String) -> void:
	var is_left: bool = (side == "left")
	var side_changed: bool = (last_speaker_side != side)

	if is_left:
		portrait_left.setup_speaker(speaker, expression, true, DIALOGUE_BOX_SIZE.x, side_changed)
		portrait_right.hide_all()
	else:
		portrait_right.setup_speaker(speaker, expression, false, DIALOGUE_BOX_SIZE.x, side_changed)
		portrait_left.hide_all()

	last_speaker_side = side

func _on_typing_finished() -> void:
	_start_indicator_blink()

func _start_indicator_blink() -> void:
	continue_indicator.visible = true
	continue_indicator.modulate.a = 1.0
	if indicator_tween and indicator_tween.is_valid():
		indicator_tween.kill()

	indicator_tween = create_tween().set_loops()
	indicator_tween.tween_property(continue_indicator, "modulate:a", 0.25, 0.45)
	indicator_tween.tween_property(continue_indicator, "modulate:a", 1.0, 0.45)

func _stop_indicator_blink() -> void:
	if indicator_tween and indicator_tween.is_valid():
		indicator_tween.kill()
	continue_indicator.visible = false

func _close_dialogue() -> void:
	is_closing = true
	_stop_indicator_blink()

	if box_tween and box_tween.is_valid():
		box_tween.kill()

	box_tween = create_tween().set_parallel(true)
	box_tween.tween_property(box_container, "modulate:a", 0.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	box_tween.tween_property(box_container, "position", BOX_HIDDEN_POS, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	box_tween.chain().tween_callback(func():
		visible = false
		is_active = false
		is_closing = false
		is_dialogue_open = false
		dialogue_finished.emit()
	)

func _apply_font(lbl: Label, f_size: int, col: Color, font_type: int = 1) -> void:
	var root_node = Engine.get_main_loop().root if Engine.get_main_loop() else null
	var font_mgr = root_node.get_node_or_null("FontManager") if root_node else null
	if font_mgr and font_mgr.has_method("apply"):
		font_mgr.apply(lbl, font_type, f_size, col)
	else:
		lbl.add_theme_font_size_override("font_size", f_size)
		lbl.add_theme_color_override("font_color", col)
