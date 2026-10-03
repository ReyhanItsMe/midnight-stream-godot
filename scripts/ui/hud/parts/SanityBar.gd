class_name SanityBar
extends MarginContainer

const SANITY_BAR_SIZE: Vector2 = Vector2(96, 6)
const PULSE_DURATION: float = 0.4

var sanity_bar: ProgressBar
var lbl_sanity: Label
var sanity_pulse_tween: Tween

func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	offset_left = 12
	offset_top = 10
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	add_child(vbox)
	
	lbl_sanity = Label.new()
	lbl_sanity.text = "SANITY // 100%"
	FontManager.apply(lbl_sanity, FontManager.Type.DIGITAL, 12, Palette.CYAN)
	vbox.add_child(lbl_sanity)
	
	sanity_bar = ProgressBar.new()
	sanity_bar.custom_minimum_size = SANITY_BAR_SIZE
	sanity_bar.show_percentage = false
	sanity_bar.min_value = 0.0
	sanity_bar.max_value = 100.0
	sanity_bar.value = 100.0
	
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Palette.BLACK_MODAL
	bg_style.set_border_width_all(1)
	bg_style.border_color = Palette.SLATE
	
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Palette.CYAN
	
	sanity_bar.add_theme_stylebox_override("background", bg_style)
	sanity_bar.add_theme_stylebox_override("fill", fill_style)
	vbox.add_child(sanity_bar)
	
	if SaveManager:
		SaveManager.sanity_changed.connect(_on_sanity_changed)
		SaveManager.sanity_critical.connect(_on_sanity_critical)
		var init_sanity: float = SaveManager.get_current_sanity()
		_on_sanity_changed(init_sanity, SaveManager.MAX_SANITY)

func _on_sanity_changed(val: float, max_val: float) -> void:
	sanity_bar.value = val
	lbl_sanity.text = "SANITY // %d%%" % int((val / max_val) * 100)

func _on_sanity_critical(is_critical: bool) -> void:
	if is_critical:
		if sanity_pulse_tween and sanity_pulse_tween.is_valid():
			sanity_pulse_tween.kill()
		sanity_pulse_tween = create_tween().set_loops()
		sanity_pulse_tween.tween_property(sanity_bar, "modulate", Palette.RED, PULSE_DURATION)
		sanity_pulse_tween.tween_property(sanity_bar, "modulate", Palette.WHITE, PULSE_DURATION)
	else:
		if sanity_pulse_tween and sanity_pulse_tween.is_valid():
			sanity_pulse_tween.kill()
		sanity_bar.modulate = Palette.WHITE
