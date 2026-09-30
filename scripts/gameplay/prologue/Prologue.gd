extends Node2D

const TILE_SIZE: int = 32
const COLOR_TILE_A: Color = Color(0.22, 0.24, 0.30)
const COLOR_TILE_B: Color = Color(0.16, 0.18, 0.24)
const COLOR_TILE_BORDER: Color = Color(0.12, 0.13, 0.18)

const DOOR_SCENE_PATH: String = "res://scenes/entities/interactables/Door.tscn"

@onready var player: Player = $Player
@onready var camera: Camera2D = $Camera2D
@onready var floor_rect: TextureRect = $GridFloor/FloorTiles
@onready var save_point: SavePoint = $SavePoint
@onready var save_modal: SaveModal = $UILayer/SaveModal

func _ready() -> void:
	AudioManager.stop_bgm(0.4)
	_generate_checkerboard_floor()
	_create_visual_walls()
	_setup_horizontal_darkness_gradient()
	_create_darkness_markers()
	_create_test_doors()

	var pause_modal := PauseModal.new()
	pause_modal.name = "PauseModal"
	$UILayer.add_child(pause_modal)

	if player:
		# Posisikan player di depan pintu kayu area terang
		player.global_position = Vector2(-180, -40)
		camera.global_position = player.global_position

	if save_point and save_modal:
		save_point.save_station_triggered.connect(save_modal.open)


func _process(_delta: float) -> void:
	if player and camera:
		camera.global_position = player.global_position


## 1. Visual Dinding Struktural (Atas, Bawah, Kiri, Kanan)
func _create_visual_walls() -> void:
	var wall_container := Node2D.new()
	wall_container.name = "VisualWalls"
	wall_container.z_index = 2 # Di atas lantai dan sejajar dinding
	add_child(wall_container)

	# Dinding Atas (Tinggi 40px menutupi batas Y=-180 sampai Y=-140)
	var wall_top := ColorRect.new()
	wall_top.position = Vector2(-320, -180)
	wall_top.size = Vector2(640, 42)
	wall_top.color = Color(0.08, 0.09, 0.13, 1.0)
	wall_container.add_child(wall_top)

	# Garis lis penahan dinding atas (skirting board)
	var skirting_top := ColorRect.new()
	skirting_top.position = Vector2(-320, -138)
	skirting_top.size = Vector2(640, 4)
	skirting_top.color = Color(0.18, 0.20, 0.28, 1.0)
	wall_container.add_child(skirting_top)


## 2. Gradasi Cahaya Ruangan: Terang di Kiri -> Hitam Total di Kanan
func _setup_horizontal_darkness_gradient() -> void:
	var ambient_light := PointLight2D.new()
	ambient_light.name = "AmbientGradientLight"
	ambient_light.position = Vector2(0, 0)
	ambient_light.energy = 1.0
	ambient_light.shadow_enabled = false

	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.35, 0.65, 0.85, 1.0])
	grad.colors = PackedColorArray([
		Color(0.65, 0.70, 0.85, 1.0), # X = -320 (Kiri terang)
		Color(0.35, 0.40, 0.50, 1.0), # X = -100
		Color(0.12, 0.14, 0.20, 1.0), # X = +100 (Remang pekat)
		Color(0.03, 0.03, 0.05, 1.0), # X = +220 (Mendekati hitam)
		Color(0.00, 0.00, 0.00, 1.0)  # X = +320 (Gelap total 100%)
	])

	var grad_tex := GradientTexture2D.new()
	grad_tex.gradient = grad
	grad_tex.width = 640
	grad_tex.height = 360
	grad_tex.fill = GradientTexture2D.FILL_LINEAR
	grad_tex.fill_from = Vector2(0.0, 0.5)
	grad_tex.fill_to = Vector2(1.0, 0.5)

	ambient_light.texture = grad_tex
	add_child(ambient_light)


