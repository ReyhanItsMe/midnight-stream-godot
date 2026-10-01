class_name BaseModal
extends Control

signal closed

const MENU_BUTTON_SCENE: PackedScene = preload("res://scenes/components/interface/buttons/MenuButton.tscn")
const COLOR_RED_CLOSE: Color = Color(0.85, 0.22, 0.22)
const COLOR_MODAL_BG: Color = Color(0.05, 0.06, 0.09, 0.98)
const COLOR_GOLD: Color = Color(0.95, 0.82, 0.25)

@export var box_size: Vector2 = Vector2(260.0, 118.0)

var modal_box: PanelContainer
var content_container: VBoxContainer
var btn_close_x: GameMenuButton
var animator: ModalAnimator

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	modulate.a = 0.0
	
	animator = ModalAnimator.new()
	add_child(animator)
	
	_build_base_ui()
	_build_content()

func _build_base_ui() -> void:
	# 1. Dimmer Background
	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.0, 0.0, 0.0, 0.72)
	add_child(dimmer)

	# 2. Kotak Modal Tengah
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	modal_box = PanelContainer.new()
	modal_box.custom_minimum_size = box_size
	set_border_color(COLOR_GOLD)
	center.add_child(modal_box)

	content_container = VBoxContainer.new()
	content_container.alignment = BoxContainer.ALIGNMENT_CENTER
	content_container.add_theme_constant_override("separation", 8)
	modal_box.add_child(content_container)

	# 3. Tombol [X] Melayang
	btn_close_x = MENU_BUTTON_SCENE.instantiate()
	btn_close_x.text = "X"
	btn_close_x.set_dimensions(24, 24)
	btn_close_x.set_variant(GameMenuButton.Variant.DANGER)
	_style_round_close_button(btn_close_x)

	btn_close_x.anchor_left = 0.5
	btn_close_x.anchor_right = 0.5
	btn_close_x.anchor_top = 0.5
	btn_close_x.anchor_bottom = 0.5
	btn_close_x.offset_left = -12.0
	btn_close_x.offset_right = 12.0
	btn_close_x.offset_top = (box_size.y / 2.0) + 10.0
	btn_close_x.offset_bottom = (box_size.y / 2.0) + 34.0
	btn_close_x.pressed.connect(close)
	add_child(btn_close_x)

# Virtual method untuk di-override child class
func _build_content() -> void:
	pass

func open_modal() -> void:
	animator.animate_open(self, modal_box)

func close() -> void:
	animator.animate_close(self, func(): closed.emit())

func set_border_color(color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_MODAL_BG
	style.set_border_width_all(1)
	style.border_color = color
	modal_box.add_theme_stylebox_override("panel", style)

func _style_round_close_button(btn: GameMenuButton) -> void:
	var round_normal := StyleBoxFlat.new()
	round_normal.bg_color = Color(0.1, 0.05, 0.07, 0.9)
	round_normal.set_border_width_all(1)
	round_normal.border_color = COLOR_RED_CLOSE
	round_normal.set_corner_radius_all(12)

	var round_hover := round_normal.duplicate()
	round_hover.bg_color = Color(0.25, 0.06, 0.08, 0.98)
	round_hover.border_color = Color(1.0, 0.35, 0.35)

	btn.add_theme_color_override("font_color", COLOR_RED_CLOSE)
	btn.add_theme_stylebox_override("normal", round_normal)
	btn.add_theme_stylebox_override("hover", round_hover)
	btn.add_theme_stylebox_override("pressed", round_hover)
	btn.add_theme_stylebox_override("focus", round_normal)
