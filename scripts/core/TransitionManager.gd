extends CanvasLayer

const DEFAULT_FADE_DURATION: float = 0.3

var fade_rect: ColorRect
var is_transitioning: bool = false

func _ready() -> void:
	# Layer tertinggi agar selalu menutupi UI paling atas sekalipun
	layer = 128

	fade_rect = ColorRect.new()
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade_rect)


## Pindah halaman dengan efek Fade Gelap (Fade Out -> Ganti Scene -> Fade In)
func change_scene(target_path: String, duration: float = DEFAULT_FADE_DURATION) -> void:
	if is_transitioning:
		return

	if not ResourceLoader.exists(target_path):
		push_error("[TransitionManager] Scene tujuan tidak ditemukan: " + target_path)
		return

	is_transitioning = true
	# Blokir klik/sentuhan selama proses transisi berlangsung
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	var tween := create_tween()
	# 1. Gelapkan layar
	tween.tween_property(fade_rect, "color:a", 1.0, duration).set_trans(Tween.TRANS_SINE)
	await tween.finished

	# 2. Pindah scene saat layar sedang hitam pekat
	get_tree().change_scene_to_file(target_path)
	await get_tree().process_frame

	# 3. Terangkan kembali layar
	var tween_in := create_tween()
	tween_in.tween_property(fade_rect, "color:a", 0.0, duration).set_trans(Tween.TRANS_SINE)
	await tween_in.finished

	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_transitioning = false
