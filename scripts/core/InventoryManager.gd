## Manager inventaris untuk mengelola tas, hotbar 3 slot, dan berat beban.
##
## Cara pakai:
##   InventoryManager.add_item("baterai_senter", 1)
##   InventoryManager.use_item_at_slot(0)
##   InventoryManager.assign_to_hotbar(0, 1)
class_name InventoryManagerClass
extends Node

signal inventory_updated
signal hotbar_updated
signal weight_changed(current_weight: float, max_weight: float)
signal item_used(item_id: String, message: String)

const MAX_SLOTS: int = 8
const MAX_HOTBAR: int = 3
const MAX_WEIGHT: float = 15.0

var inventory: Array[Dictionary] = []
var hotbar: Array[Dictionary] = []
var current_weight: float = 0.0

func _ready() -> void:
	_initialize_empty_slots()

func _initialize_empty_slots() -> void:
	inventory.clear()
	for i in range(MAX_SLOTS):
		inventory.append({})

	hotbar.clear()
	for i in range(MAX_HOTBAR):
		hotbar.append({})

	_recalculate_weight()

func get_item_meta(item_id: String) -> Dictionary:
	return ItemDatabase.get_item(item_id)

func add_item(item_id: String, amount: int = 1) -> bool:
	if not ItemDatabase.has_item(item_id):
		return false

	var item_data: Dictionary = ItemDatabase.get_item(item_id)
	var added_weight: float = float(item_data.get("weight", 0.0)) * amount

	if current_weight + added_weight > MAX_WEIGHT:
		return false

	var max_stack: int = int(item_data.get("max_stack", 1))

	# Cek stacking slot yang sudah ada
	for i in range(MAX_SLOTS):
		if inventory[i].has("id") and inventory[i]["id"] == item_id:
			if inventory[i]["amount"] + amount <= max_stack:
				inventory[i]["amount"] += amount
				_recalculate_weight()
				return true

	# Isi slot kosong
	for i in range(MAX_SLOTS):
		if not inventory[i].has("id"):
			inventory[i] = {"id": item_id, "amount": amount}
			_recalculate_weight()
			return true

	return false

func remove_item_at_slot(slot_idx: int, amount: int = 1) -> bool:
	if slot_idx < 0 or slot_idx >= MAX_SLOTS or not inventory[slot_idx].has("id"):
		return false

	var removed_id: String = inventory[slot_idx]["id"]
	if inventory[slot_idx]["amount"] > amount:
		inventory[slot_idx]["amount"] -= amount
	else:
		inventory[slot_idx] = {}
		_clean_missing_hotbar_ref(removed_id)

	_recalculate_weight()
	return true

func use_item_at_slot(slot_idx: int) -> String:
	if slot_idx < 0 or slot_idx >= MAX_SLOTS or not inventory[slot_idx].has("id"):
		return "Slot kosong."

	var item_id: String = str(inventory[slot_idx]["id"])
	var meta: Dictionary = get_item_meta(item_id)
	var item_type: int = int(meta.get("type", ItemDatabase.ItemType.TOOL))

	match item_type:
		ItemDatabase.ItemType.CONSUMABLE:
			if item_id == "baterai_senter":
				var save_mgr := get_node_or_null("/root/SaveManager")
				if save_mgr and save_mgr.current_data.has("inventory"):
					var cur_bat: float = float(save_mgr.current_data["inventory"].get("flashlight_battery", 100.0))
					save_mgr.set_flashlight_battery(minf(cur_bat + 50.0, 100.0))

				remove_item_at_slot(slot_idx, 1)
				var msg_bat: String = "Baterai diganti. Daya senter pulih +50%!"
				item_used.emit(item_id, msg_bat)
				return msg_bat

		ItemDatabase.ItemType.KEY:
			var msg_key: String = "Kunci ini digunakan otomatis saat memeriksa pintu."
			item_used.emit(item_id, msg_key)
			return msg_key

		_:
			var item_name: String = str(meta.get("name", "ITEM"))
			var msg_info: String = "Item diperiksa: " + item_name
			item_used.emit(item_id, msg_info)
			return msg_info

	return "Tidak dapat digunakan saat ini."

func assign_to_hotbar(inv_slot_idx: int, hotbar_idx: int = -1) -> String:
	if inv_slot_idx < 0 or inv_slot_idx >= MAX_SLOTS or not inventory[inv_slot_idx].has("id"):
		return "Pilih item terlebih dahulu."

	var item_id: String = inventory[inv_slot_idx]["id"]

	# Lepas jika sudah ada di slot hotbar lain
	for i in range(MAX_HOTBAR):
		if hotbar[i].has("id") and hotbar[i]["id"] == item_id:
			hotbar[i] = {}
			hotbar_updated.emit()
			return "Dilepas dari Hotbar #" + str(i + 1)

	var target_hb: int = hotbar_idx
	if target_hb == -1:
		for i in range(MAX_HOTBAR):
			if not hotbar[i].has("id"):
				target_hb = i
				break
		if target_hb == -1:
			target_hb = 0 

	hotbar[target_hb] = {"id": item_id, "amount": inventory[inv_slot_idx]["amount"]}
	hotbar_updated.emit()
	return "Dipasang ke Hotbar #" + str(target_hb + 1)

func _clean_missing_hotbar_ref(item_id: String) -> void:
	if has_item_in_bag(item_id):
		return
	for i in range(MAX_HOTBAR):
		if hotbar[i].has("id") and hotbar[i]["id"] == item_id:
			hotbar[i] = {}
	hotbar_updated.emit()

func has_item_in_bag(item_id: String) -> bool:
	for slot in inventory:
		if slot.has("id") and slot["id"] == item_id:
			return true
	return false

func has_item(item_id: String) -> bool:
	if has_item_in_bag(item_id):
		return true
	for slot in hotbar:
		if slot.has("id") and slot["id"] == item_id:
			return true
	return false

func _recalculate_weight() -> void:
	current_weight = 0.0
	for slot in inventory:
		if slot.has("id") and ItemDatabase.has_item(slot["id"]):
			var meta: Dictionary = ItemDatabase.get_item(slot["id"])
			var w: float = float(meta.get("weight", 0.0))
			current_weight += w * int(slot["amount"])

	weight_changed.emit(current_weight, MAX_WEIGHT)
	inventory_updated.emit()

func get_encumbrance_level() -> String:
	var ratio: float = current_weight / MAX_WEIGHT
	if ratio >= 0.8:
		return "HEAVY"
	elif ratio >= 0.5:
		return "MEDIUM"
	return "LIGHT"
