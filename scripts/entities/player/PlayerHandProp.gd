## Komponen pengelola visual prop senter di tangan Rian.
##
## Mengatur rotasi, skala, z-index per arah, serta sinkronisasi
## titik posisi cahaya dengan PlayerFlashlightLight.
class_name PlayerHandProp
extends Node2D

const PROP_SCALE: Vector2 = Vector2(0.5, 0.5)

# Offset posisi tangan berdasarkan arah pandang dan frame animasi gerak
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

var prop_sprite: Sprite2D
var player_lighting: PlayerFlashlightLight

var tex_depan: Texture2D
var tex_belakang: Texture2D
var tex_kanan: Texture2D
var tex_kiri: Texture2D

func _ready() -> void:
	_load_textures()
	_create_sprite_node()

func set_lighting_reference(lighting: PlayerFlashlightLight) -> void:
	player_lighting = lighting

func _load_textures() -> void:
	var base_path: String = AssetPaths.Sprites.PROPS_SENTER_DIR
	
	tex_depan = _load_safe(base_path + "senter_tangan_depan.png")
	tex_belakang = _load_safe(base_path + "senter_tangan_belakang.png")
	tex_kanan = _load_safe(base_path + "senter_tangan_samping_kanan.png")
	tex_kiri = _load_safe(base_path + "senter_tangan_samping_kiri.png")

func _create_sprite_node() -> void:
	prop_sprite = Sprite2D.new()
	prop_sprite.name = "PropSprite"
	prop_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	prop_sprite.scale = PROP_SCALE
	add_child(prop_sprite)

func _load_safe(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	push_warning("[PlayerHandProp] File aset tidak ditemukan: " + path)
	return null

## Sinkronisasi posisi tangan dan orientasi visual
func update_held_prop(dir_name: String, pose_idx: int = 1) -> void:
	if not prop_sprite:
		return

	# Cek kepemilikan senter di SaveManager
	var has_item: bool = true
	var save_mgr = get_node_or_null("/root/SaveManager")
	if save_mgr and save_mgr.get("current_data") != null:
		var inv_data = save_mgr.current_data.get("inventory", {})
		has_item = inv_data.get("has_flashlight", true)

	if not has_item:
		prop_sprite.visible = false
		if player_lighting:
			player_lighting.set_flashlight_active(false)
		return

	prop_sprite.visible = true
	if player_lighting:
		player_lighting.set_flashlight_active(true)

	# Terapkan offset frame gerak kaki
	var offset_pos := Vector2.ZERO
	if HAND_OFFSETS.has(dir_name) and HAND_OFFSETS[dir_name].has(pose_idx):
		offset_pos = HAND_OFFSETS[dir_name][pose_idx]
	prop_sprite.position = offset_pos

	# Sinkronkan posisi cone cahaya ke titik tangan
	if player_lighting:
		player_lighting.update_light_transform(prop_sprite.position, dir_name)

	# Skala dinamis khusus pandangan depan
	var target_scale: Vector2 = PROP_SCALE
	if dir_name == "depan":
		match pose_idx:
			0: target_scale = PROP_SCALE * 1.05
			1: target_scale = PROP_SCALE
			2: target_scale = PROP_SCALE * 0.82
	prop_sprite.scale = target_scale

	# Arah pandang, tekstur, rotasi, dan kedalaman z-index
	match dir_name:
		"kanan":
			prop_sprite.texture = tex_kanan if tex_kanan else tex_depan
			prop_sprite.rotation_degrees = 0.0
			prop_sprite.show_behind_parent = false
			prop_sprite.z_index = 1
		"kiri":
			prop_sprite.texture = tex_kiri if tex_kiri else tex_depan
			prop_sprite.rotation_degrees = 0.0
			prop_sprite.show_behind_parent = true
			prop_sprite.z_index = -1
		"depan":
			prop_sprite.texture = tex_depan
			prop_sprite.rotation_degrees = 180.0
			prop_sprite.show_behind_parent = false
			prop_sprite.z_index = 1
		"belakang":
			prop_sprite.texture = tex_belakang
			prop_sprite.rotation_degrees = 180.0
			prop_sprite.show_behind_parent = true
			prop_sprite.z_index = -1
