extends Control
class_name DialogueBox

signal dialogue_finished

# Flag static global agar skrip lain (Player, Door, Interaksi) tahu dialog sedang aktif
static var is_dialogue_open: bool = false

const VIEWPORT_RES: Vector2 = Vector2(640, 360)
const DIALOGUE_BOX_SIZE: Vector2 = Vector2(520, 82)
const BOX_TARGET_POS: Vector2 = Vector2(60, 258)
const BOX_HIDDEN_POS: Vector2 = Vector2(60, 276)

const TYPE_SFX_PATH: String = "res://assets/audio/sfx/sfx-click-button.mp3"

const COL_BG_BOX: Color = Color(0.05, 0.06, 0.10, 0.96)
const COL_BORDER_GOLD: Color = Color(0.95, 0.82, 0.25, 0.95)
const COL_HEADER_BG: Color = Color(0.09, 0.10, 0.16, 1.0)
const COL_TEXT_CONTENT: Color = Color(0.92, 0.94, 0.98, 1.0)

const RIAN_EXPR_DIR: String = "res://assets/sprites/characters/rian/expressions/"
const MISTERIUS_EXPR_DIR: String = "res://assets/sprites/characters/mistery/expressions/"

var type_sfx_player: AudioStreamPlayer

# Node Penahan Input Dunia Game (Full Screen)
var input_blocker: ColorRect

# Node Kotak Dialog
var box_container: Control
var box_panel: PanelContainer
var text_label: Label
var continue_indicator: Label
var click_catcher_btn: Button

# Node Avatar & Nama
var avatar_left: TextureRect
var name_badge_left: PanelContainer
var name_label_left: Label

var avatar_right: TextureRect
var name_badge_right: PanelContainer
var name_label_right: Label

var dialogue_queue: Array[Dictionary] = []
var is_active: bool = false
var is_typing: bool = false
var is_closing: bool = false
var full_current_text: String = ""
var visible_chars_count: float = 0.0
var last_char_index: int = 0
var typewriter_speed: float = 36.0

var box_tween: Tween
var indicator_tween: Tween
var portrait_tween: Tween
var last_speaker_side: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	position = Vector2.ZERO
	size = VIEWPORT_RES
	custom_minimum_size = VIEWPORT_RES
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_setup_typewriter_audio()
	_build_ui_structure()
	_apply_fonts_with_manager()
	visible = false


func _process(delta: float) -> void:
	if not is_active or not is_typing or is_closing:
		return

	visible_chars_count += typewriter_speed * delta
	var current_idx: int = int(visible_chars_count)
	text_label.visible_characters = current_idx

	if current_idx > last_char_index:
		if current_idx % 2 == 0 and type_sfx_player and type_sfx_player.stream:
			type_sfx_player.pitch_scale = randf_range(1.9, 2.3)
			type_sfx_player.play()
		last_char_index = current_idx

	if text_label.visible_characters >= full_current_text.length():
		_finish_typing()


func _unhandled_input(event: InputEvent) -> void:
	if not is_active or is_closing:
		return

	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and (event.keycode == KEY_E or event.keycode == KEY_SPACE)):
		advance_dialogue()
		get_viewport().set_input_as_handled()


# ==============================================================================
# STRUKTUR UI DENGAN INPUT BLOCKER
# ==============================================================================

func _setup_typewriter_audio() -> void:
	type_sfx_player = AudioStreamPlayer.new()
	type_sfx_player.bus = "SFX"
	type_sfx_player.volume_db = -14.0
	if ResourceLoader.exists(TYPE_SFX_PATH):
		type_sfx_player.stream = load(TYPE_SFX_PATH)
	add_child(type_sfx_player)


