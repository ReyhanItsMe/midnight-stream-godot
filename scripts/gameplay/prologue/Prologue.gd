extends Node2D

const TILE_SIZE: int = 32
const COLOR_TILE_A: Color = Color(0.16, 0.18, 0.24)
const COLOR_TILE_B: Color = Color(0.12, 0.14, 0.19)
const COLOR_TILE_BORDER: Color = Color(0.09, 0.1, 0.15)

@onready var player: Player = $Player
@onready var camera: Camera2D = $Camera2D
@onready var floor_rect: TextureRect = $GridFloor/FloorTiles
@onready var save_point: SavePoint = $SavePoint
@onready var save_modal: SaveModal = $UILayer/SaveModal

func _ready() -> void:
	AudioManager.stop_bgm(0.4)
	_generate_checkerboard_floor()

	if player:
		player.global_position = Vector2(0, 20)
		camera.global_position = player.global_position

	# Hubungkan save point langsung ke komponen SaveModal
	if save_point and save_modal:
		save_point.save_station_triggered.connect(save_modal.open)


func _process(_delta: float) -> void:
	if player and camera:
		camera.global_position = player.global_position


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
