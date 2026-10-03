## Manager terpusat untuk memuat, menyimpan cache, dan menerapkan Tipografi UI.
##
## Cara pakai:
##   FontManager.apply(my_label, FontManager.Type.BODY, 8, Color.WHITE)
##   FontManager.apply(my_btn, FontManager.Type.BODY_BOLD, 10, Palette.GOLD)
##   var raw_font: Font = FontManager.get_font(FontManager.Type.TITLE)
class_name FontManagerClass
extends Node

enum Type {
	BODY,      # PixelifySans-Regular (Teks umum, dialog, instruksi)
	BODY_BOLD, # PixelifySans-Bold (Tombol aksi, teks penting)
	TITLE,     # Pix32 / Jersey (Header menu, judul game)
	DIGITAL,   # Handjet-Regular (Jam, counter slot, koordinat)
	RETRO_ALT, # Geist-Pixel (Subtitle, meta log)
	GOTHIC     # Pixelta / Jacquard (Lore sanatorium, surat kuno)
}

var fonts: Dictionary = {}

func _ready() -> void:
	_load_all_fonts()

func _load_all_fonts() -> void:
	fonts[Type.BODY] = _load_font_safe(AssetPaths.Fonts.PIXELIFY_REGULAR)
	fonts[Type.BODY_BOLD] = _load_font_safe(AssetPaths.Fonts.PIXELIFY_BOLD, fonts[Type.BODY])
	fonts[Type.TITLE] = _load_font_safe(AssetPaths.Fonts.PIX32, fonts[Type.BODY])
	fonts[Type.DIGITAL] = _load_font_safe(AssetPaths.Fonts.HANDJET_REGULAR, fonts[Type.BODY])
	fonts[Type.RETRO_ALT] = _load_font_safe(AssetPaths.Fonts.GEIST_PIXEL, fonts[Type.BODY])
	fonts[Type.GOTHIC] = _load_font_safe(AssetPaths.Fonts.PIXELTA, fonts[Type.BODY])

func _load_font_safe(path: String, fallback: Font = null) -> Font:
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Font:
			return res
	return fallback

## Mengambil objek Font mentah
func get_font(type: Type = Type.BODY) -> Font:
	if fonts.has(type) and fonts[type] != null:
		return fonts[type]
	return fonts.get(Type.BODY, null)

## Helper serbaguna untuk menerapkan Font, Ukuran, dan Warna ke Control Node (Label, Button, RichTextLabel)
func apply(control: Control, font_type: Type = Type.BODY, font_size: int = 10, color: Color = Color.WHITE) -> void:
	if not control:
		return

	var chosen_font: Font = get_font(font_type)

	if control is Label:
		if chosen_font:
			control.add_theme_font_override("font", chosen_font)
		control.add_theme_font_size_override("font_size", font_size)
		control.add_theme_color_override("font_color", color)

	elif control is Button:
		if chosen_font:
			control.add_theme_font_override("font", chosen_font)
		control.add_theme_font_size_override("font_size", font_size)
		control.add_theme_color_override("font_color", color)
		control.add_theme_color_override("font_hover_color", color)
		control.add_theme_color_override("font_pressed_color", color)
		control.add_theme_color_override("font_focus_color", color)

	elif control is RichTextLabel:
		if chosen_font:
			control.add_theme_font_override("normal_font", chosen_font)
		control.add_theme_font_size_override("normal_font_size", font_size)
		control.add_theme_color_override("default_color", color)
