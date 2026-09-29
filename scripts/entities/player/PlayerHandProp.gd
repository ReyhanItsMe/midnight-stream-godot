extends Node2D
class_name PlayerHandProp

# Base path aset senter
const SENTER_PROPS_PATH: String = "res://assets/sprites/props/senter/"

# Skala ukuran prop agar proporsional dengan sprite Rian
const PROP_SCALE: Vector2 = Vector2(0.55, 0.55)

var prop_sprite: Sprite2D

# Cache tekstur
var tex_depan: Texture2D
var tex_belakang: Texture2D
var tex_kanan: Texture2D
var tex_kiri: Texture2D

func _ready() -> void:
	_load_textures()
	_create_sprite_node()


func _load_textures() -> void:
	tex_depan = _load_safe(SENTER_PROPS_PATH + "senter_tangan_depan.png")
	tex_belakang = _load_safe(SENTER_PROPS_PATH + "senter_tangan_belakang.png")
	tex_kanan = _load_safe(SENTER_PROPS_PATH + "senter_tangan_samping_kanan.png")
	tex_kiri = _load_safe(SENTER_PROPS_PATH + "senter_tangan_samping_kiri.png")


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


## Mengatur arah pandang, orientasi rotasi, dan layering tangan kanan
func update_direction(dir_name: String) -> void:
	if not prop_sprite:
		return

	# Cek kepemilikan senter di SaveManager jika ada
	var save_mgr = get_node_or_null("/root/SaveManager")
	if save_mgr and save_mgr.get("current_data") != null:
		var has_senter: bool = save_mgr.current_data.get("inventory", {}).get("has_flashlight", true)
		if not has_senter:
			prop_sprite.visible = false
			return

	prop_sprite.visible = true

	match dir_name:
		"kanan":
			# Menghadap kanan: Tangan kanan berada di depan tubuh
			prop_sprite.texture = tex_kanan
			prop_sprite.position = Vector2(3, 1)
			prop_sprite.rotation_degrees = 0.0
			prop_sprite.show_behind_parent = false
			prop_sprite.z_index = 1

		"kiri":
			# Menghadap kiri: Tangan kanan berada di balik tubuh
			prop_sprite.texture = tex_kiri
			prop_sprite.position = Vector2(-3, 1)
			prop_sprite.rotation_degrees = 0.0
			prop_sprite.show_behind_parent = true
			prop_sprite.z_index = -1

		"depan":
			# Menghadap depan: Rotasi 180 derajat sesuai permintaan
			prop_sprite.texture = tex_depan
			prop_sprite.position = Vector2(-2, 3)
			prop_sprite.rotation_degrees = 180.0
			prop_sprite.show_behind_parent = false
			prop_sprite.z_index = 1

		"belakang":
			# Menghadap belakang: Rotasi 180 derajat, di belakang punggung
			prop_sprite.texture = tex_belakang
			prop_sprite.position = Vector2(2, -2)
			prop_sprite.rotation_degrees = 180.0
			prop_sprite.show_behind_parent = true
			prop_sprite.z_index = -1


func set_prop_visible(is_show: bool) -> void:
	if prop_sprite:
		prop_sprite.visible = is_show
