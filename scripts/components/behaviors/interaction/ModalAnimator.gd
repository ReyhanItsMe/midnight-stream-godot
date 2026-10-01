class_name ModalAnimator
extends Node

const DURATION_OPEN_FADE: float = 0.16
const DURATION_OPEN_SCALE: float = 0.18
const DURATION_CLOSE_FADE: float = 0.12
const INITIAL_SCALE: Vector2 = Vector2(0.92, 0.92)

var _tween: Tween

func animate_open(target_root: Control, target_box: Control) -> void:
	_kill_tween()
	target_root.visible = true
	target_box.scale = INITIAL_SCALE
	target_box.pivot_offset = target_box.custom_minimum_size / 2.0

	_tween = target_root.create_tween().set_parallel(true)
	_tween.tween_property(target_root, "modulate:a", 1.0, DURATION_OPEN_FADE).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(target_box, "scale", Vector2.ONE, DURATION_OPEN_SCALE).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func animate_close(target_root: Control, on_complete: Callable) -> void:
	_kill_tween()
	_tween = target_root.create_tween()
	_tween.tween_property(target_root, "modulate:a", 0.0, DURATION_CLOSE_FADE).set_trans(Tween.TRANS_SINE)
	_tween.tween_callback(func():
		target_root.visible = false
		if on_complete.is_valid():
			on_complete.call()
	)

func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()

