extends Node

signal inventory_updated
signal hotbar_updated
signal weight_changed(current_weight: float, max_weight: float)
signal item_used(item_id: String, message: String)

const MAX_SLOTS: int = 8
const MAX_HOTBAR: int = 3
const MAX_WEIGHT: float = 15.0

enum ItemType { KEY, CONSUMABLE, DOCUMENT, TOOL }

const ITEM_DB: Dictionary = {
	"kunci_bangsal_perunggu": {
		"name": "KUNCI PERUNGGU",
		"type": ItemType.KEY,
		"weight": 0.5,
		"max_stack": 1,
		"desc": "Kunci tua berbahan perunggu kusam. Berbau karat besi dan darah kering dari pintu Bangsal Timur.",
		"icon_path": "res://assets/sprites/props/key/key-1/Key1-BRONZE.png"
	},
	"kunci_emas_kepala": {
		"name": "KUNCI RUANG DOKTER",
		"type": ItemType.KEY,
		"weight": 0.8,
		"max_stack": 1,
		"desc": "Kunci berukir emas milik kepala sanatorium. Membuka ruang arsip rahasia di lantai utama.",
		"icon_path": "res://assets/sprites/props/key/key-1/Key1-GOLD.png"
	},
	"kunci_kutukan_mata": {
		"name": "KUNCI TERKUTUK",
		"type": ItemType.KEY,
		"weight": 2.5,
		"max_stack": 1,
		"desc": "Kunci aneh yang terasa berdenyut dingin saat digenggam. Seolah ada sesuatu yang mengintip dari lubangnya.",
		"icon_path": "res://assets/sprites/props/key/key-6/CURSE/Key8-CURSE-frame0000.png"
	},
	"baterai_senter": {
		"name": "BATERAI SENTER (AA)",
		"type": ItemType.CONSUMABLE,
		"weight": 1.5,
		"max_stack": 4,
		"desc": "Baterai cadangan berdaya tinggi. Mengisi ulang daya senter sebesar +50%.",
		"icon_path": "res://assets/sprites/props/senter/senter_item.png"
	},
	"peralatan_berat": {
		"name": "AKI CADANGAN TUA",
		"type": ItemType.TOOL,
		"weight": 4.5,
		"max_stack": 2,
		"desc": "Aki timbal bekas generator rumah sakit. Sangat berat dan membuat langkah kaki terasa lambat.",
		"icon_path": "res://assets/sprites/props/key/key-3/Key3-GREY.png"
	}
}

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
	return ITEM_DB.get(item_id, {})


func add_item(item_id: String, amount: int = 1) -> bool:
	if not ITEM_DB.has(item_id):
		return false

	var item_data: Dictionary = ITEM_DB[item_id]
	var added_weight: float = float(item_data["weight"]) * amount

	if current_weight + added_weight > MAX_WEIGHT:
		return false

	var max_stack: int = int(item_data["max_stack"])

	for i in range(MAX_SLOTS):
		if inventory[i].has("id") and inventory[i]["id"] == item_id:
			if inventory[i]["amount"] + amount <= max_stack:
				inventory[i]["amount"] += amount
				_recalculate_weight()
				return true

	for i in range(MAX_SLOTS):
		if not inventory[i].has("id"):
			inventory[i] = {"id": item_id, "amount": amount}
			_recalculate_weight()
			return true

	return false


func remove_item_at_slot(slot_idx: int, amount: int = 1) -> bool:
	if slot_idx < 0 or slot_idx >= MAX_SLOTS:
		return false
	if not inventory[slot_idx].has("id"):
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
	var item_type: int = int(meta.get("type", ItemType.TOOL))

	match item_type:
		ItemType.CONSUMABLE:
			if item_id == "baterai_senter":
				if SaveManager and SaveManager.current_data.has("inventory"):
					var cur_bat: float = float(SaveManager.current_data["inventory"].get("flashlight_battery", 100.0))
					SaveManager.set_flashlight_battery(minf(cur_bat + 50.0, 100.0))
				remove_item_at_slot(slot_idx, 1)
				var msg_bat: String = "Baterai diganti. Daya senter pulih +50%!"
				item_used.emit(item_id, msg_bat)
				return msg_bat

		ItemType.KEY:
			var msg_key: String = "Kunci ini digunakan otomatis saat memeriksa pintu yang terkunci."
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
		if slot.has("id") and ITEM_DB.has(slot["id"]):
			var w: float = float(ITEM_DB[slot["id"]]["weight"])
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
