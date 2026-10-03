## Manager audio terpusat untuk mengontrol BGM dan SFX bus secara dinamis.
##
## Cara pakai:
##   AudioManager.play_menu_bgm()
##   AudioManager.play_bgm(AssetPaths.Audios.BGM_FEAR, 1.0)
##   AudioManager.play_sfx(AssetPaths.Audios.SFX_CLICK)
##   AudioManager.set_bgm_volume(80)
class_name AudioManagerClass
extends Node

const BUS_MASTER: String = "Master"
const BUS_BGM: String = "BGM"
const BUS_SFX: String = "SFX"

var bgm_player: AudioStreamPlayer
var current_bgm_path: String = ""
var bgm_tween: Tween

# Pool SFX agar efek suara bisa diputar simultan
var _sfx_players: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE: int = 6

func _ready() -> void:
	_setup_audio_buses()
	_init_players()
	apply_saved_volume()

## Inisialisasi AudioStreamPlayer untuk BGM dan pool SFX
func _init_players() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = BUS_BGM
	add_child(bgm_player)

	for i in range(SFX_POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = BUS_SFX
		add_child(p)
		_sfx_players.append(p)

## Membuat Bus BGM & SFX secara otomatis jika belum terkonfigurasi di editor
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

## Sinkronisasi volume dari SettingsManager (fallback ke default jika belum siap)
func apply_saved_volume() -> void:
	var settings_mgr := get_node_or_null("/root/SettingsManager")
	if not settings_mgr or not ("settings" in settings_mgr):
		return

	var conf: Dictionary = settings_mgr.settings
	var raw_bgm = conf.get("bgm_volume", 0.5)
	var raw_sfx = conf.get("sfx_volume", 1.0)

	var bgm_val: float = float(raw_bgm) if float(raw_bgm) <= 1.0 else float(raw_bgm) / 100.0
	var sfx_val: float = float(raw_sfx) if float(raw_sfx) <= 1.0 else float(raw_sfx) / 100.0

	set_bgm_volume(int(bgm_val * 100))
	set_sfx_volume(int(sfx_val * 100))

## Memutar musik menu utama dari AssetPaths
func play_menu_bgm(fade_in_duration: float = 0.5) -> void:
	play_bgm(AssetPaths.Audios.BGM_FEAR, fade_in_duration)

## Memutar stream BGM dengan opsi fade in
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

	var bus_idx := AudioServer.get_bus_index(BUS_BGM)
	var is_muted: bool = AudioServer.is_bus_mute(bus_idx) if bus_idx != -1 else false

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

## Menghentikan BGM dengan opsi fade out
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

## Memutar efek suara (SFX) memakai pool player yang sedang nganggur
func play_sfx(sfx_path: String, pitch_scale: float = 1.0) -> void:
	if not ResourceLoader.exists(sfx_path):
		push_error("[AudioManager] File SFX tidak ditemukan: " + sfx_path)
		return

	var stream: AudioStream = load(sfx_path)
	for player in _sfx_players:
		if not player.playing:
			player.stream = stream
			player.pitch_scale = pitch_scale
			player.play()
			return

	# Jika semua player sedang sibuk, pakai player pertama secara paksa
	_sfx_players[0].stream = stream
	_sfx_players[0].pitch_scale = pitch_scale
	_sfx_players[0].play()

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
