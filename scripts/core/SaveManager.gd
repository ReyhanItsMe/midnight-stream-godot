extends Node

# --- SIGNALS ---
signal sanity_changed(new_sanity: float, max_sanity: float)
signal sanity_depleted
signal sanity_critical(is_critical: bool)
signal inventory_updated(keys: Array, has_flashlight: bool, battery: float)

# --- CONSTANTS ---
const SETTINGS_FILE_PATH: String = "user://settings.json"
const SLOT_FILE_TEMPLATE: String = "user://save_slot_%d.json"
const MAX_SLOTS: int = 20
const MAX_SANITY: float = 100.0
const MAX_BATTERY: float = 100.0
const CRITICAL_SANITY_THRESHOLD: float = 25.0
const DEFAULT_GAMEPLAY_SCENE: String = "res://scenes/gameplay/prologue/Prologue.tscn"

# --- DEFAULT SCHEMA ---
var default_data: Dictionary = {
	"meta": {
		"save_date": "",
		"chapter_title": "CHAPTER 1 // SANATORIUM DAHLIA",
		"play_time_seconds": 0,
		"scene_path": DEFAULT_GAMEPLAY_SCENE
	},
	"player": {
		"position_x": 0.0,
		"position_y": 20.0,
		"last_direction": "depan",
		"sanity": 100.0,
		"max_sanity": 100.0
	},
	"inventory": {
		"has_flashlight": true,
		"flashlight_battery": 100.0,
		"keys": []
	},
	"story_flags": {
		"chapter": 1,
		"lights_out": false,
		"pc_stream_started": false,
		"door_unlocked": false,
		"current_event": "none"
	},
	"settings": {
		"bgm_volume": 0.5,
		"sfx_volume": 1.0,
		"screen_shake_enabled": true,
		"text_speed": 0.05
	}
}

var current_data: Dictionary = {}
var active_slot: int = 1
var is_in_critical_sanity: bool = false
var play_time_timer: float = 0.0

func _ready() -> void:
	current_data = default_data.duplicate(true)
	load_settings()
	apply_audio_settings()

func _process(delta: float) -> void:
	play_time_timer += delta
	if play_time_timer >= 1.0:
		play_time_timer -= 1.0
		if current_data.has("meta"):
			current_data["meta"]["play_time_seconds"] = current_data["meta"].get("play_time_seconds", 0) + 1


# ==============================================================================
# SISTEM MEKANIK SANITY
# ==============================================================================

func get_current_sanity() -> float:
	if current_data.has("player") and current_data["player"].has("sanity"):
		return float(current_data["player"]["sanity"])
	return MAX_SANITY


func get_sanity_ratio() -> float:
	return get_current_sanity() / MAX_SANITY


func damage_sanity(amount: float) -> void:
	if amount <= 0.0:
		return
	var current_sanity: float = clampf(get_current_sanity() - amount, 0.0, MAX_SANITY)
	current_data["player"]["sanity"] = current_sanity
	sanity_changed.emit(current_sanity, MAX_SANITY)
	_check_sanity_status(current_sanity)


func restore_sanity(amount: float) -> void:
	if amount <= 0.0:
		return
	var current_sanity: float = clampf(get_current_sanity() + amount, 0.0, MAX_SANITY)
	current_data["player"]["sanity"] = current_sanity
	sanity_changed.emit(current_sanity, MAX_SANITY)
	_check_sanity_status(current_sanity)


func _check_sanity_status(val: float) -> void:
	if val <= CRITICAL_SANITY_THRESHOLD and not is_in_critical_sanity:
		is_in_critical_sanity = true
		sanity_critical.emit(true)
	elif val > CRITICAL_SANITY_THRESHOLD and is_in_critical_sanity:
		is_in_critical_sanity = false
		sanity_critical.emit(false)

	if is_zero_approx(val):
		sanity_depleted.emit()


# ==============================================================================
# SISTEM INVENTORY & ITEM STORY
# ==============================================================================

func add_key(key_id: String) -> void:
	var keys: Array = current_data["inventory"]["keys"]
	if not key_id in keys:
		keys.append(key_id)
		inventory_updated.emit(keys, current_data["inventory"]["has_flashlight"], current_data["inventory"]["flashlight_battery"])


func has_key(key_id: String) -> bool:
	return key_id in current_data["inventory"]["keys"]


func set_flashlight_battery(val: float) -> void:
	current_data["inventory"]["flashlight_battery"] = clampf(val, 0.0, MAX_BATTERY)
	inventory_updated.emit(current_data["inventory"]["keys"], current_data["inventory"]["has_flashlight"], current_data["inventory"]["flashlight_battery"])


# ==============================================================================
# SISTEM 20 SLOT RECOVERY LOG
# ==============================================================================

func get_slot_path(slot_index: int) -> String:
	return SLOT_FILE_TEMPLATE % clampi(slot_index, 1, MAX_SLOTS)


func has_slot_file(slot_index: int) -> bool:
	return FileAccess.file_exists(get_slot_path(slot_index))


