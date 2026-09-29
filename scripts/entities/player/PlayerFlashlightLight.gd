extends Node2D
class_name PlayerFlashlightLight

# --- RESOURCE PATHS ---
const CONE_TEXTURE_PATH: String = "res://assets/sprites/lights/cone_composed_c.png"
const CONE_SIZE: float = 270.0

# Kecepatan transisi sapuan sudut diagonal (makin besar makin gesit/sekejap)
const ROTATION_LERP_SPEED: float = 26.0

var cone_light: PointLight2D
var ambient_light: PointLight2D

# Variabel sudut target & sudut saat ini
var target_angle_rad: float = 0.0

func _ready() -> void:
	_setup_cone_light()
	_setup_ambient_light()


func _physics_process(delta: float) -> void:
	if not cone_light or not cone_light.enabled:
		return

	# Hitung selisih sudut absolut antara rotasi sekarang dan target
	var diff: float = absf(wrapf(target_angle_rad - cone_light.rotation, -PI, PI))

	# ATURAN:
	# Jika selisih sudut mendekati 180 derajat (balik badan instan kiri <-> kanan),
	# langsung SNAP tanpa sapuan diagonal.
	if diff > (PI * 0.78): # Lebih dari ~140 derajat
		cone_light.rotation = target_angle_rad
	else:
		# Jika belok 90 derajat (Kanan -> Atas, Kiri -> Bawah, dll),
		# berikan efek sapuan diagonal halus sekejap menggunakan lerp_angle
		cone_light.rotation = lerp_angle(cone_light.rotation, target_angle_rad, delta * ROTATION_LERP_SPEED)


func _setup_cone_light() -> void:
	cone_light = PointLight2D.new()
	cone_light.name = "FlashlightCone"
	cone_light.color = Color(1.0, 0.94, 0.82, 1.0)
	cone_light.energy = 1.35
	cone_light.shadow_enabled = true
	cone_light.shadow_filter = PointLight2D.SHADOW_FILTER_PCF5

	if ResourceLoader.exists(CONE_TEXTURE_PATH):
		var tex: Texture2D = load(CONE_TEXTURE_PATH)
		cone_light.texture = tex
		cone_light.offset = Vector2(CONE_SIZE * 0.5, 0.0)
	else:
		push_warning("[PlayerFlashlightLight] Tekstur senter tidak ditemukan di: " + CONE_TEXTURE_PATH)

	add_child(cone_light)


func _setup_ambient_light() -> void:
	ambient_light = PointLight2D.new()
	ambient_light.name = "AmbientPlayerGlow"
	ambient_light.color = Color(1.0, 0.95, 0.88, 1.0)
	ambient_light.energy = 0.4
	ambient_light.shadow_enabled = false

	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	grad.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 0.85),
		Color(1.0, 1.0, 1.0, 0.25),
		Color(0.0, 0.0, 0.0, 0.0)
	])

	var grad_tex := GradientTexture2D.new()
	grad_tex.gradient = grad
	grad_tex.width = 96
	grad_tex.height = 96
	grad_tex.fill = GradientTexture2D.FILL_RADIAL
	grad_tex.fill_from = Vector2(0.5, 0.5)
	grad_tex.fill_to = Vector2(0.5, 0.0)

	ambient_light.texture = grad_tex
	ambient_light.position = Vector2(0.0, -2.0)
	add_child(ambient_light)


## Menyesuaikan titik tangan dan target sudut arah sorot
func update_light_transform(hand_pos: Vector2, dir_name: String) -> void:
	if not cone_light:
		return

	cone_light.position = hand_pos

	match dir_name:
		"kanan":
			target_angle_rad = deg_to_rad(0.0)
			cone_light.z_index = 1
		"depan":
			target_angle_rad = deg_to_rad(90.0)
			cone_light.z_index = 1
		"kiri":
			target_angle_rad = deg_to_rad(180.0)
			cone_light.z_index = 1
		"belakang":
			target_angle_rad = deg_to_rad(270.0)
			cone_light.z_index = -1


func set_flashlight_active(is_active: bool) -> void:
	if cone_light:
		cone_light.enabled = is_active
	if ambient_light:
		ambient_light.enabled = is_active
