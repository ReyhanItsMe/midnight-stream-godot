## Manager terpusat untuk konfigurasi aplikasi dan preferensi user (Volume, Display, Gameplay).
##
## Cara pakai:
##   SettingsManager.set_bgm_volume(80)
##   SettingsManager.set_screen_shake(false)
##   SettingsManager.save_settings()
class_name SettingsManagerClass
extends Node

const SETTINGS_FILE_PATH: String = "user://settings.json"

var settings: Dictionary = {
	"bgm_volume": 0.5,
	"sfx_volume": 1.0,
	"screen_shake_enabled": true,
	"text_speed": 0.05
}

func _ready() -> void:
	load_settings()

func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_FILE_PATH):
		save_settings()
		return
		
	var file := FileAccess.open(SETTINGS_FILE_PATH, FileAccess.READ)
	if not file:
		return
		
	var json := JSON.new()
	if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
		settings.merge(json.data, true)
		apply_all_settings()

func save_settings() -> bool:
	var file := FileAccess.open(SETTINGS_FILE_PATH, FileAccess.WRITE)
	if not file:
		push_error("[SettingsManager] Gagal menyimpan settings.")
		return false
		
	file.store_string(JSON.stringify(settings, "\t"))
	file.close()
	apply_all_settings()
	return true

func apply_all_settings() -> void:
	var raw_bgm = settings.get("bgm_volume", 0.5)
	var raw_sfx = settings.get("sfx_volume", 1.0)
	var bgm_percent: int = int(raw_bgm * 100) if float(raw_bgm) <= 1.0 else int(raw_bgm)
	var sfx_percent: int = int(raw_sfx * 100) if float(raw_sfx) <= 1.0 else int(raw_sfx)

	var audio_mgr: Node = get_node_or_null("/root/AudioManager")
	if audio_mgr:
		audio_mgr.set_bgm_volume(bgm_percent)
		audio_mgr.set_sfx_volume(sfx_percent)

func set_bgm_volume(percent: int) -> void:
	settings["bgm_volume"] = clampf(float(percent) / 100.0, 0.0, 1.0)
	var audio_mgr: Node = get_node_or_null("/root/AudioManager")
	if audio_mgr:
		audio_mgr.set_bgm_volume(percent)

func set_sfx_volume(percent: int) -> void:
	settings["sfx_volume"] = clampf(float(percent) / 100.0, 0.0, 1.0)
	var audio_mgr: Node = get_node_or_null("/root/AudioManager")
	if audio_mgr:
		audio_mgr.set_sfx_volume(percent)
