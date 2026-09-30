extends CharacterBody2D
class_name Player

# --- KECEPATAN GERAK ---
const WALK_SPEED: float = 75.0
const SPRINT_SPEED: float = 135.0

const MIN_ANALOG_DEADZONE: float = 0.18
const MIN_WALK_RATIO: float = 0.55
const MIN_ANIM_SPEED: float = 0.60

const STEP_DISTANCE_WALK: float = 24.0
const STEP_DISTANCE_SPRINT: float = 30.0

const PROP_SCALE: Vector2 = Vector2(0.5, 0.5)

# --- TABEL OFFSET POSISI TANGAN ---
const HAND_OFFSETS: Dictionary = {
	"kanan": {
		0: Vector2(2, -3),
		1: Vector2(0, -3),
		2: Vector2(-4, -4)
	},
	"kiri": {
		0: Vector2(-6, -3),
		1: Vector2(0, -3),
		2: Vector2(4, -4)
	},
	"depan": {
		0: Vector2(-7, -3),
		1: Vector2(-7, -3),
		2: Vector2(-7, -3)
	},
	"belakang": {
		0: Vector2(4, -6),
		1: Vector2(4, -5),
		2: Vector2(4, -4)
	}
}

# --- PARAMETER STAMINA ---
const MAX_STAMINA: float = 100.0
const STAMINA_DRAIN_RATE: float = 28.0
const STAMINA_REGEN_RATE: float = 20.0
const STAMINA_REGEN_DELAY: float = 0.8

# --- RESOURCE PATHS ---
const SPRITE_BASE_PATH: String = "res://assets/sprites/characters/rian/"
const FOOTSTEP_SFX_PATH: String = "res://assets/audio/sfx/footsteps/sfx-footsteps-dirt.wav"
const SENTER_PROPS_PATH: String = "res://assets/sprites/props/senter/"
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

# Sistem Akumulator Footstep
var step_distance_accum: float = 0.0
var was_moving_last_frame: bool = false
var idle_reset_timer: float = 0.0

# Audio Player Single-Step Footstep
var footstep_player: AudioStreamPlayer

# Node & Tekstur Prop Senter
var held_flashlight: Sprite2D
var tex_senter_depan: Texture2D
var tex_senter_belakang: Texture2D
var tex_senter_kanan: Texture2D
var tex_senter_kiri: Texture2D

# Komponen Pencahayaan Senter & Lingkaran Ambient
var player_lighting: PlayerFlashlightLight

func _ready() -> void:
	joystick_vector = Vector2.ZERO
	is_sprint_pressed = false
	current_stamina = MAX_STAMINA

	_setup_animations()
	_setup_flashlight_prop()
	_setup_lighting()
	_setup_footsteps_audio()

	# Muat posisi dan arah tersimpan dari SaveManager
	if SaveManager and SaveManager.current_data.has("player"):
		var p_data: Dictionary = SaveManager.current_data["player"]
		global_position = Vector2(
			p_data.get("position_x", global_position.x),
			p_data.get("position_y", global_position.y)
		)
		current_direction = p_data.get("last_direction", "depan")

	_update_held_item(current_direction, 1)
	_play_idle()


func _physics_process(delta: float) -> void:
	# ==========================================================================
	# KUNCI GERAKAN SAAT DIALOG BERLANGSUNG
	# ==========================================================================
	if DialogueBox.is_dialogue_open:
		velocity = Vector2.ZERO
		is_running = false
		was_moving_last_frame = false
		step_distance_accum = 0.0
		_play_idle()
		_sync_hand_and_light_instant(false)
		move_and_slide()
		return

	# 1. Input Analog / Keyboard
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
		move_strength = remap(raw_strength, MIN_ANALOG_DEADZONE, 1.0, MIN_WALK_RATIO, 1.0)
		move_strength = clampf(move_strength, MIN_WALK_RATIO, 1.0)

	# 2. Status Stamina & Sprint
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

	# 3. Gerak Fisik
	if is_moving:
		var max_target_speed: float = SPRINT_SPEED if is_running else WALK_SPEED
		velocity = input_vector.normalized() * (max_target_speed * move_strength)
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	# 4. Suara Langkah Kaki
	var real_speed: float = get_real_velocity().length()
	if is_moving and real_speed > 4.0:
		if not was_moving_last_frame and idle_reset_timer <= 0.0:
			_play_single_step()
			step_distance_accum = 0.0

		was_moving_last_frame = true
		idle_reset_timer = 0.32

		step_distance_accum += real_speed * delta
		var threshold_dist: float = STEP_DISTANCE_SPRINT if is_running else STEP_DISTANCE_WALK

		if step_distance_accum >= threshold_dist:
			step_distance_accum -= threshold_dist
			_play_single_step()
	else:
		was_moving_last_frame = false
		if idle_reset_timer > 0.0:
			idle_reset_timer -= delta
		else:
			step_distance_accum = 0.0

	# 5. Animasi & Orientasi
	if is_moving:
		_update_direction_and_anim(input_vector, is_running, move_strength)
	else:
		_play_idle()

	# 6. SINKRONISASI INSTAN (Menghapus delay 1 frame)
	_sync_hand_and_light_instant(is_moving)


## Sinkronisasi posisi tangan dan cahaya instan di frame physics yang sama
func _sync_hand_and_light_instant(moving: bool) -> void:
	var pose_idx: int = 1
	if moving and anim.animation.begins_with("walk_"):
		match anim.frame:
			0: pose_idx = 0
			1: pose_idx = 1
			2: pose_idx = 2
			3: pose_idx = 1

	_update_held_item(current_direction, pose_idx)


