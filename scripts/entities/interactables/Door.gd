extends Area2D
class_name Door

enum DoorType {
	KAYU_1DAUN,
	KAYU_GANDA,
	BESI_1DAUN,
	BESI_GANDA,
	RUMAH_SAKIT_1DAUN,
	RUMAH_SAKIT_GANDA,
	RUSAK_1DAUN,
	RUSAK_GANDA,
	RANTAI_1DAUN,
	DIPAKU_1DAUN,
	SEL_BESI_1DAUN,
	DARAH_1DAUN,
	TERBUKA_SEDIKIT_1DAUN,
	TERBUKA_MATA_1DAUN
}

const DOOR_BASE_PATH: String = "res://assets/sprites/interactables/pintu_horror/"

const TEXTURE_MAP: Dictionary = {
	DoorType.KAYU_1DAUN: "pintu_kayu_1daun.png",
	DoorType.KAYU_GANDA: "pintu_kayu_ganda.png",
	DoorType.BESI_1DAUN: "pintu_besi_1daun.png",
	DoorType.BESI_GANDA: "pintu_besi_ganda.png",
	DoorType.RUMAH_SAKIT_1DAUN: "pintu_rumah_sakit_1daun.png",
	DoorType.RUMAH_SAKIT_GANDA: "pintu_rumah_sakit_ganda.png",
	DoorType.RUSAK_1DAUN: "pintu_rusak_1daun.png",
	DoorType.RUSAK_GANDA: "pintu_rusak_ganda.png",
	DoorType.RANTAI_1DAUN: "pintu_rantai_1daun.png",
	DoorType.DIPAKU_1DAUN: "pintu_dipaku_1daun.png",
	DoorType.SEL_BESI_1DAUN: "pintu_sel_besi_1daun.png",
	DoorType.DARAH_1DAUN: "pintu_darah_1daun.png",
	DoorType.TERBUKA_SEDIKIT_1DAUN: "pintu_terbuka_sedikit_1daun.png",
	DoorType.TERBUKA_MATA_1DAUN: "pintu_terbuka_sedikit_mata_1daun.png"
}

# Cooldown global agar pintu lain tidak langsung memicu transisi saat player baru mendarat
static var is_any_door_teleporting: bool = false

@export_group("Visual Pintu")
@export var door_type: DoorType = DoorType.KAYU_1DAUN:
	set(val):
		door_type = val
		_update_sprite_texture()
@export var custom_scale: Vector2 = Vector2(1.0, 1.0):
	set(val):
		custom_scale = val
		if sprite:
			sprite.scale = custom_scale

@export_group("Konfigurasi Teleportasi")
@export var door_name: String = "PINTU"
@export_file("*.tscn") var target_scene: String = ""
@export var target_teleport_position: Vector2 = Vector2.ZERO
@export var spawn_direction: String = "depan"
@export var is_locked: bool = false
@export var required_key_id: String = ""
@export var auto_teleport_on_touch: bool = true

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var is_player_in_range: bool = false
var current_player_ref: Player = null

func _ready() -> void:
	collision_layer = 3
	collision_mask = 3
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_sprite_texture()


func _unhandled_input(event: InputEvent) -> void:
	# Abaikan input pintu jika player di luar jangkauan, sedang transisi, atau sedang dialog
	if not is_player_in_range or is_any_door_teleporting or DialogueBox.is_dialogue_open:
		return

	if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
		interact()


func interact() -> void:
	# Kunci interaksi total saat dialog sedang berjalan
	if is_any_door_teleporting or DialogueBox.is_dialogue_open:
		return

	if is_locked:
		_handle_locked()
		return

	_start_door_transition()


func _handle_locked() -> void:
	if required_key_id != "" and SaveManager and SaveManager.current_data.has("inventory"):
		var keys: Array = SaveManager.current_data["inventory"].get("keys", [])
		if keys.has(required_key_id):
			is_locked = false
			_start_door_transition()
			return

	print("[Door] Pintu terkunci.")


func _start_door_transition() -> void:
	is_any_door_teleporting = true
	var fade_overlay := _get_or_create_fade_overlay()

	# Hentikan tween sebelumnya jika masih berjalan
	var tween := create_tween()
	tween.tween_property(fade_overlay, "color", Color(0, 0, 0, 1.0), 0.2)
	tween.tween_callback(Callable(self, "_execute_teleport"))
	tween.tween_property(fade_overlay, "color", Color(0, 0, 0, 0.0), 0.25)
	# Cooldown 0.35 detik sebelum pintu mana pun bisa diaktifkan lagi
	tween.tween_interval(0.35)
	tween.tween_callback(func(): is_any_door_teleporting = false)


func _execute_teleport() -> void:
	if target_scene != "":
		if SaveManager and SaveManager.current_data.has("player"):
			SaveManager.current_data["player"]["position_x"] = target_teleport_position.x
			SaveManager.current_data["player"]["position_y"] = target_teleport_position.y
			SaveManager.current_data["player"]["last_direction"] = spawn_direction
		
		# Bersihkan overlay hitam sebelum ganti scene agar menu tidak tertutup
		var canvas = get_tree().root.get_node_or_null("FadeCanvas")
		if canvas:
			canvas.queue_free()

		is_any_door_teleporting = false
		get_tree().change_scene_to_file(target_scene)
		return

	if current_player_ref:
		current_player_ref.global_position = target_teleport_position
		current_player_ref.velocity = Vector2.ZERO
		current_player_ref.current_direction = spawn_direction
		if current_player_ref.has_method("_update_held_item"):
			current_player_ref._update_held_item(spawn_direction, 1)


func _update_sprite_texture() -> void:
	if not sprite:
		return
	
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = custom_scale

	var file_name: String = TEXTURE_MAP.get(door_type, "pintu_kayu_1daun.png")
	var path: String = DOOR_BASE_PATH + file_name

	if ResourceLoader.exists(path):
		sprite.texture = load(path)
	else:
		push_warning("[Door] Tekstur pintu tidak ditemukan: " + path)


func _get_or_create_fade_overlay() -> ColorRect:
	var canvas := get_tree().root.get_node_or_null("FadeCanvas")
	if not canvas:
		canvas = CanvasLayer.new()
		canvas.name = "FadeCanvas"
		canvas.layer = 100
		get_tree().root.add_child(canvas)

	var rect := canvas.get_node_or_null("FadeRect") as ColorRect
	if not rect:
		rect = ColorRect.new()
		rect.name = "FadeRect"
		rect.color = Color(0, 0, 0, 0)
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(rect)

	return rect


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		is_player_in_range = true
		current_player_ref = body
		# Tolak auto-teleportasi jika sedang dialog atau sedang transisi pintu lain
		if auto_teleport_on_touch and not is_any_door_teleporting and not DialogueBox.is_dialogue_open:
			interact()


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		is_player_in_range = false
		if current_player_ref == body:
			current_player_ref = null
