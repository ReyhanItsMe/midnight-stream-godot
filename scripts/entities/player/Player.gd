extends CharacterBody2D
class_name Player

# --- KECEPATAN & DEADZONE ---
const WALK_SPEED: float = 75.0
const SPRINT_SPEED: float = 135.0

const MIN_ANALOG_DEADZONE: float = 0.18
const MIN_WALK_RATIO: float = 0.55
const MIN_ANIM_SPEED: float = 0.60

const STEP_DISTANCE_WALK: float = 24.0
const STEP_DISTANCE_SPRINT: float = 30.0

# --- PARAMETER STAMINA ---
const MAX_STAMINA: float = 100.0
const STAMINA_DRAIN_RATE: float = 28.0
const STAMINA_REGEN_RATE: float = 20.0
const STAMINA_REGEN_DELAY: float = 0.8

const DIRECTIONS: Array[String] = ["depan", "belakang", "kiri", "kanan"]

# Input dari Virtual Controller HUD
static var joystick_vector: Vector2 = Vector2.ZERO
static var is_sprint_pressed: bool = false
static var current_stamina: float = MAX_STAMINA

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_ray: RayCast2D = $InteractionRay

var current_direction: String = "depan"
var is_running: bool = false
var is_exhausted: bool = false
var regen_timer: float = 0.0

# Akumulator Footstep
var step_distance_accum: float = 0.0
var was_moving_last_frame: bool = false
var idle_reset_timer: float = 0.0
var footstep_player: AudioStreamPlayer

# Sub-Komponen Player
var player_hand_prop: PlayerHandProp
var player_lighting: PlayerFlashlightLight

func _ready() -> void:
	joystick_vector = Vector2.ZERO
	is_sprint_pressed = false
	current_stamina = MAX_STAMINA

	_setup_animations()
	_setup_components()
	_setup_footsteps_audio()

	# Muat save data posisi pemain
	if SaveManager and SaveManager.current_data.has("player"):
		var p_data: Dictionary = SaveManager.current_data["player"]
		global_position = Vector2(
			p_data.get("position_x", global_position.x),
			p_data.get("position_y", global_position.y)
		)
		current_direction = p_data.get("last_direction", "depan")

	player_hand_prop.update_held_prop(current_direction, 1)
	_play_idle()

func _setup_components() -> void:
	player_lighting = PlayerFlashlightLight.new()
	player_lighting.name = "PlayerLighting"
	add_child(player_lighting)

	player_hand_prop = PlayerHandProp.new()
	player_hand_prop.name = "PlayerHandProp"
	player_hand_prop.set_lighting_reference(player_lighting)
	add_child(player_hand_prop)

func _physics_process(delta: float) -> void:
	# Kunci gerakan saat percakapan atau modal dialog aktif
	if DialogueBox.is_dialogue_open:
		velocity = Vector2.ZERO
		is_running = false
		was_moving_last_frame = false
		step_distance_accum = 0.0
		_play_idle()
		player_hand_prop.update_held_prop(current_direction, 1)
		move_and_slide()
		return

	# 1. Kalkulasi Input (Virtual Controls Analog / Keyboard Fallback)
	var input_vector: Vector2 = joystick_vector
	if input_vector == Vector2.ZERO:
		input_vector.x = Input.get_axis("ui_left", "ui_right")
		input_vector.y = Input.get_axis("ui_up", "ui_down")
		if input_vector.length() > 1.0:
			input_vector = input_vector.normalized()

	var raw_strength: float = clampf(input_vector.length(), 0.0, 1.0)
	var is_moving: bool = (raw_strength >= MIN_ANALOG_DEADZONE)

	var move_strength: float = 0.0
	if is_moving:
		move_strength = clampf(remap(raw_strength, MIN_ANALOG_DEADZONE, 1.0, MIN_WALK_RATIO, 1.0), MIN_WALK_RATIO, 1.0)

	# 2. Pengelolaan Stamina & Sprint
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

	# 3. Gerakan Fisik Karakter
	if is_moving:
		var target_speed: float = SPRINT_SPEED if is_running else WALK_SPEED
		velocity = input_vector.normalized() * (target_speed * move_strength)
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	# 4. Audio Footstep Berdasarkan Langkah Nyata
	var real_speed: float = get_real_velocity().length()
	if is_moving and real_speed > 4.0:
		if not was_moving_last_frame and idle_reset_timer <= 0.0:
			_play_single_step()
			step_distance_accum = 0.0

		was_moving_last_frame = true
		idle_reset_timer = 0.32
		step_distance_accum += real_speed * delta
		var threshold: float = STEP_DISTANCE_SPRINT if is_running else STEP_DISTANCE_WALK

		if step_distance_accum >= threshold:
			step_distance_accum -= threshold
			_play_single_step()
	else:
		was_moving_last_frame = false
		if idle_reset_timer > 0.0:
			idle_reset_timer -= delta
		else:
			step_distance_accum = 0.0

	# 5. Animasi Badan & Arah Pandang
	if is_moving:
		_update_direction_and_anim(input_vector, is_running, move_strength)
	else:
		_play_idle()

	# 6. Sinkronisasi Posisi Tangan Senter & Frame Gerak
	var pose_idx: int = 1
	if is_moving and anim.animation.begins_with("walk_"):
		match anim.frame:
			0: pose_idx = 0
			1: pose_idx = 1
			2: pose_idx = 2
			3: pose_idx = 1

	player_hand_prop.update_held_prop(current_direction, pose_idx)

