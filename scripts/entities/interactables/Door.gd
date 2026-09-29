extends Area2D
class_name Door

@export_file("*.tscn") var target_scene: String = ""
@export var target_spawn_position: Vector2 = Vector2.ZERO
@export var is_locked: bool = false
@export var required_key_id: String = ""
@export var door_name: String = "DOOR"

func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		InteractionManager.register_interactable(self)

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		InteractionManager.unregister_interactable(self)

func interact() -> void:
	if is_locked:
		var keys: Array = SaveManager.current_data["inventory"]["keys"]
		if required_key_id != "" and required_key_id in keys:
			is_locked = false
			print("[Door] Kunci cocok. Pintu terbuka.")
		else:
			print("[Door] Pintu terkunci!")
			return

	if target_scene != "":
		# Catat posisi target spawn
		SaveManager.current_data["player"]["position_x"] = target_spawn_position.x
		SaveManager.current_data["player"]["position_y"] = target_spawn_position.y
		TransitionManager.change_scene(target_scene, 0.4)
