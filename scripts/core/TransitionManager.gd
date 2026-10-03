## Manager terpusat untuk transisi layar (Fade Black, Teleportasi Pemain, & Loading Screen).
##
## Menggunakan ScenePaths untuk target navigasi dan Palette untuk tema warna.
class_name TransitionManagerClass
extends CanvasLayer

const DEFAULT_FADE_DURATION: float = 0.25

var fade_rect: ColorRect
var is_transitioning: bool = false

func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS

	fade_rect = ColorRect.new()
	fade_rect.name = "FadeRect"
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.color = Palette.alpha(Palette.BLACK, 0.0)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade_rect)


## Ganti scene standar UI / Menu (menerima float durasi lama agar kompatibel)
func change_scene(target_path: String, duration: float = DEFAULT_FADE_DURATION) -> void:
	if is_transitioning:
		return

	if not ResourceLoader.exists(target_path):
		push_error("[TransitionManager] Scene tujuan tidak ditemukan: " + target_path)
		return

	is_transitioning = true
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	var tween_out := create_tween()
	tween_out.tween_property(fade_rect, "color:a", 1.0, duration).set_trans(Tween.TRANS_SINE)
	await tween_out.finished

	get_tree().change_scene_to_file(target_path)
	await get_tree().process_frame

	var tween_in := create_tween()
	tween_in.tween_property(fade_rect, "color:a", 0.0, duration).set_trans(Tween.TRANS_SINE)
	await tween_in.finished

	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_transitioning = false


## Ganti scene gameplay yang membutuhkan titik koordinat spawn dan arah hadap pemain
func change_scene_to_pos(target_path: String, target_pos: Vector2, target_dir: String = "depan", duration: float = DEFAULT_FADE_DURATION) -> void:
	if is_transitioning:
		return

	if not ResourceLoader.exists(target_path):
		push_error("[TransitionManager] Scene tujuan tidak ditemukan: " + target_path)
		return

	is_transitioning = true
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	var tween_out := create_tween()
	tween_out.tween_property(fade_rect, "color:a", 1.0, duration).set_trans(Tween.TRANS_SINE)
	await tween_out.finished

	if SaveManager and SaveManager.current_data.has("player"):
		if target_pos != Vector2.ZERO:
			SaveManager.current_data["player"]["position_x"] = target_pos.x
			SaveManager.current_data["player"]["position_y"] = target_pos.y
		SaveManager.current_data["player"]["last_direction"] = target_dir

	get_tree().change_scene_to_file(target_path)
	await get_tree().process_frame

	var tween_in := create_tween()
	tween_in.tween_property(fade_rect, "color:a", 0.0, duration).set_trans(Tween.TRANS_SINE)
	await tween_in.finished

	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_transitioning = false


## Teleportasi posisi karakter di map yang sama tanpa me-reload scene
func teleport_player(player: Player, target_pos: Vector2, target_dir: String = "depan", duration: float = DEFAULT_FADE_DURATION) -> void:
	if is_transitioning or not is_instance_valid(player):
		return

	is_transitioning = true
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	var tween_out := create_tween()
	tween_out.tween_property(fade_rect, "color:a", 1.0, duration).set_trans(Tween.TRANS_SINE)
	await tween_out.finished

	player.global_position = target_pos
	player.velocity = Vector2.ZERO
	player.current_direction = target_dir
	
	if player.get("player_hand_prop"):
		player.player_hand_prop.update_held_prop(target_dir, 1)

	if SaveManager and SaveManager.current_data.has("player"):
		SaveManager.current_data["player"]["position_x"] = target_pos.x
		SaveManager.current_data["player"]["position_y"] = target_pos.y
		SaveManager.current_data["player"]["last_direction"] = target_dir

	await get_tree().create_timer(0.08).timeout

	var tween_in := create_tween()
	tween_in.tween_property(fade_rect, "color:a", 0.0, duration).set_trans(Tween.TRANS_SINE)
	await tween_in.finished

	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_transitioning = false


## Pindah scene menggunakan Loading Screen
func change_scene_with_loading(target_path: String, duration: float = DEFAULT_FADE_DURATION) -> void:
	if is_transitioning:
		return

	if not ResourceLoader.exists(target_path):
		push_error("[TransitionManager] Scene tujuan tidak ditemukan: " + target_path)
		return

	var loading_path: String = ScenePaths.Screens.LOADING_SCREEN
	if not ResourceLoader.exists(loading_path):
		push_warning("[TransitionManager] LoadingScreen.tscn tidak ditemukan di " + loading_path + ", fallback ke change_scene biasa.")
		change_scene(target_path, duration)
		return

	is_transitioning = true
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	var tween_out := create_tween()
	tween_out.tween_property(fade_rect, "color:a", 1.0, duration).set_trans(Tween.TRANS_SINE)
	await tween_out.finished

	var loading_scene: PackedScene = load(loading_path)
	var loading_inst = loading_scene.instantiate()
	if "target_scene_path" in loading_inst:
		loading_inst.target_scene_path = target_path

	var cur_scene = get_tree().current_scene
	get_tree().root.add_child(loading_inst)
	get_tree().current_scene = loading_inst
	if cur_scene:
		cur_scene.queue_free()

	await get_tree().process_frame

	var tween_in := create_tween()
	tween_in.tween_property(fade_rect, "color:a", 0.0, duration).set_trans(Tween.TRANS_SINE)
	await tween_in.finished

	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_transitioning = false
