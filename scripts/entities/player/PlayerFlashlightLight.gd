## Komponen pencahayaan senter karakter (Cone Spotlight + Ambient Glow).
##
## Menggunakan tekstur cone dari AssetPaths dan warna hangat dari Palette.
class_name PlayerFlashlightLight
extends Node2D

const CONE_SIZE: float = 270.0
const ROTATION_LERP_SPEED: float = 26.0

var cone_light: PointLight2D
var ambient_light: PointLight2D
var target_angle_rad: float = 0.0

func _ready() -> void:
	_setup_cone_light()
	_setup_ambient_light()

func _physics_process(delta: float) -> void:
	if not cone_light or not cone_light.enabled:
		return

	# Hitung selisih sudut absolut antara rotasi saat ini dan target
	var diff: float = absf(wrapf(target_angle_rad - cone_light.rotation, -PI, PI))
	
	# Snap instan jika putar balik 180 derajat, lerp jika belok 90 derajat
	if diff > (PI * 0.78):
		cone_light.rotation = target_angle_rad
	else:
		cone_light.rotation = lerp_angle(cone_light.rotation, target_angle_rad, delta * ROTATION_LERP_SPEED)

func _setup_cone_light() -> void:
	cone_light = PointLight2D.new()
	cone_light.name = "FlashlightCone"
	# Menggunakan palet GOLD untuk kehangatan senter horror
	cone_light.color = Palette.blend(Palette.WHITE, Palette.GOLD, 0.25)
	cone_light.energy = 1.35
	cone_light.shadow_enabled = true
	cone_light.shadow_filter = PointLight2D.SHADOW_FILTER_PCF5

	var cone_path: String = AssetPaths.Sprites.LIGHT_CONE
	if ResourceLoader.exists(cone_path):
		cone_light.texture = load(cone_path)
		cone_light.offset = Vector2(CONE_SIZE * 0.5, 0.0)
	else:
		push_warning("[PlayerFlashlightLight] Tekstur cone senter tidak ditemukan di: " + cone_path)

	add_child(cone_light)

func _setup_ambient_light() -> void:
	ambient_light = PointLight2D.new()
	ambient_light.name = "AmbientPlayerGlow"
	ambient_light.color = Palette.blend(Palette.WHITE, Palette.GOLD_LIGHT, 0.15)
	ambient_light.energy = 0.4
	ambient_light.shadow_enabled = false

	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	grad.colors = PackedColorArray([
		Palette.alpha(Palette.WHITE, 0.85),
		Palette.alpha(Palette.WHITE, 0.25),
		Palette.TRANSPARENT
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