func get_slot_summary(slot_index: int) -> String:
	if not has_slot_file(slot_index):
		return "EMPTY ARCHIVE SLOT"

	var file := FileAccess.open(get_slot_path(slot_index), FileAccess.READ)
	if not file:
		return "CORRUPTED LOG"

	var json := JSON.new()
	if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
		var meta: Dictionary = json.data.get("meta", {})
		var title: String = meta.get("chapter_title", "SANATORIUM LOG")
		var date_str: String = meta.get("save_date", "")
		return "%s [%s]" % [title, date_str] if date_str != "" else title

	return "EMPTY ARCHIVE SLOT"


func get_saved_scene_path() -> String:
	if current_data.has("meta") and current_data["meta"].has("scene_path"):
		var path: String = current_data["meta"]["scene_path"]
		if ResourceLoader.exists(path):
			return path
	return DEFAULT_GAMEPLAY_SCENE


func save_to_slot(slot_index: int = active_slot) -> bool:
	active_slot = clampi(slot_index, 1, MAX_SLOTS)
	current_data["meta"]["save_date"] = Time.get_datetime_string_from_system(false, true)

	var scene_now := get_tree().current_scene
	if scene_now and scene_now.scene_file_path != "":
		current_data["meta"]["scene_path"] = scene_now.scene_file_path

	var file := FileAccess.open(get_slot_path(active_slot), FileAccess.WRITE)
	if not file:
		push_error("[SaveManager] Gagal membuka file save slot: ", FileAccess.get_open_error())
		return false

	file.store_string(JSON.stringify(current_data, "\t"))
	file.close()
	save_settings()
	print("[SaveManager] Berhasil menyimpan progress ke Slot #", active_slot, " | Scene: ", current_data["meta"]["scene_path"])
	return true


func load_from_slot(slot_index: int) -> bool:
	if not has_slot_file(slot_index):
		return false

	var file := FileAccess.open(get_slot_path(slot_index), FileAccess.READ)
	if not file:
		return false

	var json := JSON.new()
	if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
		var saved_settings: Dictionary = current_data.get("settings", {}).duplicate(true)
		current_data = json.data
		current_data["settings"] = saved_settings
		active_slot = slot_index

		var cur_san: float = get_current_sanity()
		is_in_critical_sanity = (cur_san <= CRITICAL_SANITY_THRESHOLD)
		sanity_changed.emit(cur_san, MAX_SANITY)
		print("[SaveManager] Berhasil memuat data dari Slot #", slot_index, " | Target Scene: ", get_saved_scene_path())
		return true

	return false


func delete_slot(slot_index: int) -> bool:
	if has_slot_file(slot_index):
		DirAccess.remove_absolute(get_slot_path(slot_index))
		print("[SaveManager] Slot #", slot_index, " berhasil dihapus.")
		return true
	return false


# ==============================================================================
# SETTINGS PERSISTENCE & HARDWARE AUDIO SYNC
# ==============================================================================

func save_game() -> bool:
	return save_settings()


func save_settings() -> bool:
	var file := FileAccess.open(SETTINGS_FILE_PATH, FileAccess.WRITE)
	if not file:
		return false
	file.store_string(JSON.stringify(current_data.get("settings", {}), "\t"))
	file.close()
	apply_audio_settings()
	return true


func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_FILE_PATH):
		return
	var file := FileAccess.open(SETTINGS_FILE_PATH, FileAccess.READ)
	if not file:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
		current_data["settings"] = json.data
		apply_audio_settings()


## Menerapkan volume secara menyeluruh ke AudioServer Godot & AudioManager
func apply_audio_settings() -> void:
	var settings_dict: Dictionary = current_data.get("settings", {})
	var raw_bgm = settings_dict.get("bgm_volume", 0.5)
	var raw_sfx = settings_dict.get("sfx_volume", 1.0)

	var bgm_vol: float = float(raw_bgm) if float(raw_bgm) <= 1.0 else float(raw_bgm) / 100.0
	var sfx_vol: float = float(raw_sfx) if float(raw_sfx) <= 1.0 else float(raw_sfx) / 100.0

	set_bus_volume("BGM", bgm_vol)
	set_bus_volume("SFX", sfx_vol)

	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr and audio_mgr.has_method("apply_saved_volume"):
		audio_mgr.apply_saved_volume()


func set_bus_volume(bus_name: String, linear_val: float) -> void:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		if linear_val <= 0.001:
			AudioServer.set_bus_mute(bus_idx, true)
			AudioServer.set_bus_volume_db(bus_idx, -80.0)
		else:
			AudioServer.set_bus_mute(bus_idx, false)
			AudioServer.set_bus_volume_db(bus_idx, linear_to_db(linear_val))


func reset_to_new_game() -> void:
	var saved_settings: Dictionary = current_data.get("settings", {}).duplicate(true)
	current_data = default_data.duplicate(true)
	current_data["settings"] = saved_settings
	is_in_critical_sanity = false
	sanity_changed.emit(MAX_SANITY, MAX_SANITY)
