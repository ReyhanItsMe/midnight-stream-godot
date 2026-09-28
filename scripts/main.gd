extends Node2D

var player_position: Vector2 = Vector2(640, 360)
var player_speed: float = 180.0

var flashlight: PointLight2D

var touch_id: int = -1
var touch_start: Vector2
var touch_direction: Vector2 = Vector2.ZERO


func _ready():
	# Dunia gelap
	var darkness := CanvasModulate.new()
	darkness.color = Color(0.025, 0.025, 0.035)
	add_child(darkness)

	# Flashlight
	flashlight = PointLight2D.new()
	flashlight.position = player_position
	flashlight.energy = 2.5
	flashlight.texture_scale = 3.0

	# Buat texture cahaya
	var image := Image.create(
		256,
		256,
		false,
		Image.FORMAT_RGBA8
	)

	for y in range(256):
		for x in range(256):
			var distance: float = Vector2(x, y).distance_to(
				Vector2(128, 128)
			)

			var alpha: float = clampf(
				1.0 - distance / 128.0,
				0.0,
				1.0
			)

			alpha = pow(alpha, 2.0)

			image.set_pixel(
				x,
				y,
				Color(1.0, 0.9, 0.7, alpha)
			)

	flashlight.texture = ImageTexture.create_from_image(image)

	add_child(flashlight)

	queue_redraw()


func _process(delta):
	var direction := Vector2.ZERO

	# =========================
	# KEYBOARD
	# =========================

	if Input.is_key_pressed(KEY_W):
		direction.y -= 1

	if Input.is_key_pressed(KEY_S):
		direction.y += 1

	if Input.is_key_pressed(KEY_A):
		direction.x -= 1

	if Input.is_key_pressed(KEY_D):
		direction.x += 1

	# =========================
	# TOUCH
	# =========================

	if touch_direction != Vector2.ZERO:
		direction = touch_direction

	# =========================
	# MOVEMENT
	# =========================

	if direction != Vector2.ZERO:
		direction = direction.normalized()

		player_position += direction * player_speed * delta

		# Batasi player di dalam ruangan
		player_position.x = clampf(
			player_position.x,
			150.0,
			1130.0
		)

		player_position.y = clampf(
			player_position.y,
			150.0,
			570.0
		)

	# Flashlight mengikuti player
	flashlight.position = player_position

	queue_redraw()


func _input(event):
	if event is InputEventScreenTouch:

		if event.pressed:
			touch_id = event.index
			touch_start = event.position

		else:
			if event.index == touch_id:
				touch_id = -1
				touch_direction = Vector2.ZERO

	elif event is InputEventScreenDrag:

		if event.index == touch_id:
			var offset: Vector2 = event.position - touch_start

			if offset.length() > 15.0:
				touch_direction = offset.normalized()


func _draw():
	# Lantai
	draw_rect(
		Rect2(100, 100, 1080, 520),
		Color(0.28, 0.28, 0.30)
	)

	# Dinding atas
	draw_rect(
		Rect2(100, 100, 1080, 30),
		Color(0.08, 0.08, 0.09)
	)

	# Dinding bawah
	draw_rect(
		Rect2(100, 590, 1080, 30),
		Color(0.08, 0.08, 0.09)
	)

	# Dinding kiri
	draw_rect(
		Rect2(100, 100, 30, 520),
		Color(0.08, 0.08, 0.09)
	)

	# Dinding kanan
	draw_rect(
		Rect2(1150, 100, 30, 520),
		Color(0.08, 0.08, 0.09)
	)

	# Objek
	draw_rect(
		Rect2(350, 250, 180, 100),
		Color(0.05, 0.05, 0.06)
	)

	draw_rect(
		Rect2(800, 200, 200, 120),
		Color(0.05, 0.05, 0.06)
	)

	draw_rect(
		Rect2(750, 450, 180, 90),
		Color(0.05, 0.05, 0.06)
	)

	# Player
	draw_circle(
		player_position,
		18,
		Color.WHITE
	)