func _update_direction_and_anim(dir: Vector2, sprinting: bool, strength: float) -> void:
	if abs(dir.x) > abs(dir.y):
		current_direction = "kanan" if dir.x > 0.0 else "kiri"
	else:
		current_direction = "depan" if dir.y > 0.0 else "belakang"

	var walk_anim: String = "walk_" + current_direction
	if anim.animation != walk_anim or not anim.is_playing():
		anim.play(walk_anim)

	var base_scale: float = 1.65 if sprinting else 1.0
	anim.speed_scale = clampf(base_scale * strength, MIN_ANIM_SPEED, 1.65)

	var target_vector := Vector2.DOWN
	match current_direction:
		"depan": target_vector = Vector2.DOWN
		"belakang": target_vector = Vector2.UP
		"kiri": target_vector = Vector2.LEFT
		"kanan": target_vector = Vector2.RIGHT

	interaction_ray.target_position = target_vector * 24.0

	if SaveManager and SaveManager.current_data.has("player"):
		SaveManager.current_data["player"]["last_direction"] = current_direction
		SaveManager.current_data["player"]["position_x"] = global_position.x
		SaveManager.current_data["player"]["position_y"] = global_position.y

func _play_idle() -> void:
	anim.speed_scale = 1.0
	var idle_name: String = "idle_" + current_direction
	if anim.sprite_frames and anim.sprite_frames.has_animation(idle_name):
		anim.play(idle_name)

func _setup_footsteps_audio() -> void:
	footstep_player = AudioStreamPlayer.new()
	footstep_player.name = "FootstepAudio"
	footstep_player.bus = "Master"
	footstep_player.volume_db = -1.0

	var sfx_path: String = AssetPaths.Audios.SFX_FOOTSTEP_DIRT
	if ResourceLoader.exists(sfx_path):
		footstep_player.stream = load(sfx_path)
	add_child(footstep_player)

func _play_single_step() -> void:
	if not footstep_player or not footstep_player.stream:
		return
	var base_pitch: float = 1.04 if is_running else 1.0
	footstep_player.pitch_scale = randf_range(base_pitch - 0.03, base_pitch + 0.03)
	footstep_player.stop()
	footstep_player.play()

func _setup_animations() -> void:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	var sprite_base: String = AssetPaths.Sprites.CHAR_RIAN_DIR + "/"

	for dir_name in DIRECTIONS:
		var tex_1: Texture2D = load(sprite_base + dir_name + "_1.png")
		var tex_2: Texture2D = load(sprite_base + dir_name + "_2.png")
		var tex_3: Texture2D = load(sprite_base + dir_name + "_3.png")

		var idle_name: String = "idle_" + dir_name
		frames.add_animation(idle_name)
		frames.set_animation_loop(idle_name, false)
		frames.set_animation_speed(idle_name, 5.0)
		if tex_2:
			frames.add_frame(idle_name, tex_2)

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

	var sample_tex: Texture2D = load(sprite_base + "depan_2.png")
	if sample_tex and sample_tex.get_height() > 64:
		var target_scale: float = 36.0 / float(sample_tex.get_height())
		anim.scale = Vector2(target_scale, target_scale)
