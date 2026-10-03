## Kelas dasar untuk semua jendela modal UI dengan backdrop dimmer gelap, tombol tutup [X], dan animasi pop-up.
##
## Cara pakai (Inheritance):
##   class_name MyCustomModal extends BaseModal
##   func _build_content() -> void:
##       # Isi elemen UI ke content_container
##       pass
##
## Cara buka / tutup dari script luar:
##   my_modal.open_modal()
##   my_modal.close()
class_name BaseModal
extends Control

signal closed

# Jarak antara kotak popup dan tombol [X] di bawahnya
const CLOSE_BUTTON_GAP: int = 10
# Sisa ruang di tepi bawah layar agar modal tidak mepet
const BOTTOM_MARGIN: int = 8

@export var box_size: Vector2 = Vector2(260.0, 118.0)
# Area atas layar yang dipakai HUD (tombol pause dll). Modal ditaruh di bawah area ini.
@export var top_reserved: float = 36.0

var modal_box: PanelContainer
var content_container: VBoxContainer
var btn_close_x: GameMenuButton
var animator: ModalAnimator
var modal_stack: VBoxContainer # kotak modal + tombol X, dianimasikan bersama
var menu_button_scene: PackedScene

func _ready() -> void:
	visible = false
	modulate.a = 0.0

	_load_dependencies()

	# PENTING: ukuran modal diambil dari viewport, BUKAN dari parent.
	# Kalau parent-nya Node2D / Control berukuran 0, anchor FULL_RECT jadi 0x0
	# dan seluruh isi modal numpuk di pojok kiri atas.
	_fit_to_viewport()
	get_viewport().size_changed.connect(_fit_to_viewport)

	animator = ModalAnimator.new()
	add_child(animator)

	_build_base_ui()
	_build_content()

func _load_dependencies() -> void:
	var btn_path: String = ScenePaths.UIComponents.MENU_BUTTON
	if ResourceLoader.exists(btn_path):
		menu_button_scene = load(btn_path)
	else:
		push_error("[BaseModal] Menu button scene tidak ditemukan: " + btn_path)

func _fit_to_viewport() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	global_position = Vector2.ZERO
	size = get_viewport_rect().size

func _build_base_ui() -> void:
	# 1. Dimmer Background
	var dimmer := ColorRect.new()
	dimmer.color = Palette.alpha(Palette.BLACK, 0.72)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# 2. Area aman: sisakan ruang di atas (HUD / tombol pause) dan di bawah layar
	var safe_area := MarginContainer.new()
	safe_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe_area.add_theme_constant_override("margin_top", int(top_reserved))
	safe_area.add_theme_constant_override("margin_bottom", BOTTOM_MARGIN)
	add_child(safe_area)
	safe_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# 3. Tengah-kan isi di area aman tadi
	var center_wrapper := CenterContainer.new()
	center_wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe_area.add_child(center_wrapper)

	# 4. Susunan vertikal: [kotak modal] -> jarak -> [tombol X]
	modal_stack = VBoxContainer.new()
	modal_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modal_stack.add_theme_constant_override("separation", CLOSE_BUTTON_GAP)
	modal_stack.resized.connect(func(): modal_stack.pivot_offset = modal_stack.size / 2.0)
	center_wrapper.add_child(modal_stack)

	# Kotak Modal Utama
	modal_box = PanelContainer.new()
	modal_box.custom_minimum_size = box_size
	set_border_color(Palette.GOLD)
	modal_stack.add_child(modal_box)

	content_container = VBoxContainer.new()
	content_container.alignment = BoxContainer.ALIGNMENT_CENTER
	content_container.add_theme_constant_override("separation", 6)
	modal_box.add_child(content_container)

	# Tombol [X] di bawah kotak, tengah, berjarak
	if menu_button_scene:
		btn_close_x = menu_button_scene.instantiate()
		btn_close_x.text = "X"
		btn_close_x.set_dimensions(24, 24)
		btn_close_x.set_variant(GameMenuButton.Variant.DANGER)
		_style_round_close_button(btn_close_x)
		btn_close_x.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn_close_x.pressed.connect(close)
		modal_stack.add_child(btn_close_x)

# Virtual method untuk di-override child class
func _build_content() -> void:
	pass

func open_modal() -> void:
	animator.animate_open(self, modal_stack)

func close() -> void:
	animator.animate_close(self, func(): closed.emit())

func set_border_color(color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.alpha(Palette.BG_MODAL, 0.98)
	style.set_border_width_all(1)
	style.border_color = color
	# Padding internal agar teks tidak menempel ke border
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 14.0
	style.content_margin_bottom = 14.0
	modal_box.add_theme_stylebox_override("panel", style)

func _style_round_close_button(btn: GameMenuButton) -> void:
	var round_normal := StyleBoxFlat.new()
	round_normal.bg_color = Color(0.1, 0.05, 0.07, 0.9)
	round_normal.set_border_width_all(1)
	round_normal.border_color = Palette.RED_ACCENT
	round_normal.set_corner_radius_all(12)

	var round_hover := round_normal.duplicate()
	round_hover.bg_color = Color(0.25, 0.06, 0.08, 0.98)
	round_hover.border_color = Color(1.0, 0.35, 0.35)

	btn.add_theme_color_override("font_color", Palette.RED_ACCENT)
	btn.add_theme_stylebox_override("normal", round_normal)
	btn.add_theme_stylebox_override("hover", round_hover)
	btn.add_theme_stylebox_override("pressed", round_hover)
	btn.add_theme_stylebox_override("focus", round_normal)
