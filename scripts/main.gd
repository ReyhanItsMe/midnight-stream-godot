extends Node2D

# ========================================
# GAME SETTINGS
# ========================================

const GAME_WIDTH: float = 640.0
const GAME_HEIGHT: float = 360.0

var player_position: Vector2 = Vector2(320, 180)
var player_speed: float = 180.0

var flashlight: PointLight2D

# ========================================
# TOUCH CONTROL
# ========================================

var touch_id: int = -1
var touch_start: Vector2
var touch_direction: Vector2 = Vector2.ZERO


func _ready():
	# ====================================
	# DUNIA GELAP
	# ====================================

	var darkness := CanvasModulate.new()
	darkness.color = Color(
		0.025,
		0.025,
		0.035
	)

	add_child(darkness)

	# ====================================
	# FLASHLIGHT
	# ====================================

	flashlight = PointLight2D.new()

	flashlight.position = player_position
	flashlight.energy = 2.5
	flashlight.texture_scale = 1.5

	# ====================================
	# BUAT TEXTURE CAHAYA
	# ====================================

	var image := Image.create(
		256,
		256,
		false,
		Image.FORMAT_RGBA8
	)

	for y in range(256):
		for x in range(256):

			var distance: float = Vector2(
				x,
				y
			).distance_to(
				Vector2(128, 128)
			)

			var alpha: float = clampf(
				1.0 - distance / 128.0,
				0.0,
				1.0
			)

			# Membuat pinggiran cahaya lebih lembut
			alpha = pow(alpha, 2.0)

			image.set_pixel(
				x,
				y,
				Color(
					1.0,
					0.9,
					0.7,
					alpha
				)
			)

	flashlight.texture = ImageTexture.create_from_image(image)

	add_child(flashlight)

	queue_redraw()


func _process(delta):
	var direction := Vector2.ZERO

	# ====================================
	# KEYBOARD
	# ====================================

	if Input.is_key_pressed(KEY_W):
		direction.y -= 1.0

	if Input.is_key_pressed(KEY_S):
		direction.y += 1.0

	if Input.is_key_pressed(KEY_A):
		direction.x -= 1.0

	if Input.is_key_pressed(KEY_D):
		direction.x += 1.0

	# ====================================
	# TOUCH
	# ====================================

	if touch_direction != Vector2.ZERO:
		direction = touch_direction

	# ====================================
	# MOVEMENT
	# ====================================

	if direction != Vector2.ZERO:

		direction = direction.normalized()

		player_position += (
			direction
			* player_speed
			* delta
		)

		# =================================
		# BATASI PLAYER DI AREA GAME
		# =================================

		player_position.x = clampf(
			player_position.x,
			30.0,
			610.0
		)

		player_position.y = clampf(
			player_position.y,
			30.0,
			330.0
		)

	# ====================================
	# FLASHLIGHT IKUT PLAYER
	# ====================================

	flashlight.position = player_position

	queue_redraw()


func _input(event):

	# ====================================
	# TOUCH
	# ====================================

	if event is InputEventScreenTouch:

		if event.pressed:

			touch_id = event.index
			touch_start = event.position

		else:

			if event.index == touch_id:

				touch_id = -1
				touch_direction = Vector2.ZERO

	# ====================================
	# TOUCH DRAG
	# ====================================

	elif event is InputEventScreenDrag:

		if event.index == touch_id:

			var offset: Vector2 = (
				event.position
				- touch_start
			)

			if offset.length() > 15.0:

				touch_direction = offset.normalized()


func _draw():

	# ====================================
	# BACKGROUND / LANTAI
	# FULL 640 × 360
	# ====================================

	draw_rect(
		Rect2(
			0,
			0,
			GAME_WIDTH,
			GAME_HEIGHT
		),
		Color(
			0.28,
			0.28,
			0.30
		)
	)

	# ====================================
	# DINDING ATAS
	# ====================================

	draw_rect(
		Rect2(
			0,
			0,
			640,
			20
		),
		Color(
			0.08,
			0.08,
			0.09
		)
	)

	# ====================================
	# DINDING BAWAH
	# ====================================

	draw_rect(
		Rect2(
			0,
			340,
			640,
			20
		),
		Color(
			0.08,
			0.08,
			0.09
		)
	)

	# ====================================
	# DINDING KIRI
	# ====================================

	draw_rect(
		Rect2(
			0,
			0,
			20,
			360
		),
		Color(
			0.08,
			0.08,
			0.09
		)
	)

	# ====================================
	# DINDING KANAN
	# ====================================

	draw_rect(
		Rect2(
			620,
			0,
			20,
			360
		),
		Color(
			0.08,
			0.08,
			0.09
		)
	)

	# ====================================
	# OBJEK 1
	# ====================================

	draw_rect(
		Rect2(
			140,
			110,
			100,
			60
		),
		Color(
			0.05,
			0.05,
			0.06
		)
	)

	# ====================================
	# OBJEK 2
	# ====================================

	draw_rect(
		Rect2(
			400,
			80,
			100,
			60
		),
		Color(
			0.05,
			0.05,
			0.06
		)
	)

	# ====================================
	# OBJEK 3
	# ====================================

	draw_rect(
		Rect2(
			370,
			230,
			100,
			40
		),
		Color(
			0.05,
			0.05,
			0.06
		)
	)

	# ====================================
	# PLAYER
	# ====================================

	draw_circle(
		player_position,
		9,
		Color.WHITE
	)