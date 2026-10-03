## Entitas interaktif pintu untuk transisi antar ruangan atau perpindahan scene map.
class_name Door
extends Area2D

# Alias agar pemanggilan Door.DoorType di Prologue.gd tetap valid tanpa error
const DoorType = DoorData.DoorType

@export_group("Visual Pintu")
@export var door_type: DoorData.DoorType = DoorData.DoorType.KAYU_1DAUN:
	set(val):
		door_type = val
		_update_sprite_texture()

@export var custom_scale: Vector2 = Vector2.ONE:
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
	if not is_player_in_range or DialogueBox.is_dialogue_open:
		return

	if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
		interact()

func interact() -> void:
	if TransitionManager.is_transitioning or DialogueBox.is_dialogue_open:
		return

	if is_locked:
		if _can_unlock():
			is_locked = false
		else:
			print("[Door] Pintu %s terkunci." % door_name)
			return

	_trigger_transition()

func _can_unlock() -> bool:
	if required_key_id.is_empty():
		return true

	if SaveManager and SaveManager.current_data.has("inventory"):
		var keys: Array = SaveManager.current_data["inventory"].get("keys", [])
		return keys.has(required_key_id)

	return false

func _trigger_transition() -> void:
	if not target_scene.is_empty():
		TransitionManager.change_scene_to_pos(target_scene, target_teleport_position, spawn_direction)
	elif current_player_ref:
		TransitionManager.teleport_player(current_player_ref, target_teleport_position, spawn_direction)

func _update_sprite_texture() -> void:
	if not sprite:
		return

	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = custom_scale

	var path: String = DoorData.get_texture_path(door_type)
	if ResourceLoader.exists(path):
		sprite.texture = load(path)
	else:
		push_warning("[Door] Tekstur pintu tidak ditemukan: " + path)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		is_player_in_range = true
		current_player_ref = body
		if auto_teleport_on_touch and not TransitionManager.is_transitioning and not DialogueBox.is_dialogue_open:
			interact()

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		is_player_in_range = false
		if current_player_ref == body:
			current_player_ref = null
