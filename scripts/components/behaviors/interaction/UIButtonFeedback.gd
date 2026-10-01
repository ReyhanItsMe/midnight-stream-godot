class_name UIButtonFeedback
extends Node

const DEFAULT_SFX_PATH: String = "res://assets/audio/sfx/clicks/sfx-click-button.mp3"
const SFX_PITCH_FAST: float = 1.35
const CLICK_SCALE_DOWN: Vector2 = Vector2(0.95, 0.95)
const CLICK_PIXEL_OFFSET_Y: float = 1.5
const PRESS_TWEEN_DURATION: float = 0.06
const RELEASE_TWEEN_DURATION: float = 0.12

@export var target_control: Control
@export var enable_sfx: bool = true
@export var custom_sfx: AudioStream = null

var sfx_player: AudioStreamPlayer
var anim_tween: Tween
var _base_position_y: float = 0.0

func _ready() -> void:
	if not target_control and get_parent() is Control:
		target_control = get_parent() as Control

	if not target_control:
		return

	_setup_audio()

	if target_control is BaseButton:
		var btn := target_control as BaseButton
		btn.button_down.connect(_on_down)
		btn.button_up.connect(_on_up)
		btn.pressed.connect(_on_pressed)

func _setup_audio() -> void:
	if not enable_sfx:
		return

	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "SFX"
	sfx_player.pitch_scale = SFX_PITCH_FAST

	if custom_sfx:
		sfx_player.stream = custom_sfx
	elif ResourceLoader.exists(DEFAULT_SFX_PATH):
		sfx_player.stream = load(DEFAULT_SFX_PATH)

	add_child(sfx_player)

func _on_down() -> void:
	_kill_tween()
	_base_position_y = target_control.position.y
	anim_tween = create_tween().set_parallel(true)
	anim_tween.tween_property(target_control, "scale", CLICK_SCALE_DOWN, PRESS_TWEEN_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	anim_tween.tween_property(target_control, "position:y", _base_position_y + CLICK_PIXEL_OFFSET_Y, PRESS_TWEEN_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_up() -> void:
	_kill_tween()
	anim_tween = create_tween().set_parallel(true)
	anim_tween.tween_property(target_control, "scale", Vector2.ONE, RELEASE_TWEEN_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	anim_tween.tween_property(target_control, "position:y", _base_position_y, RELEASE_TWEEN_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_pressed() -> void:
	if enable_sfx and sfx_player and sfx_player.stream:
		sfx_player.stop()
		sfx_player.play()

func _kill_tween() -> void:
	if anim_tween and anim_tween.is_valid():
		anim_tween.kill()
