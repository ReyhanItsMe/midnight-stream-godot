extends Area2D
class_name SavePoint

signal save_station_triggered

@export var station_name: String = "TERMINAL REKAMAN"

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
	save_station_triggered.emit()
