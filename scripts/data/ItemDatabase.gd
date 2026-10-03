## Kamus data statis seluruh item di dalam game.
##
## Cara pakai:
##   var meta = ItemDatabase.get_item("baterai_senter")
##   var berat = meta.get("weight", 0.0)
class_name ItemDatabase
extends RefCounted

enum ItemType { KEY, CONSUMABLE, DOCUMENT, TOOL }

const ITEMS: Dictionary = {
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

static func get_item(item_id: String) -> Dictionary:
	return ITEMS.get(item_id, {})

static func has_item(item_id: String) -> bool:
	return ITEMS.has(item_id)
