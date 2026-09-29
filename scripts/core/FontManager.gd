extends Node

# --- DAFTAR TIPE FONT ---
enum Type {
	BODY,      # PixelifySans-Regular (Teks umum, dialog, instruksi)
	BODY_BOLD, # PixelifySans-SemiBold / Bold (Tombol aksi, teks penting)
	TITLE,     # Jersey25-Regular (Header menu, arcade, judul besar)
	DIGITAL,   # Handjet-Medium (Jam, counter slot, koordinat, baterai)
	RETRO_ALT, # Geist-Pixel (Subtitle, meta log)
	GOTHIC     # Jacquard-Regular (Lore sanatorium, surat, dokumen kuno)
}

# --- PATHS FONT ASSETS ---
const PATH_BODY: String = "res://assets/fonts/PixelifySans-Regular.ttf"
const PATH_BODY_BOLD: String = "res://assets/fonts/PixelifySans-Bold.ttf"
const PATH_TITLE: String = "res://assets/fonts/Jersey25-Regular.ttf"
const PATH_DIGITAL: String = "res://assets/fonts/Handjet-Medium.ttf"
const PATH_RETRO_ALT: String = "res://assets/fonts/Geist-Pixel.ttf"
const PATH_GOTHIC: String = "res://assets/fonts/Jacquard-Regular.ttf"

# Penyimpanan Font Loaded
var fonts: Dictionary = {}


func _ready() -> void:
	_load_all_fonts()


func _load_all_fonts() -> void:
	fonts[Type.BODY] = _load_font_safe(PATH_BODY)
	fonts[Type.BODY_BOLD] = _load_font_safe(PATH_BODY_BOLD, fonts[Type.BODY])
	fonts[Type.TITLE] = _load_font_safe(PATH_TITLE, fonts[Type.BODY])
	fonts[Type.DIGITAL] = _load_font_safe(PATH_DIGITAL, fonts[Type.BODY])
	fonts[Type.RETRO_ALT] = _load_font_safe(PATH_RETRO_ALT, fonts[Type.BODY])
	fonts[Type.GOTHIC] = _load_font_safe(PATH_GOTHIC, fonts[Type.BODY])


func _load_font_safe(path: String, fallback: Font = null) -> Font:
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Font:
			return res
	return fallback


## Mengambil resource Font mentah jika dibutuhkan secara manual
func get_font(type: Type = Type.BODY) -> Font:
	if fonts.has(type) and fonts[type] != null:
		return fonts[type]
	return fonts.get(Type.BODY, null)


## Helper serbaguna untuk menerapkan Font, Ukuran, dan Warna ke Label / Button
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
