extends CharacterBody2D
class_name Player

# Kecepatan Gerak
const WALK_SPEED: float = 75.0
const SPRINT_SPEED: float = 135.0

# Parameter Stamina
const MAX_STAMINA: float = 100.0
const STAMINA_DRAIN_RATE: float = 28.0 # Habis dalam ~3.5 detik lari nonstop
const STAMINA_REGEN_RATE: float = 20.0 # Pulih penuh dalam ~5 detik
const STAMINA_REGEN_DELAY: float = 0.8  # Jeda sebelum mulai mengisi ulang

const SPRITE_BASE_PATH: String = "res://assets/sprites/characters/rian/"
const DIRECTIONS: Array[String] = ["depan", "belakang", "kiri", "kanan"]

# Input dari Virtual Controller HUD
static var joystick_vector: Vector2 = Vector2.ZERO
static var is_sprint_pressed: bool = false
static var current_stamina: float = MAX_STAMINA

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var flashlight: PointLight2D = $Flashlight
@onready var interaction_ray: RayCast2D = $InteractionRay

var current_direction: String = "depan"
var is_running: bool = false
var is_exhausted: bool = false
var regen_timer: float = 0.0

func _ready() -> void:
	joystick_vector = Vector2.ZERO
	is_sprint_pressed = false
	current_stamina = MAX_STAMINA

	_setup_animations()
	_setup_flashlight_texture()

	# Muat posisi dan arah tersimpan saat scene dimuat via Load Game
	if SaveManager and SaveManager.current_data.has("player"):
		var p_data: Dictionary = SaveManager.current_data["player"]
		global_position = Vector2(
			p_data.get("position_x", global_position.x),
			p_data.get("position_y", global_position.y)
		)
		current_direction = p_data.get("last_direction", "depan")

	# Sesuaikan arah senter awal berdasarkan arah tersimpan
	_align_flashlight_to_direction(current_direction)
	_play_idle()


func _physics_process(delta: float) -> void:
	# 1. Baca Arah Gerak (Analog Virtual / Keyboard)
	var input_vector: Vector2 = joystick_vector
	if input_vector == Vector2.ZERO:
		input_vector.x = Input.get_axis("ui_left", "ui_right")
		input_vector.y = Input.get_axis("ui_up", "ui_down")
		if input_vector.length() > 1.0:
			input_vector = input_vector.normalized()

	var is_moving: bool = (input_vector != Vector2.ZERO)

	# 2. Periksa Status Lari (Shift Keyboard atau Tombol Sprint Mobile)
	var wants_to_sprint: bool = is_sprint_pressed or Input.is_key_pressed(KEY_SHIFT)

	if is_exhausted and current_stamina >= 25.0:
		is_exhausted = false

	if is_moving and wants_to_sprint and not is_exhausted and current_stamina > 0.0:
		is_running = true
		current_stamina = clampf(current_stamina - (STAMINA_DRAIN_RATE * delta), 0.0, MAX_STAMINA)
		regen_timer = STAMINA_REGEN_DELAY
		if is_zero_approx(current_stamina):
			is_exhausted = true
	else:
		is_running = false
		if regen_timer > 0.0:
			regen_timer -= delta
		else:
			current_stamina = clampf(current_stamina + (STAMINA_REGEN_RATE * delta), 0.0, MAX_STAMINA)

	# 3. Eksekusi Gerakan
	var current_speed: float = SPRINT_SPEED if is_running else WALK_SPEED
	velocity = input_vector * current_speed
	move_and_slide()

	# 4. Update Animasi & Posisi Terkini
	if is_moving:
		_update_direction_and_anim(input_vector, is_running)
	else:
		_play_idle()


func _update_direction_and_anim(dir: Vector2, sprinting: bool) -> void:
	if abs(dir.x) > abs(dir.y):
		current_direction = "kanan" if dir.x > 0.0 else "kiri"
	else:
		current_direction = "depan" if dir.y > 0.0 else "belakang"

	var walk_anim: String = "walk_" + current_direction
	anim.play(walk_anim)
	# Langkah kaki lebih cepat saat berlari
	anim.speed_scale = 1.65 if sprinting else 1.0

	_align_flashlight_to_direction(current_direction)

	if SaveManager and SaveManager.current_data.has("player"):
		SaveManager.current_data["player"]["last_direction"] = current_direction
		SaveManager.current_data["player"]["position_x"] = global_position.x
		SaveManager.current_data["player"]["position_y"] = global_position.y


func _align_flashlight_to_direction(dir_name: String) -> void:
	var target_vector := Vector2.DOWN
	match dir_name:
		"depan":
			target_vector = Vector2.DOWN
		"belakang":
			target_vector = Vector2.UP
		"kiri":
			target_vector = Vector2.LEFT
		"kanan":
			target_vector = Vector2.RIGHT

	flashlight.rotation = target_vector.angle()
	interaction_ray.target_position = target_vector * 24.0


func _play_idle() -> void:
	anim.speed_scale = 1.0
	var idle_anim_name: String = "idle_" + current_direction
	if anim.sprite_frames and anim.sprite_frames.has_animation(idle_anim_name):
		anim.play(idle_anim_name)


func _setup_animations() -> void:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	for dir_name in DIRECTIONS:
		var tex_1: Texture2D = load(SPRITE_BASE_PATH + dir_name + "_1.png")
		var tex_2: Texture2D = load(SPRITE_BASE_PATH + dir_name + "_2.png")
		var tex_3: Texture2D = load(SPRITE_BASE_PATH + dir_name + "_3.png")

		# Diam memakai frame 2
		var idle_name: String = "idle_" + dir_name
		frames.add_animation(idle_name)
		frames.set_animation_loop(idle_name, false)
		frames.set_animation_speed(idle_name, 5.0)
		if tex_2:
			frames.add_frame(idle_name, tex_2)

		# Gerak kaki 1 -> 2 -> 3 -> 2
		var walk_name: String = "walk_" + dir_name
		frames.add_animation(walk_name)
		frames.set_animation_loop(walk_name, true)
		frames.set_animation_speed(walk_name, 6.5)
		if tex_1 and tex_2 and tex_3:
			frames.add_frame(walk_name, tex_1)
			frames.add_frame(walk_name, tex_2)
			frames.add_frame(walk_name, tex_3)
			frames.add_frame(walk_name, tex_2)

	anim.sprite_frames = frames

	var sample_tex: Texture2D = load(SPRITE_BASE_PATH + "depan_2.png")
	if sample_tex and sample_tex.get_height() > 64:
		var target_scale: float = 36.0 / float(sample_tex.get_height())
		anim.scale = Vector2(target_scale, target_scale)


func _setup_flashlight_texture() -> void:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	grad.colors = PackedColorArray([
		Color(1.0, 0.95, 0.82, 1.0),
		Color(0.85, 0.75, 0.55, 0.45),
		Color(0.0, 0.0, 0.0, 0.0)
	])

	var grad_tex := GradientTexture2D.new()
	grad_tex.gradient = grad
	grad_tex.width = 256
	grad_tex.height = 256
	grad_tex.fill = GradientTexture2D.FILL_RADIAL
	grad_tex.fill_from = Vector2(0.5, 0.5)
	grad_tex.fill_to = Vector2(0.5, 0.0)

	flashlight.texture = grad_tex
	flashlight.energy = 1.35
