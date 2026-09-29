extends Node2D

const TILE_SIZE: int = 32
const COLOR_TILE_A: Color = Color(0.22, 0.24, 0.30)
const COLOR_TILE_B: Color = Color(0.16, 0.18, 0.24)
const COLOR_TILE_BORDER: Color = Color(0.12, 0.13, 0.18)

@onready var player: Player = $Player
@onready var camera: Camera2D = $Camera2D
@onready var floor_rect: TextureRect = $GridFloor/FloorTiles
@onready var save_point: SavePoint = $SavePoint
@onready var save_modal: SaveModal = $UILayer/SaveModal

func _ready() -> void:
	AudioManager.stop_bgm(0.4)
	_generate_checkerboard_floor()
	_setup_horizontal_darkness_gradient()
	_create_darkness_markers()

	if player:
		# Posisikan player mulai dari sisi kiri ruangan yang masih terang
		player.global_position = Vector2(-220, 20)
		camera.global_position = player.global_position

	if save_point and save_modal:
		save_point.save_station_triggered.connect(save_modal.open)


func _process(_delta: float) -> void:
	if player and camera:
		camera.global_position = player.global_position


## 1. Gradasi Cahaya Ruangan: Terang di Kiri -> Hitam Total di Kanan
func _setup_horizontal_darkness_gradient() -> void:
	var ambient_light := PointLight2D.new()
	ambient_light.name = "AmbientGradientLight"
	ambient_light.position = Vector2(0, 0)
	ambient_light.energy = 1.0
	ambient_light.shadow_enabled = false

	# Gradien horizontal: Kiri cukup terang (0.6), tengah remang (0.15), kanan gelap total (0.0)
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.35, 0.65, 0.85, 1.0])
	grad.colors = PackedColorArray([
		Color(0.65, 0.70, 0.85, 1.0), # X = -320 (Kiri terang berbayang dingin)
		Color(0.35, 0.40, 0.50, 1.0), # X = -100
		Color(0.12, 0.14, 0.20, 1.0), # X = +100 (Mulai remang pekat)
		Color(0.03, 0.03, 0.05, 1.0), # X = +220 (Hampir hitam total)
		Color(0.00, 0.00, 0.00, 1.0)  # X = +320 (Gelap gulita 100%)
	])

	var grad_tex := GradientTexture2D.new()
	grad_tex.gradient = grad
	grad_tex.width = 640
	grad_tex.height = 360
	grad_tex.fill = GradientTexture2D.FILL_LINEAR
	grad_tex.fill_from = Vector2(0.0, 0.5) # Dari tepi kiri
	grad_tex.fill_to = Vector2(1.0, 0.5)   # Ke tepi kanan

	ambient_light.texture = grad_tex
	add_child(ambient_light)


## 2. Marker Penguji Tingkat Kegelapan (5 Pilar Warna dari Kiri ke Kanan)
func _create_darkness_markers() -> void:
	var markers: Array[Dictionary] = [
		{"pos": Vector2(-220, 80), "col": Color(0.2, 0.85, 0.3),  "label": "TERANG (100%)"},
		{"pos": Vector2(-110, 80), "col": Color(0.9, 0.85, 0.2),  "label": "SEDANG (60%)"},
		{"pos": Vector2(0, 80),    "col": Color(0.95, 0.5, 0.1),  "label": "REMANG (30%)"},
		{"pos": Vector2(120, 80),  "col": Color(0.9, 0.2, 0.2),   "label": "GELAP (10%)"},
		{"pos": Vector2(240, 80),  "col": Color(0.6, 0.1, 0.9),   "label": "GELAP TOTAL (0%)"}
	]

	var marker_container := Node2D.new()
	marker_container.name = "DarknessMarkers"
	add_child(marker_container)

	for m in markers:
		# Kotak warna fisik penanda
		var box := ColorRect.new()
		box.size = Vector2(18, 48)
		box.position = m["pos"] - Vector2(9, 24)
		box.color = m["col"]
		marker_container.add_child(box)

		# Label keterangan di bawah kotak
		var lbl := Label.new()
		lbl.text = m["label"]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.position = m["pos"] + Vector2(-60, 28)
		lbl.size = Vector2(120, 20)
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.add_theme_color_override("font_color", m["col"])
		marker_container.add_child(lbl)


func _generate_checkerboard_floor() -> void:
	var pattern_size: int = TILE_SIZE * 2
	var img := Image.create(pattern_size, pattern_size, false, Image.FORMAT_RGBA8)

	for y in range(pattern_size):
		for x in range(pattern_size):
			var is_even_x: bool = (x / TILE_SIZE) % 2 == 0
			var is_even_y: bool = (y / TILE_SIZE) % 2 == 0
			var col: Color = COLOR_TILE_A if (is_even_x == is_even_y) else COLOR_TILE_B

			if x % TILE_SIZE == 0 or y % TILE_SIZE == 0:
				col = COLOR_TILE_BORDER

			img.set_pixel(x, y, col)

	var tex := ImageTexture.create_from_image(img)
	floor_rect.texture = tex
	floor_rect.stretch_mode = TextureRect.STRETCH_TILE
