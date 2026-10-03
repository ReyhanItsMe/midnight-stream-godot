extends ProgressBar

const STAMINA_BAR_HEIGHT: float = 3.0
var stamina_fill_style: StyleBoxFlat
var player_ref: Node = null

func _ready() -> void:
	set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	offset_top = -STAMINA_BAR_HEIGHT
	offset_bottom = 0
	show_percentage = false
	fill_mode = ProgressBar.FILL_END_TO_BEGIN
	
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Palette.BLACK_MODAL
	stamina_fill_style = StyleBoxFlat.new()
	stamina_fill_style.bg_color = Palette.YELLOW
	
	add_theme_stylebox_override("background", bg_style)
	add_theme_stylebox_override("fill", stamina_fill_style)

func _process(_delta: float) -> void:
	if not player_ref:
		player_ref = get_node_or_null("/root/Player") 
		if not player_ref: return
		
		if "MAX_STAMINA" in player_ref:
			max_value = player_ref.MAX_STAMINA
	
	var cur_stamina: float = 100.0
	if "current_stamina" in player_ref:
		cur_stamina = player_ref.current_stamina
		
	value = cur_stamina
	
	if cur_stamina <= 0.0:
		stamina_fill_style.bg_color = Palette.RED
	elif cur_stamina >= 25.0:
		stamina_fill_style.bg_color = Palette.YELLOW
