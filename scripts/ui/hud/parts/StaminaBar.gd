class_name StaminaBar
extends ProgressBar

const STAMINA_BAR_HEIGHT: float = 4.0
var stamina_fill_style: StyleBoxFlat
var player_ref: Node = null

func _ready() -> void:
	show_percentage = false
	fill_mode = ProgressBar.FILL_END_TO_BEGIN
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Desain style bar
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Palette.BLACK_MODAL
	
	stamina_fill_style = StyleBoxFlat.new()
	stamina_fill_style.bg_color = Palette.YELLOW
	
	add_theme_stylebox_override("background", bg_style)
	add_theme_stylebox_override("fill", stamina_fill_style)

	# Pastikan ukuran dan posisi bar menempel di tepi bawah viewport
	get_viewport().size_changed.connect(_reposition_bar)
	call_deferred("_reposition_bar")

func _reposition_bar() -> void:
	var vp_size: Vector2 = get_viewport_rect().size
	if vp_size == Vector2.ZERO:
		vp_size = Vector2(640, 360)
		
	# Bentangkan di sepanjang tepi bawah layar
	position = Vector2(0, vp_size.y - STAMINA_BAR_HEIGHT)
	size = Vector2(vp_size.x, STAMINA_BAR_HEIGHT)
	custom_minimum_size = Vector2(vp_size.x, STAMINA_BAR_HEIGHT)

func _process(_delta: float) -> void:
	# Cari player jika belum tersambung
	if not player_ref or not is_instance_valid(player_ref):
		var cur_scene := get_tree().current_scene
		if cur_scene:
			player_ref = cur_scene.find_child("Player", true, false)
		if not player_ref:
			return

		if "MAX_STAMINA" in player_ref:
			max_value = player_ref.MAX_STAMINA

	# Ambil data stamina real-time dari karakter
	var cur_stamina: float = 100.0
	if "current_stamina" in player_ref:
		cur_stamina = player_ref.current_stamina

	value = cur_stamina

	# Efek warna habis / pulih
	if cur_stamina <= 0.0:
		stamina_fill_style.bg_color = Palette.RED
	elif cur_stamina >= 25.0:
		stamina_fill_style.bg_color = Palette.YELLOW
