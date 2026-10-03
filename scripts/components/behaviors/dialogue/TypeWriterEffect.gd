## Node pembantu untuk menghasilkan efek ketikan teks mesin tik per karakter dengan SFX audio.
##
## Cara pakai:
##   var tw = TypewriterEffect.new()
##   add_child(tw)
##   tw.typing_finished.connect(func(): print("Selesai ngetik!"))
##   tw.start_typing(my_label, "Halo Rian...", 40.0)
##   # Untuk skip langsung ke teks penuh saat tombol ditekan:
##   if tw.is_active():
##       tw.finish()
class_name TypewriterEffect
extends Node

signal character_typed(char_index: int)
signal typing_finished

const DEFAULT_SFX_PATH: String = AssetPaths.Audios.SFX_CLICK

var target_label: Label
var sfx_player: AudioStreamPlayer

var is_typing: bool = false
var text_content: String = ""
var speed: float = 36.0
var visible_chars_count: float = 0.0
var last_char_index: int = 0

func _ready() -> void:
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "SFX"
	sfx_player.volume_db = -14.0
	if ResourceLoader.exists(DEFAULT_SFX_PATH):
		sfx_player.stream = load(DEFAULT_SFX_PATH)
	add_child(sfx_player)

func start_typing(label: Label, text: String, char_speed: float = 36.0) -> void:
	target_label = label
	text_content = text
	speed = char_speed
	visible_chars_count = 0.0
	last_char_index = 0

	target_label.text = text_content
	target_label.visible_characters = 0
	is_typing = true

func _process(delta: float) -> void:
	if not is_typing or not target_label:
		return

	visible_chars_count += speed * delta
	var current_idx: int = int(visible_chars_count)
	target_label.visible_characters = current_idx

	if current_idx > last_char_index:
		if current_idx % 2 == 0 and sfx_player and sfx_player.stream:
			sfx_player.pitch_scale = randf_range(1.9, 2.3)
			sfx_player.play()
		last_char_index = current_idx
		character_typed.emit(current_idx)

	if target_label.visible_characters >= text_content.length():
		finish()

func finish() -> void:
	if not is_typing:
		return
	is_typing = false
	if target_label:
		target_label.visible_characters = -1
	typing_finished.emit()

func is_active() -> bool:
	return is_typing
