extends Button
class_name GameMenuButton

# --- ENUMS ---
enum Variant {
	DEFAULT,   # Border abu-kebiruan, hover crimson horror
	ACCENT,    # Border emas kusam
	DANGER,    # Border merah darah
	GHOST      # Tanpa background
}

enum IconAlignMode {
	LEFT,
	RIGHT,
	CENTER
}

# --- CONSTANTS ---
const DEFAULT_SFX_PATH: String = "res://assets/audio/sfx/sfx-click-button.mp3"

# Kecepatan Playback SFX (1.35 = ~35% lebih cepat dan renyah)
const SFX_PITCH_FAST: float = 1.35

# Animasi Klik
const CLICK_SCALE_DOWN: Vector2 = Vector2(0.95, 0.95)
const CLICK_PIXEL_OFFSET_Y: float = 1.5
const PRESS_TWEEN_DURATION: float = 0.06
const RELEASE_TWEEN_DURATION: float = 0.12

# --- EXPORT PROPERTIES ---
@export_group("Layout & Size")
@export var button_size: Vector2 = Vector2(196, 24):
	set(val):
		button_size = val
		custom_minimum_size = val
		_update_pivot()

@export var font_size_override: int = 10:
	set(val):
		font_size_override = val
		_update_font()

@export_group("Visual Style")
@export var variant: Variant = Variant.DEFAULT:
	set(val):
		variant = val
		_apply_theme_styles()

@export_group("Icon Settings")
@export var icon_texture: Texture2D = null:
	set(val):
		icon_texture = val
		_setup_icon()

@export var icon_alignment_mode: IconAlignMode = IconAlignMode.LEFT:
	set(val):
		icon_alignment_mode = val
		_setup_icon()

@export_group("Audio")
@export var enable_sfx: bool = true
@export var custom_sfx: AudioStream = null

var sfx_player: AudioStreamPlayer
var anim_tween: Tween

func _ready() -> void:
	custom_minimum_size = button_size
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	_update_pivot()
	_update_font()
	_apply_theme_styles()
	_setup_icon()
	_setup_audio()

	# Signal animasi tombol
	button_down.connect(_on_button_down_anim)
	button_up.connect(_on_button_up_anim)
	pressed.connect(_on_pressed_internal)


func _update_pivot() -> void:
	pivot_offset = custom_minimum_size / 2.0


# ==============================================================================
# CONFIGURATION HELPERS
# ==============================================================================

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


# ==============================================================================
# ANIMASI TEKAN / KLIK (PRESS & RELEASE TWEEN)
# ==============================================================================

func _on_button_down_anim() -> void:
	if anim_tween and anim_tween.is_valid():
		anim_tween.kill()

	anim_tween = create_tween().set_parallel(true)
	anim_tween.tween_property(self, "scale", CLICK_SCALE_DOWN, PRESS_TWEEN_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	anim_tween.tween_property(self, "position:y", position.y + CLICK_PIXEL_OFFSET_Y, PRESS_TWEEN_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_button_up_anim() -> void:
	if anim_tween and anim_tween.is_valid():
		anim_tween.kill()

	anim_tween = create_tween().set_parallel(true)
	anim_tween.tween_property(self, "scale", Vector2.ONE, RELEASE_TWEEN_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	anim_tween.tween_property(self, "position:y", position.y - CLICK_PIXEL_OFFSET_Y, RELEASE_TWEEN_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


# ==============================================================================
# FONT & THEME STYLING
# ==============================================================================

func _update_font() -> void:
	if Engine.has_singleton("FontManager") or get_node_or_null("/root/FontManager") != null:
		FontManager.apply(self, FontManager.Type.BODY_BOLD, font_size_override, Color(0.9, 0.92, 0.95))
	else:
		add_theme_font_size_override("font_size", font_size_override)


func _setup_icon() -> void:
	if icon_texture:
		icon = icon_texture
		expand_icon = true
		match icon_alignment_mode:
			IconAlignMode.LEFT:
				icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
			IconAlignMode.RIGHT:
				icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			IconAlignMode.CENTER:
				icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	else:
		icon = null


func _apply_theme_styles() -> void:
	add_theme_color_override("font_color", Color(0.9, 0.92, 0.95))
	add_theme_color_override("font_focus_color", Color(0.9, 0.92, 0.95))

	var bg_color := Color(0.06, 0.07, 0.11, 0.88)
	var border_color := Color(0.32, 0.35, 0.44, 0.9)
	var hover_border := Color(0.85, 0.25, 0.2)
	var hover_bg := Color(0.12, 0.08, 0.12, 0.95)
	var hover_font := Color(1.0, 0.35, 0.3)

	match variant:
		Variant.ACCENT:
			border_color = Color(0.65, 0.55, 0.22, 0.9)
			hover_border = Color(0.95, 0.82, 0.25)
			hover_bg = Color(0.14, 0.12, 0.06, 0.95)
			hover_font = Color(0.95, 0.82, 0.25)
		Variant.DANGER:
			border_color = Color(0.6, 0.15, 0.15, 0.9)
			hover_border = Color(0.95, 0.2, 0.2)
			hover_bg = Color(0.18, 0.05, 0.05, 0.95)
			hover_font = Color(1.0, 0.4, 0.4)
		Variant.GHOST:
			bg_color = Color(0, 0, 0, 0)
			border_color = Color(0, 0, 0, 0)
			hover_bg = Color(0.1, 0.1, 0.15, 0.5)
			hover_border = Color(0.4, 0.45, 0.55, 0.5)

	add_theme_color_override("font_hover_color", hover_font)
	add_theme_color_override("font_pressed_color", hover_font.darkened(0.2))

	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = bg_color
	style_normal.set_border_width_all(1)
	style_normal.border_color = border_color

	var style_hover := style_normal.duplicate()
	style_hover.bg_color = hover_bg
	style_hover.border_color = hover_border

	var style_pressed := style_hover.duplicate()
	style_pressed.bg_color = hover_bg.darkened(0.25)

	add_theme_stylebox_override("normal", style_normal)
	add_theme_stylebox_override("hover", style_hover)
	add_theme_stylebox_override("pressed", style_pressed)
	add_theme_stylebox_override("focus", style_normal)


# ==============================================================================
# AUDIO (CLICK SFX SPEEDUP)
# ==============================================================================

func _setup_audio() -> void:
	if not enable_sfx:
		return

	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "SFX"
	# Menaikkan pitch scale agar durasi playback lebih pendek dan instan
	sfx_player.pitch_scale = SFX_PITCH_FAST

	if custom_sfx:
		sfx_player.stream = custom_sfx
	elif ResourceLoader.exists(DEFAULT_SFX_PATH):
		sfx_player.stream = load(DEFAULT_SFX_PATH)

	add_child(sfx_player)


func _on_pressed_internal() -> void:
	if enable_sfx and sfx_player and sfx_player.stream:
		# Restart SFX jika diklik beruntun tanpa terpotong error
		sfx_player.stop()
		sfx_player.play()
