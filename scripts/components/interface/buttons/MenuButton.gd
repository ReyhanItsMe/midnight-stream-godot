class_name GameMenuButton
extends Button

enum Variant { DEFAULT, ACCENT, DANGER, GHOST }
enum IconAlignMode { LEFT, RIGHT, CENTER }

@export_group("Layout & Size")
@export var button_size: Vector2 = Vector2(196, 24):
	set(val):
		button_size = val
		custom_minimum_size = val
		pivot_offset = val / 2.0

@export var font_size_override: int = 10:
	set(val):
		font_size_override = val
		_update_font()

@export_group("Visual Style")
@export var variant: Variant = Variant.DEFAULT:
	set(val):
		variant = val
		MenuButtonStyler.apply_variant(self, variant)

@export_group("Icon Settings")
@export var icon_texture: Texture2D = null:
	set(val):
		icon_texture = val
		_setup_icon()

@export var icon_alignment_mode: IconAlignMode = IconAlignMode.LEFT:
	set(val):
		icon_alignment_mode = val
		_setup_icon()

@export_group("Audio Feedback")
@export var enable_sfx: bool = true
@export var custom_sfx: AudioStream = null

var feedback: UIButtonFeedback

func _ready() -> void:
	custom_minimum_size = button_size
	pivot_offset = button_size / 2.0
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	_update_font()
	MenuButtonStyler.apply_variant(self, variant)
	_setup_icon()
	_setup_feedback()

func _setup_feedback() -> void:
	feedback = UIButtonFeedback.new()
	feedback.name = "FeedbackAtom"
	feedback.enable_sfx = enable_sfx
	feedback.custom_sfx = custom_sfx
	add_child(feedback)

func _update_font() -> void:
	if not is_inside_tree():
		add_theme_font_size_override("font_size", font_size_override)
		return

	var font_mgr: Node = get_node_or_null("/root/FontManager")
	if font_mgr and font_mgr.has_method("apply"):
		font_mgr.apply(self, 1, font_size_override, Color(0.9, 0.92, 0.95))
	else:
		add_theme_font_size_override("font_size", font_size_override)

func _setup_icon() -> void:
	icon = icon_texture
	expand_icon = icon_texture != null
	match icon_alignment_mode:
		IconAlignMode.LEFT: icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		IconAlignMode.RIGHT: icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		IconAlignMode.CENTER: icon_alignment = HORIZONTAL_ALIGNMENT_CENTER

func set_dimensions(width: float, height: float) -> GameMenuButton:
	self.button_size = Vector2(width, height)
	return self

func set_icon_texture(texture: Texture2D, align: IconAlignMode = IconAlignMode.LEFT) -> GameMenuButton:
	self.icon_texture = texture
	self.icon_alignment_mode = align
	return self

func set_variant(new_variant: Variant) -> GameMenuButton:
	self.variant = new_variant
	return self