func _build_ui_structure() -> void:
	# 1. Input Blocker Layar Penuh (Memblokir klik ke dunia game & tombol lain)
	input_blocker = ColorRect.new()
	input_blocker.name = "InputBlocker"
	input_blocker.position = Vector2.ZERO
	input_blocker.size = VIEWPORT_RES
	input_blocker.custom_minimum_size = VIEWPORT_RES
	# Transparan tidak terlihat, namun STOP semua mouse/touch input
	input_blocker.color = Color(0, 0, 0, 0.001)
	input_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(input_blocker)

	# 2. Kontainer Kotak Dialog Utama
	box_container = Control.new()
	box_container.custom_minimum_size = DIALOGUE_BOX_SIZE
	box_container.size = DIALOGUE_BOX_SIZE
	box_container.position = BOX_HIDDEN_POS
	box_container.modulate.a = 0.0
	add_child(box_container)

	box_panel = PanelContainer.new()
	box_panel.position = Vector2.ZERO
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
	text_margin.add_child(text_label)

	continue_indicator = Label.new()
	continue_indicator.text = "▼ KLIK / E"
	continue_indicator.position = Vector2(DIALOGUE_BOX_SIZE.x - 68, DIALOGUE_BOX_SIZE.y - 16)
	continue_indicator.visible = false
	box_container.add_child(continue_indicator)

	# Avatar & Badge Kiri (Player)
	avatar_left = TextureRect.new()
	avatar_left.custom_minimum_size = Vector2(48, 48)
	avatar_left.size = Vector2(48, 48)
	avatar_left.position = Vector2(2, -34)
	avatar_left.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box_container.add_child(avatar_left)

	name_badge_left = _create_name_badge()
	name_badge_left.position = Vector2(54, -14)
	name_label_left = name_badge_left.get_child(0).get_child(0) as Label
	box_container.add_child(name_badge_left)

	# Avatar & Badge Kanan (Misterius)
	avatar_right = TextureRect.new()
	avatar_right.custom_minimum_size = Vector2(48, 48)
	avatar_right.size = Vector2(48, 48)
	avatar_right.position = Vector2(DIALOGUE_BOX_SIZE.x - 50, -34)
	avatar_right.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box_container.add_child(avatar_right)

	name_badge_right = _create_name_badge()
	name_badge_right.position = Vector2(DIALOGUE_BOX_SIZE.x - 154, -14)
	name_label_right = name_badge_right.get_child(0).get_child(0) as Label
	box_container.add_child(name_badge_right)

	# 3. Tombol Klik Transparan (Hanya melapisi kotak dialog saja)
	click_catcher_btn = Button.new()
	click_catcher_btn.flat = true
	click_catcher_btn.position = Vector2(0, -36)
	click_catcher_btn.size = Vector2(DIALOGUE_BOX_SIZE.x, DIALOGUE_BOX_SIZE.y + 36)
	click_catcher_btn.focus_mode = Control.FOCUS_NONE
	click_catcher_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	click_catcher_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	click_catcher_btn.pressed.connect(advance_dialogue)
	box_container.add_child(click_catcher_btn)


func _create_name_badge() -> PanelContainer:
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(96, 20)
	var st := StyleBoxFlat.new()
	st.bg_color = COL_HEADER_BG
	st.set_border_width_all(1)
	st.border_color = COL_BORDER_GOLD
	badge.add_theme_stylebox_override("panel", st)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	badge.add_child(margin)

	var lbl := Label.new()
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	margin.add_child(lbl)
	return badge


func _apply_fonts_with_manager() -> void:
	var font_mgr: Node = get_node_or_null("/root/FontManager")
	if not font_mgr:
		return

	if text_label:
		font_mgr.apply(text_label, font_mgr.Type.BODY, 10, COL_TEXT_CONTENT)
	if name_label_left:
		font_mgr.apply(name_label_left, font_mgr.Type.BODY_BOLD, 9, COL_BORDER_GOLD)
	if name_label_right:
		font_mgr.apply(name_label_right, font_mgr.Type.BODY_BOLD, 9, COL_BORDER_GOLD)
	if continue_indicator:
		font_mgr.apply(continue_indicator, font_mgr.Type.RETRO_ALT, 8, COL_BORDER_GOLD)


