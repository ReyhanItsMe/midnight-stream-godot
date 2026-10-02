class_name DialoguePortrait
extends Control

const COL_BORDER_GOLD: Color = Color(0.95, 0.82, 0.25, 0.95)
const COL_HEADER_BG: Color = Color(0.09, 0.10, 0.16, 1.0)

const RIAN_EXPR_DIR: String = "res://assets/sprites/characters/rian/expressions/"
const MISTERIUS_EXPR_DIR: String = "res://assets/sprites/characters/mistery/expressions/"

var avatar_rect: TextureRect
var name_badge: PanelContainer
var name_label: Label
var portrait_tween: Tween

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()

func _build_ui() -> void:
	avatar_rect = TextureRect.new()
	avatar_rect.custom_minimum_size = Vector2(48, 48)
	avatar_rect.size = Vector2(48, 48)
	avatar_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(avatar_rect)

	name_badge = PanelContainer.new()
	name_badge.custom_minimum_size = Vector2(96, 20)
	name_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st := StyleBoxFlat.new()
	st.bg_color = COL_HEADER_BG
	st.set_border_width_all(1)
	st.border_color = COL_BORDER_GOLD
	name_badge.add_theme_stylebox_override("panel", st)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_badge.add_child(margin)

	name_label = Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	margin.add_child(name_label)
	add_child(name_badge)

	_apply_font(name_label, 9, COL_BORDER_GOLD)

func setup_speaker(speaker: String, expression: String, is_left: bool, box_width: float, animate: bool) -> void:
	var tex := _resolve_expression_texture(speaker, expression)
	avatar_rect.visible = (tex != null)
	avatar_rect.texture = tex
	avatar_rect.flip_h = not is_left

	name_badge.visible = true
	name_label.text = speaker.to_upper()

	var target_av_pos := Vector2(2, -34) if is_left else Vector2(box_width - 50, -34)
	var target_bg_pos := Vector2(54, -14) if is_left else Vector2(box_width - 154, -14)

	if animate:
		if portrait_tween and portrait_tween.is_valid():
			portrait_tween.kill()

		avatar_rect.position = target_av_pos + Vector2(0, 6)
		avatar_rect.modulate.a = 0.3
		name_badge.position = target_bg_pos + Vector2(0, 4)

		portrait_tween = create_tween().set_parallel(true)
		portrait_tween.tween_property(avatar_rect, "position", target_av_pos, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		portrait_tween.tween_property(avatar_rect, "modulate:a", 1.0, 0.15)
		portrait_tween.tween_property(name_badge, "position", target_bg_pos, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		avatar_rect.position = target_av_pos
		avatar_rect.modulate.a = 1.0
		name_badge.position = target_bg_pos

func hide_all() -> void:
	avatar_rect.visible = false
	name_badge.visible = false

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

func _apply_font(lbl: Label, f_size: int, col: Color) -> void:
	var root_node = Engine.get_main_loop().root if Engine.get_main_loop() else null
	var font_mgr = root_node.get_node_or_null("FontManager") if root_node else null
	if font_mgr and font_mgr.has_method("apply"):
		font_mgr.apply(lbl, 1, f_size, col)
	else:
		lbl.add_theme_font_size_override("font_size", f_size)
		lbl.add_theme_color_override("font_color", col)