## 3. Marker Penguji Tingkat Kegelapan
func _create_darkness_markers() -> void:
	var markers: Array[Dictionary] = [
		{"pos": Vector2(-220, 90), "col": Color(0.2, 0.85, 0.3),  "label": "TERANG (100%)"},
		{"pos": Vector2(-110, 90), "col": Color(0.9, 0.85, 0.2),  "label": "SEDANG (60%)"},
		{"pos": Vector2(0, 90),    "col": Color(0.95, 0.5, 0.1),  "label": "REMANG (30%)"},
		{"pos": Vector2(120, 90),  "col": Color(0.9, 0.2, 0.2),   "label": "GELAP (10%)"},
		{"pos": Vector2(240, 90),  "col": Color(0.6, 0.1, 0.9),   "label": "GELAP TOTAL (0%)"}
	]

	var marker_container := Node2D.new()
	marker_container.name = "DarknessMarkers"
	add_child(marker_container)

	for m in markers:
		var box := ColorRect.new()
		box.size = Vector2(18, 48)
		box.position = m["pos"] - Vector2(9, 24)
		box.color = m["col"]
		marker_container.add_child(box)

		var lbl := Label.new()
		lbl.text = m["label"]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.position = m["pos"] + Vector2(-60, 28)
		lbl.size = Vector2(120, 20)
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.add_theme_color_override("font_color", m["col"])
		marker_container.add_child(lbl)

## 4. Spawn Pintu Horror Tepat di Atas Batas Lantai dengan Rute Berurutan
func _create_test_doors() -> void:
	if not ResourceLoader.exists(DOOR_SCENE_PATH):
		push_warning("[Prologue] Scene Door tidak ditemukan di: " + DOOR_SCENE_PATH)
		return

	var door_packed: PackedScene = load(DOOR_SCENE_PATH)
	var door_container := Node2D.new()
	door_container.name = "TestDoors"
	door_container.z_index = 3
	add_child(door_container)

	# Rute Teleportasi:
	# Pintu 1 (-180) -> Spawn di depan Pintu 2 (-40)
	# Pintu 2 (-40)  -> Spawn di depan Pintu 3 (100)
	# Pintu 3 (100)  -> Spawn di depan Pintu 4 (230)
	# Pintu 4 (230)  -> Kembali ke depan Pintu 1 (-180)
	var doors_data: Array[Dictionary] = [
		{
			"pos": Vector2(-180, -130),
			"type": Door.DoorType.KAYU_1DAUN,
			"name": "1. PINTU KAYU (TERANG)",
			"tp_pos": Vector2(-40, -30), # Teleport ke depan Pintu 2
			"spawn_dir": "depan"
		},
		{
			"pos": Vector2(-40, -130),
			"type": Door.DoorType.BESI_GANDA,
			"name": "2. PINTU BESI GANDA (REMANG)",
			"tp_pos": Vector2(100, -30), # Teleport ke depan Pintu 3
			"spawn_dir": "depan"
		},
		{
			"pos": Vector2(100, -130),
			"type": Door.DoorType.RUMAH_SAKIT_1DAUN,
			"name": "3. PINTU RUMAH SAKIT (GELAP)",
			"tp_pos": Vector2(230, -30), # Teleport ke depan Pintu 4
			"spawn_dir": "depan"
		},
		{
			"pos": Vector2(230, -130),
			"type": Door.DoorType.TERBUKA_MATA_1DAUN,
			"name": "4. PINTU HOROR MATA (GELAP TOTAL)",
			"tp_pos": Vector2(-180, -30), # Teleport kembali ke Pintu 1
			"spawn_dir": "depan"
		}
	]

	for data in doors_data:
		var door_inst: Door = door_packed.instantiate() as Door
		door_inst.position = data["pos"]
		door_inst.door_type = data["type"]
		door_inst.door_name = data["name"]
		door_inst.target_teleport_position = data["tp_pos"]
		door_inst.spawn_direction = data["spawn_dir"]
		door_inst.auto_teleport_on_touch = true
		door_inst.custom_scale = Vector2(1.2, 1.2)
		door_container.add_child(door_inst)


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