# ==============================================================================
# SISTEM PROPS SENTER GENGGAM (HELD FLASHLIGHT)
# ==============================================================================

func _setup_flashlight_prop() -> void:
	tex_senter_depan = _load_texture_safe(SENTER_PROPS_PATH + "senter_tangan_depan.png")
	tex_senter_belakang = _load_texture_safe(SENTER_PROPS_PATH + "senter_tangan_belakang.png")
	tex_senter_kanan = _load_texture_safe(SENTER_PROPS_PATH + "senter_tangan_samping_kanan.png")
	tex_senter_kiri = _load_texture_safe(SENTER_PROPS_PATH + "senter_tangan_samping_kiri.png")

	held_flashlight = Sprite2D.new()
	held_flashlight.name = "HeldFlashlight"
	held_flashlight.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	held_flashlight.scale = PROP_SCALE
	add_child(held_flashlight)


func _setup_lighting() -> void:
	player_lighting = PlayerFlashlightLight.new()
	player_lighting.name = "PlayerLighting"
	add_child(player_lighting)


func _load_texture_safe(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	push_warning("[Player] Aset prop senter tidak ditemukan di: " + path)
	return null


func _update_held_item(dir_name: String, pose_idx: int = 1) -> void:
	if not held_flashlight:
		return

	var has_item: bool = true
	if SaveManager and SaveManager.current_data.has("inventory"):
		has_item = SaveManager.current_data["inventory"].get("has_flashlight", true)

	if not has_item:
		held_flashlight.visible = false
		if player_lighting:
			player_lighting.set_flashlight_active(false)
		return

	held_flashlight.visible = true
	if player_lighting:
		player_lighting.set_flashlight_active(true)

	var offset_pos := Vector2.ZERO
	if HAND_OFFSETS.has(dir_name) and HAND_OFFSETS[dir_name].has(pose_idx):
		offset_pos = HAND_OFFSETS[dir_name][pose_idx]
	held_flashlight.position = offset_pos

	if player_lighting:
		player_lighting.update_light_transform(held_flashlight.position, dir_name)

	var target_scale: Vector2 = PROP_SCALE
	if dir_name == "depan":
		match pose_idx:
			0: target_scale = PROP_SCALE * 1.05
			1: target_scale = PROP_SCALE
			2: target_scale = PROP_SCALE * 0.82
	held_flashlight.scale = target_scale

	match dir_name:
		"kanan":
			held_flashlight.texture = tex_kanan_safe()
			held_flashlight.rotation_degrees = 0.0
			held_flashlight.show_behind_parent = false
			held_flashlight.z_index = 1

		"kiri":
			held_flashlight.texture = tex_kiri_safe()
			held_flashlight.rotation_degrees = 0.0
			held_flashlight.show_behind_parent = true
			held_flashlight.z_index = -1

		"depan":
			held_flashlight.texture = tex_senter_depan
			held_flashlight.rotation_degrees = 180.0
			held_flashlight.show_behind_parent = false
			held_flashlight.z_index = 1

		"belakang":
			held_flashlight.texture = tex_senter_belakang
			held_flashlight.rotation_degrees = 180.0
			held_flashlight.show_behind_parent = true
			held_flashlight.z_index = -1


func tex_kanan_safe() -> Texture2D:
	return tex_senter_kanan if tex_senter_kanan else tex_senter_depan


func tex_kiri_safe() -> Texture2D:
	return tex_senter_kiri if tex_senter_kiri else tex_senter_depan


# ==============================================================================
# SISTEM SFX FOOTSTEPS
# ==============================================================================

func _setup_footsteps_audio() -> void:
	footstep_player = AudioStreamPlayer.new()
	footstep_player.name = "FootstepAudio"
	footstep_player.bus = "Master"
	footstep_player.volume_db = -1.0

	if ResourceLoader.exists(FOOTSTEP_SFX_PATH):
		var stream_res: AudioStream = load(FOOTSTEP_SFX_PATH)
		footstep_player.stream = stream_res
	else:
		push_error("[Player] Audio file footstep tidak ditemukan di: ", FOOTSTEP_SFX_PATH)

	add_child(footstep_player)


func _play_single_step() -> void:
	if not footstep_player or not footstep_player.stream:
		return

	var base_pitch: float = 1.04 if is_running else 1.0
	footstep_player.pitch_scale = randf_range(base_pitch - 0.03, base_pitch + 0.03)

	footstep_player.stop()
	footstep_player.play()


# ==============================================================================
# ANIMASI & ARAH
# ==============================================================================

func _update_direction_and_anim(dir: Vector2, sprinting: bool, strength: float) -> void:
	if abs(dir.x) > abs(dir.y):
		current_direction = "kanan" if dir.x > 0.0 else "kiri"
	else:
		current_direction = "depan" if dir.y > 0.0 else "belakang"

	var walk_anim: String = "walk_" + current_direction

	if anim.animation != walk_anim:
		anim.play(walk_anim)
	elif not anim.is_playing():
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

	var sample_tex: Texture2D = load(SPRITE_BASE_PATH + "depan_2.png")
	if sample_tex and sample_tex.get_height() > 64:
		var target_scale: float = 36.0 / float(sample_tex.get_height())
		anim.scale = Vector2(target_scale, target_scale)
