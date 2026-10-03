## Widget UI baris pengaturan bertipe stepper minus-plus (- / +) untuk volume dan opsi numerik.
##
## Cara pakai:
##   var bgm_row = StepperSettingRow.new("VOLUME BGM", "80%")
##   add_child(bgm_row)
##   bgm_row.value_decreased.connect(func(): _kurangi_volume())
##   bgm_row.value_increased.connect(func(): _tambah_volume())
##   bgm_row.set_value_text("90%")
class_name StepperSettingRow
extends HBoxContainer

signal value_decreased
signal value_increased

const COL_TEXT_WHITE: Color = Color(0.92, 0.94, 0.97, 1.0)
const COL_GOLD: Color = Color(0.95, 0.82, 0.25, 1.0)

var lbl_title: Label
var lbl_value: Label
var btn_minus: GameMenuButton
var btn_plus: GameMenuButton

func _init(title_text: String = "", initial_val: String = "") -> void:
	custom_minimum_size = Vector2(250, 22)
	alignment = BoxContainer.ALIGNMENT_CENTER

	lbl_title = Label.new()
	lbl_title.text = title_text
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(lbl_title, 9, COL_TEXT_WHITE)
	add_child(lbl_title)

	var controls_hbox := HBoxContainer.new()
	controls_hbox.add_theme_constant_override("separation", 6)
	add_child(controls_hbox)

	btn_minus = _build_btn("-")
	btn_minus.pressed.connect(func(): value_decreased.emit())
	controls_hbox.add_child(btn_minus)

	lbl_value = Label.new()
	lbl_value.text = initial_val
	lbl_value.custom_minimum_size = Vector2(44, 20)
	lbl_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_font(lbl_value, 9, COL_GOLD)
	controls_hbox.add_child(lbl_value)

	btn_plus = _build_btn("+")
	btn_plus.pressed.connect(func(): value_increased.emit())
	controls_hbox.add_child(btn_plus)

func set_value_text(text: String) -> void:
	lbl_value.text = text

func _build_btn(txt: String) -> GameMenuButton:
	var btn := GameMenuButton.new()
	btn.text = txt
	btn.set_dimensions(22, 20)
	btn.font_size_override = 9
	btn.set_variant(GameMenuButton.Variant.ACCENT)
	return btn

func _apply_font(lbl: Label, f_size: int, col: Color) -> void:
	# Cek apakah autoload FontManager tersedia secara global
	var font_mgr = Engine.get_main_loop().root.get_node_or_null("FontManager") if Engine.get_main_loop() and Engine.get_main_loop().has_method("get_root") else null
	if font_mgr and font_mgr.has_method("apply"):
		font_mgr.apply(lbl, 1, f_size, col)
	else:
		lbl.add_theme_font_size_override("font_size", f_size)
		lbl.add_theme_color_override("font_color", col)
