## Manager terpusat untuk data status gameplay, Sanity Rian, dan 20 Slot Archive.
##
## Cara pakai:
##   SaveManager.damage_sanity(15.0)
##   SaveManager.save_game(1)
##   SaveManager.load_game(1)
##   SaveManager.reset_to_new_game()
class_name SaveManagerClass
extends Node

# --- SIGNALS ---
signal sanity_changed(new_sanity: float, max_sanity: float)
signal sanity_depleted
signal sanity_critical(is_critical: bool)
signal inventory_synced

# --- CONSTANTS ---
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
		"position_x": -180.0,
		"position_y": -20.0,
		"last_direction": "depan",
		"sanity": 100.0,
		"max_sanity": 100.0
	},
	"inventory": {
		"has_flashlight": true,
		"flashlight_battery": 100.0,
		"items": [],
		"hotbar": [],
		"current_weight": 0.0
	},
	"story_flags": {
		"chapter": 1,
		"lights_out": false,
		"pc_stream_started": false,
		"door_unlocked": false,
		"current_event": "none"
	}
}

var current_data: Dictionary = {}
var active_slot: int = 1
var is_in_critical_sanity: bool = false
var play_time_timer: float = 0.0

func _ready() -> void:
	current_data = default_data.duplicate(true)

func _process(delta: float) -> void:
	play_time_timer += delta
	if play_time_timer >= 1.0:
		play_time_timer -= 1.0
		if current_data.has("meta"):
			current_data["meta"]["play_time_seconds"] = current_data["meta"].get("play_time_seconds", 0) + 1

# ==============================================================================
# INTEGRASI INVENTORY
# ==============================================================================

func _sync_from_inventory_manager() -> void:
	var inv_mgr: Node = get_node_or_null("/root/InventoryManager")
	if not inv_mgr:
		return

	if not current_data.has("inventory"):
		current_data["inventory"] = {}

	current_data["inventory"]["items"] = inv_mgr.inventory.duplicate(true)
	current_data["inventory"]["hotbar"] = inv_mgr.hotbar.duplicate(true)
	current_data["inventory"]["current_weight"] = inv_mgr.current_weight

func _push_to_inventory_manager() -> void:
	var inv_mgr: Node = get_node_or_null("/root/InventoryManager")
	if not inv_mgr:
		return

	var inv_data: Dictionary = current_data.get("inventory", {})
	var saved_items: Array = inv_data.get("items", [])
	var saved_hotbar: Array = inv_data.get("hotbar", [])

	if saved_items.is_empty():
		inv_mgr._initialize_empty_slots()
	else:
		inv_mgr.inventory.assign(saved_items.duplicate(true))

	if not saved_hotbar.is_empty():
		inv_mgr.hotbar.assign(saved_hotbar.duplicate(true))

	if inv_mgr.has_method("_recalculate_weight"):
		inv_mgr._recalculate_weight()

	inventory_synced.emit()

func add_item_to_inventory(item_id: String, amount: int = 1) -> bool:
	var inv_mgr: Node = get_node_or_null("/root/InventoryManager")
	if inv_mgr and inv_mgr.has_method("add_item"):
		var res: bool = inv_mgr.add_item(item_id, amount)
		_sync_from_inventory_manager()
		return res
	return false

func has_key(key_id: String) -> bool:
	var inv_mgr: Node = get_node_or_null("/root/InventoryManager")
	if inv_mgr and inv_mgr.has_method("has_item"):
		return inv_mgr.has_item(key_id)
	return false

func set_flashlight_battery(val: float) -> void:
	current_data["inventory"]["flashlight_battery"] = clampf(val, 0.0, MAX_BATTERY)

# ==============================================================================
# SISTEM SANITY
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
# SISTEM 20 SLOT RECOVERY LOG & LOADGAME
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

func get_slot_info(slot_index: int) -> Dictionary:
	if not has_slot_file(slot_index):
		return {"exists": false}

	var file := FileAccess.open(get_slot_path(slot_index), FileAccess.READ)
	if not file:
		return {"exists": false}

	var json := JSON.new()
	if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
		var meta: Dictionary = json.data.get("meta", {})
		return {
			"exists": true,
			"location": meta.get("chapter_title", "SANATORIUM LOG"),
			"timestamp": meta.get("save_date", "")
		}
	return {"exists": false}

func get_saved_scene_path() -> String:
	if current_data.has("meta") and current_data["meta"].has("scene_path"):
		var path: String = current_data["meta"]["scene_path"]
		if ResourceLoader.exists(path):
			return path
	return DEFAULT_GAMEPLAY_SCENE

func save_game(slot_index: int = -1) -> bool:
	if slot_index == -1:
		slot_index = active_slot
	return save_to_slot(slot_index)

func load_game(slot_index: int) -> bool:
	return load_from_slot(slot_index)

func save_to_slot(slot_index: int = active_slot) -> bool:
	active_slot = clampi(slot_index, 1, MAX_SLOTS)
	current_data["meta"]["save_date"] = Time.get_datetime_string_from_system(false, true)

	var scene_now := get_tree().current_scene
	if scene_now and scene_now.scene_file_path != "":
		current_data["meta"]["scene_path"] = scene_now.scene_file_path

	_sync_from_inventory_manager()

	var file := FileAccess.open(get_slot_path(active_slot), FileAccess.WRITE)
	if not file:
		push_error("[SaveManager] Gagal membuka file save slot: ", FileAccess.get_open_error())
		return false

	file.store_string(JSON.stringify(current_data, "\t"))
	file.close()
	print("[SaveManager] Sukses simpan progress ke Slot #", active_slot)
	return true

func load_from_slot(slot_index: int) -> bool:
	if not has_slot_file(slot_index):
		return false

	var file := FileAccess.open(get_slot_path(slot_index), FileAccess.READ)
	if not file:
		return false

	var json := JSON.new()
	if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
		current_data = json.data
		active_slot = slot_index

		_push_to_inventory_manager()

		var cur_san: float = get_current_sanity()
		is_in_critical_sanity = (cur_san <= CRITICAL_SANITY_THRESHOLD)
		sanity_changed.emit(cur_san, MAX_SANITY)
		print("[SaveManager] Sukses load data dari Slot #", slot_index)
		return true

	return false

func delete_slot(slot_index: int) -> bool:
	if has_slot_file(slot_index):
		DirAccess.remove_absolute(get_slot_path(slot_index))
		print("[SaveManager] Slot #", slot_index, " berhasil dihapus.")
		return true
	return false

func reset_to_new_game() -> void:
	current_data = default_data.duplicate(true)
	is_in_critical_sanity = false
	_push_to_inventory_manager()
	sanity_changed.emit(MAX_SANITY, MAX_SANITY)