# ==============================================================================
# LOGIKA ANTREAN DIALOG
# ==============================================================================

func start_dialogue(lines: Array[Dictionary]) -> void:
	if lines.is_empty() or is_active:
		return

	is_dialogue_open = true
	dialogue_queue = lines.duplicate()
	is_active = true
	is_closing = false
	last_speaker_side = ""
	visible = true

	# Kunci dan hentikan total langkah player
	Player.joystick_vector = Vector2.ZERO
	Player.is_sprint_pressed = false
	var player_node := get_tree().current_scene.find_child("Player", true, false)
	if player_node:
		player_node.velocity = Vector2.ZERO

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

	if is_typing:
		_finish_typing()
		return

	if not dialogue_queue.is_empty():
		_play_next_line()
	else:
		_close_dialogue()


func _play_next_line() -> void:
	var line: Dictionary = dialogue_queue.pop_front()
	full_current_text = line.get("text", "")
	var speaker: String = line.get("speaker", "Rian")
	var side: String = line.get("side", "left")
	var expr: String = line.get("expression", "biasa")
	typewriter_speed = line.get("speed", 36.0)

	_apply_speaker_visual(speaker, side, expr)

	text_label.text = full_current_text
	text_label.visible_characters = 0
	visible_chars_count = 0.0
	last_char_index = 0
	is_typing = true
	_stop_indicator_blink()


func _apply_speaker_visual(speaker_name: String, side: String, expression: String) -> void:
	var tex: Texture2D = _resolve_expression_texture(speaker_name, expression)

	if side == "left":
		avatar_left.visible = (tex != null)
		avatar_left.texture = tex
		avatar_left.flip_h = false
		name_badge_left.visible = true
		name_label_left.text = speaker_name.to_upper()

		avatar_right.visible = false
		name_badge_right.visible = false

		if last_speaker_side != "left":
			_animate_portrait_pop(avatar_left, name_badge_left, Vector2(2, -34), Vector2(54, -14))
	else:
		avatar_right.visible = (tex != null)
		avatar_right.texture = tex
		avatar_right.flip_h = true
		name_badge_right.visible = true
		name_label_right.text = speaker_name.to_upper()

		avatar_left.visible = false
		name_badge_left.visible = false

		if last_speaker_side != "right":
			_animate_portrait_pop(avatar_right, name_badge_right, Vector2(DIALOGUE_BOX_SIZE.x - 50, -34), Vector2(DIALOGUE_BOX_SIZE.x - 154, -14))

	last_speaker_side = side


func _animate_portrait_pop(avatar: Control, badge: Control, target_av_pos: Vector2, target_bg_pos: Vector2) -> void:
	if portrait_tween and portrait_tween.is_valid():
		portrait_tween.kill()

	avatar.position = target_av_pos + Vector2(0, 6)
	avatar.modulate.a = 0.3
	badge.position = target_bg_pos + Vector2(0, 4)

	portrait_tween = create_tween().set_parallel(true)
	portrait_tween.tween_property(avatar, "position", target_av_pos, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	portrait_tween.tween_property(avatar, "modulate:a", 1.0, 0.15)
	portrait_tween.tween_property(badge, "position", target_bg_pos, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _resolve_expression_texture(speaker: String, expression: String) -> Texture2D:
	var clean_name: String = speaker.to_lower()
	var path: String = ""

	if clean_name == "rian":
		path = RIAN_EXPR_DIR + "rian_kepala_" + expression + ".png"
		if not ResourceLoader.exists(path):
			path = RIAN_EXPR_DIR + "rian_kepala_biasa.png"
	elif "misteri" in clean_name or "stranger" in clean_name or "sosok" in clean_name:
		path = MISTERIUS_EXPR_DIR + "misterius_kepala.png"

	if path != "" and ResourceLoader.exists(path):
		return load(path)
	return null


func _finish_typing() -> void:
	is_typing = false
	text_label.visible_characters = -1
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
