## Manager terpusat untuk transisi layar (Fade Black & Loading Screen beranimasi).
##
## Cara pakai:
##   TransitionManager.change_scene("res://scenes/gameplay/Room1.tscn")
##   TransitionManager.change_scene_with_loading(SaveManager.get_saved_scene_path())
##   TransitionManager.change_scene("res://scenes/ui/Menu.tscn", 0.5)
class_name TransitionManagerClass
extends CanvasLayer

const DEFAULT_FADE_DURATION: float = 0.3
const LOADING_SCREEN_PATH: String = "res://scenes/ui/screens/LoadingScreen.tscn"

var fade_rect: ColorRect
var is_transitioning: bool = false

func _ready() -> void:
	# Layer 128 agar selalu menutupi elemen gameplay dan UI modal
	layer = 128

	fade_rect = ColorRect.new()
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade_rect)


## Pindah halaman dengan efek Fade Gelap standar (Fade Out -> Ganti Scene -> Fade In)
func change_scene(target_path: String, duration: float = DEFAULT_FADE_DURATION) -> void:
	if is_transitioning:
		return

	if not ResourceLoader.exists(target_path):
		push_error("[TransitionManager] Scene tujuan tidak ditemukan: " + target_path)
		return

	is_transitioning = true
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, duration).set_trans(Tween.TRANS_SINE)
	await tween.finished

	get_tree().change_scene_to_file(target_path)
	await get_tree().process_frame

	var tween_in := create_tween()
	tween_in.tween_property(fade_rect, "color:a", 0.0, duration).set_trans(Tween.TRANS_SINE)
	await tween_in.finished

	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_transitioning = false


## Pindah ke gameplay dengan Layar Loading beranimasi
func change_scene_with_loading(target_path: String, duration: float = DEFAULT_FADE_DURATION) -> void:
	if is_transitioning:
		return

	if not ResourceLoader.exists(target_path):
		push_error("[TransitionManager] Scene tujuan tidak ditemukan: " + target_path)
		return

	if not ResourceLoader.exists(LOADING_SCREEN_PATH):
		push_warning("[TransitionManager] LoadingScreen.tscn tidak ditemukan, fallback ke change_scene biasa.")
		change_scene(target_path, duration)
		return

	is_transitioning = true
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	# 1. Fade out ke hitam
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, duration).set_trans(Tween.TRANS_SINE)
	await tween.finished

	# 2. Siapkan dan pasang LoadingScreen
	var loading_scene: PackedScene = load(LOADING_SCREEN_PATH)
	var loading_inst = loading_scene.instantiate()
	loading_inst.target_scene_path = target_path

	var cur_scene = get_tree().current_scene
	get_tree().root.add_child(loading_inst)
	get_tree().current_scene = loading_inst
	if cur_scene:
		cur_scene.queue_free()

	await get_tree().process_frame

	# 3. Fade in membuka layar loading screen
	var tween_in := create_tween()
	tween_in.tween_property(fade_rect, "color:a", 0.0, duration).set_trans(Tween.TRANS_SINE)
	await tween_in.finished

	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_transitioning = false
