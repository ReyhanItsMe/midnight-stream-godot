class_name MenuButtonStyler
extends RefCounted

static func apply_variant(button: Button, variant: GameMenuButton.Variant) -> void:
	button.add_theme_color_override("font_color", Color(0.9, 0.92, 0.95))
	button.add_theme_color_override("font_focus_color", Color(0.9, 0.92, 0.95))

	var bg_color := Color(0.06, 0.07, 0.11, 0.88)
	var border_color := Color(0.32, 0.35, 0.44, 0.9)
	var hover_border := Color(0.85, 0.25, 0.2)
	var hover_bg := Color(0.12, 0.08, 0.12, 0.95)
	var hover_font := Color(1.0, 0.35, 0.3)

	match variant:
		GameMenuButton.Variant.ACCENT:
			border_color = Color(0.65, 0.55, 0.22, 0.9)
			hover_border = Color(0.95, 0.82, 0.25)
			hover_bg = Color(0.14, 0.12, 0.06, 0.95)
			hover_font = Color(0.95, 0.82, 0.25)
		GameMenuButton.Variant.DANGER:
			border_color = Color(0.6, 0.15, 0.15, 0.9)
			hover_border = Color(0.95, 0.2, 0.2)
			hover_bg = Color(0.18, 0.05, 0.05, 0.95)
			hover_font = Color(1.0, 0.4, 0.4)
		GameMenuButton.Variant.GHOST:
			bg_color = Color(0, 0, 0, 0)
			border_color = Color(0, 0, 0, 0)
			hover_bg = Color(0.1, 0.1, 0.15, 0.5)
			hover_border = Color(0.4, 0.45, 0.55, 0.5)

	button.add_theme_color_override("font_hover_color", hover_font)
	button.add_theme_color_override("font_pressed_color", hover_font.darkened(0.2))

	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = bg_color
	style_normal.set_border_width_all(1)
	style_normal.border_color = border_color

	var style_hover := style_normal.duplicate()
	style_hover.bg_color = hover_bg
	style_hover.border_color = hover_border

	var style_pressed := style_hover.duplicate()
	style_pressed.bg_color = hover_bg.darkened(0.25)

	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
	button.add_theme_stylebox_override("focus", style_normal)
