extends Node

const BUS_MASTER: String = "Master"
const BUS_BGM: String = "BGM"
const BUS_SFX: String = "SFX"
const MENU_BGM_PATH: String = "res://assets/audio/bgm/bgm-fear.mp3"

var bgm_player: AudioStreamPlayer
var current_bgm_path: String = ""
var bgm_tween: Tween

func _ready() -> void:
	_setup_audio_buses()

	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = BUS_BGM
	add_child(bgm_player)

	# Terapkan volume awal
	apply_saved_volume()


## Membuat Bus BGM & SFX secara otomatis lewat kode jika belum ada
func _setup_audio_buses() -> void:
	if AudioServer.get_bus_index(BUS_BGM) == -1:
		var idx := AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, BUS_BGM)
		AudioServer.set_bus_send(idx, BUS_MASTER)

	if AudioServer.get_bus_index(BUS_SFX) == -1:
		var idx := AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, BUS_SFX)
		AudioServer.set_bus_send(idx, BUS_MASTER)


## Fungsi sinkronisasi volume dari SaveManager
func apply_saved_volume() -> void:
	var save_mgr := get_node_or_null("/root/SaveManager")
	if not save_mgr or not ("current_data" in save_mgr):
		return

	var conf: Dictionary = save_mgr.current_data.get("settings", {})
	
	# Ambil data (bisa berupa 0.0 - 1.0 atau 0 - 100)
	var raw_bgm = conf.get("bgm_volume", 0.5)
	var raw_sfx = conf.get("sfx_volume", 1.0)

	var bgm_val: float = float(raw_bgm) if float(raw_bgm) <= 1.0 else float(raw_bgm) / 100.0
	var sfx_val: float = float(raw_sfx) if float(raw_sfx) <= 1.0 else float(raw_sfx) / 100.0

	set_bgm_volume(int(bgm_val * 100))
	set_sfx_volume(int(sfx_val * 100))


## Memutar musik menu. Jika lagu yang sama sudah menyala, tidak akan di-restart.
func play_menu_bgm(fade_in_duration: float = 0.5) -> void:
	play_bgm(MENU_BGM_PATH, fade_in_duration)


func play_bgm(track_path: String, fade_in_duration: float = 0.5) -> void:
	if current_bgm_path == track_path and bgm_player.playing:
		return

	if not ResourceLoader.exists(track_path):
		push_error("[AudioManager] File BGM tidak ditemukan: " + track_path)
		return

	if bgm_tween and bgm_tween.is_valid():
		bgm_tween.kill()

	var stream: AudioStream = load(track_path)
	if stream is AudioStreamMP3:
		stream.loop = true

	current_bgm_path = track_path
	bgm_player.stream = stream

	# Cek apakah bus BGM di-mute atau volume 0
	var bus_idx := AudioServer.get_bus_index(BUS_BGM)
	var is_muted := false
	if bus_idx != -1:
		is_muted = AudioServer.is_bus_mute(bus_idx)

	if is_muted:
		bgm_player.volume_db = -80.0
		bgm_player.play()
		return

	if fade_in_duration > 0.0:
		bgm_player.volume_db = -40.0
		bgm_player.play()
		bgm_tween = create_tween()
		bgm_tween.tween_property(bgm_player, "volume_db", 0.0, fade_in_duration)
	else:
		bgm_player.volume_db = 0.0
		bgm_player.play()


## Menghentikan BGM dengan efek suara mengecil perlahan
func stop_bgm(fade_out_duration: float = 0.6) -> void:
	if not bgm_player.playing:
		return

	if bgm_tween and bgm_tween.is_valid():
		bgm_tween.kill()

	if fade_out_duration > 0.0:
		bgm_tween = create_tween()
		bgm_tween.tween_property(bgm_player, "volume_db", -40.0, fade_out_duration)
		bgm_tween.tween_callback(func():
			bgm_player.stop()
			current_bgm_path = ""
		)
	else:
		bgm_player.stop()
		current_bgm_path = ""


func set_bgm_volume(percent: int) -> void:
	_apply_bus_volume(BUS_BGM, percent)


func set_sfx_volume(percent: int) -> void:
	_apply_bus_volume(BUS_SFX, percent)


func _apply_bus_volume(bus_name: String, percent: int) -> void:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		return

	var clamped := clampi(percent, 0, 100)
	if clamped == 0:
		AudioServer.set_bus_mute(bus_idx, true)
		AudioServer.set_bus_volume_db(bus_idx, -80.0)
	else:
		AudioServer.set_bus_mute(bus_idx, false)
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(float(clamped) / 100.0))
