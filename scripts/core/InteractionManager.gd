extends Node

signal interact_pressed

var active_interactable: Node2D = null

func register_interactable(interactable: Node2D) -> void:
	active_interactable = interactable

func unregister_interactable(interactable: Node2D) -> void:
	if active_interactable == interactable:
		active_interactable = null

func _unhandled_input(event: InputEvent) -> void:
	var triggered: bool = false

	# Periksa action hanya jika action "interact" sudah terdaftar
	if InputMap.has_action("interact"):
		if event.is_action_pressed("interact"):
			triggered = true

	# Fallback tombol fisik 'E' pada keyboard tanpa bergantung InputMap
	if not triggered and event is InputEventKey:
		if event.pressed and not event.echo and event.keycode == KEY_E:
			triggered = true

	if triggered and is_instance_valid(active_interactable):
		get_viewport().set_input_as_handled()
		trigger_interact()

func trigger_interact() -> void:
	if is_instance_valid(active_interactable) and active_interactable.has_method("interact"):
		active_interactable.interact()
		interact_pressed.emit()
