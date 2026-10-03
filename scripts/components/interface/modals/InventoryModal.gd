## Jendela modal inventaris/tas streamer untuk mengelola 8 slot tas, 3 slot hotbar, dan kalkulasi berat beban.
##
## Cara pakai:
##   var inv_ui = InventoryModal.new()
##   add_child(inv_ui)
##   inv_ui.open()   # Membuka modal tas dan menjeda tree permainan (pause)
##   inv_ui.close()  # Menutup modal dan melanjutkan permainan
class_name InventoryModal
extends BaseModal

static var is_inventory_open: bool = false

# Ukuran modal (isi minimalnya sekitar 540px, jadi jangan dikecilkan di bawah itu)
const MODAL_SIZE: Vector2 = Vector2(560, 268)

# Layout area atas layar (HUD)
const PAUSE_BTN_BOTTOM: float = 34.0          # batas bawah tombol PAUSE di HUD
const DEBUG_BTN_SIZE: Vector2 = Vector2(72, 18)
const DEBUG_BTN_GAP: float = 4.0              # jarak tombol tes item ke tombol pause
const MODAL_GAP_BELOW_HUD: float = 6.0        # jarak modal ke tombol tes item

const COL_BORDER_GOLD: Color = Color(0.95, 0.82, 0.25, 0.95)
const COL_BORDER_SLATE: Color = Color(0.24, 0.28, 0.38, 0.85)
const COL_TEXT_WHITE: Color = Color(0.94, 0.95, 0.98, 1.0)
const COL_WEIGHT_LIGHT: Color = Color(0.25, 0.88, 0.45, 1.0)
const COL_WEIGHT_MED: Color = Color(0.95, 0.78, 0.20, 1.0)
const COL_WEIGHT_HEAVY: Color = Color(0.95, 0.28, 0.28, 1.0)

var hud_bag_btn: GameMenuButton
var btn_test_add: GameMenuButton

var weight_label: Label
var weight_status_badge: Label
var weight_bar_fill: ColorRect

var slot_list: InventorySlotList
var item_detail: InventoryItemDetail
var footer: InventoryFooter

var selected_slot_idx: int = 0
var equipped_item_id: String = ""

var _debug_item_cycle: Array[String] = [
	"kunci_bangsal_perunggu", "baterai_senter", "kunci_emas_kepala", "kunci_kutukan_mata", "peralatan_berat"
]
var _debug_idx: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	box_size = MODAL_SIZE
	# Modal berada di bawah tombol pause + tombol tes item
  # (ganti top_reserved yg aktif dengan ini, saat sistem item sudsh ada dan tombol tambah item dihapus).
  # top_reserved = PAUSE_BTN_BOTTOM + MODAL_GAP_BELOW_HUD
	top_reserved = PAUSE_BTN_BOTTOM + DEBUG_BTN_GAP + DEBUG_BTN_SIZE.y + MODAL_GAP_BELOW_HUD
	super._ready()
	
	_build_hud_bag_button()
	_build_floating_debug_button()

	var root_node = Engine.get_main_loop().root if Engine.get_main_loop() else null
	var inv_mgr = root_node.get_node_or_null("InventoryManager") if root_node else null
	if inv_mgr:
		inv_mgr.inventory_updated.connect(_refresh_ui)
		inv_mgr.hotbar_updated.connect(_refresh_ui)

	visible = false
	is_inventory_open = false

func _build_content() -> void:
	# 1. Header Atas
	var header_hbox := HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 10)
	header_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	content_container.add_child(header_hbox)

	var title_lbl := Label.new()
	title_lbl.text = "STREAMER BAG // EQUIPMENT"
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(title_lbl, 4, 13, COL_BORDER_GOLD)
	header_hbox.add_child(title_lbl)

	var weight_vbox := VBoxContainer.new()
	weight_vbox.add_theme_constant_override("separation", 2)
	header_hbox.add_child(weight_vbox)

	var weight_top_row := HBoxContainer.new()
	weight_top_row.add_theme_constant_override("separation", 6)
	weight_vbox.add_child(weight_top_row)

	weight_label = Label.new()
	weight_label.text = "BEBAN: 0.0 / 15.0 KG"
	_apply_font(weight_label, 3, 9, COL_TEXT_WHITE)
	weight_top_row.add_child(weight_label)

	weight_status_badge = Label.new()
	weight_status_badge.text = "[ RINGAN ]"
	_apply_font(weight_status_badge, 1, 8, COL_WEIGHT_LIGHT)
	weight_top_row.add_child(weight_status_badge)

	var bar_bg := ColorRect.new()
	bar_bg.custom_minimum_size = Vector2(130, 4)
	bar_bg.color = Color(0.12, 0.14, 0.20, 1.0)
	weight_vbox.add_child(bar_bg)

	weight_bar_fill = ColorRect.new()
	weight_bar_fill.size = Vector2(0, 4)
	weight_bar_fill.color = COL_WEIGHT_LIGHT
	bar_bg.add_child(weight_bar_fill)

	var divider_top := ColorRect.new()
	divider_top.custom_minimum_size = Vector2(0, 1)
	divider_top.color = COL_BORDER_SLATE
	content_container.add_child(divider_top)

	# 2. Body (Slot Kiri & Detail Kanan)
	var body_hbox := HBoxContainer.new()
	body_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_hbox.add_theme_constant_override("separation", 8)
	content_container.add_child(body_hbox)

	slot_list = InventorySlotList.new()
	slot_list.slot_selected.connect(_on_slot_selected)
	body_hbox.add_child(slot_list)

	item_detail = InventoryItemDetail.new()
	item_detail.action_requested.connect(_on_action_requested)
	body_hbox.add_child(item_detail)

	# 3. Footer Bawah (Hanya Hotbar + Tombol Tutup)
	var divider_bot := ColorRect.new()
	divider_bot.custom_minimum_size = Vector2(0, 1)
	divider_bot.color = COL_BORDER_SLATE
	content_container.add_child(divider_bot)

	footer = InventoryFooter.new()
	footer.hotbar_selected.connect(_on_hotbar_selected)
	footer.close_requested.connect(close)
	content_container.add_child(footer)

	if btn_close_x:
		btn_close_x.visible = false

# Tombol Debug (item dummy): tengah layar, tepat di bawah tombol pause
func _build_floating_debug_button() -> void:
	btn_test_add = GameMenuButton.new()
	btn_test_add.text = "+ TES ITEM"
	btn_test_add.set_dimensions(DEBUG_BTN_SIZE.x, DEBUG_BTN_SIZE.y)
	btn_test_add.font_size_override = 8
	btn_test_add.set_variant(GameMenuButton.Variant.ACCENT)
	btn_test_add.pressed.connect(_on_debug_add_item)
	add_child(btn_test_add)

	var top_y: float = PAUSE_BTN_BOTTOM + DEBUG_BTN_GAP
	btn_test_add.anchor_left = 0.5
	btn_test_add.anchor_right = 0.5
	btn_test_add.anchor_top = 0.0
	btn_test_add.anchor_bottom = 0.0
	btn_test_add.offset_left = -DEBUG_BTN_SIZE.x / 2.0
	btn_test_add.offset_right = DEBUG_BTN_SIZE.x / 2.0
	btn_test_add.offset_top = top_y
	btn_test_add.offset_bottom = top_y + DEBUG_BTN_SIZE.y
	# Kalau teks lebih lebar dari tombol, melebar ke dua sisi (tetap di tengah)
	btn_test_add.grow_horizontal = Control.GROW_DIRECTION_BOTH

func _build_hud_bag_button() -> void:
	hud_bag_btn = GameMenuButton.new()
	add_child(hud_bag_btn)
	hud_bag_btn.text = "[ TAS ]"
	hud_bag_btn.set_dimensions(58, 20)
	hud_bag_btn.font_size_override = 8
	hud_bag_btn.set_variant(GameMenuButton.Variant.DEFAULT)
	hud_bag_btn.position = Vector2(494, 8)
	hud_bag_btn.pressed.connect(func():
		if not DialogueBox.is_dialogue_open:
			open()
	)

func _unhandled_input(event: InputEvent) -> void:
	if DialogueBox.is_dialogue_open and not is_inventory_open:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB or event.keycode == KEY_I:
			if is_inventory_open:
				close()
			elif not get_tree().paused:
				open()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE and is_inventory_open:
			close()
			get_viewport().set_input_as_handled()

func open() -> void:
	if is_inventory_open: 
		return
	is_inventory_open = true
	get_tree().paused = true
	if hud_bag_btn:
		hud_bag_btn.visible = false
		
	item_detail.set_feedback("")
	_refresh_ui()
	open_modal()

func close() -> void:
	if not is_inventory_open: 
		return
	animator.animate_close(self, func():
		is_inventory_open = false
		if hud_bag_btn: 
			hud_bag_btn.visible = true
		if get_tree(): 
			get_tree().paused = false
		closed.emit()
	)

func _refresh_ui() -> void:
	var inv_mgr = _get_inv_mgr()
	if not inv_mgr: return

	if equipped_item_id != "" and inv_mgr.has_method("has_item_in_bag") and not inv_mgr.has_item_in_bag(equipped_item_id):
		equipped_item_id = ""

	var cur_w: float = inv_mgr.get("current_weight") if inv_mgr.get("current_weight") != null else 0.0
	var max_w: float = inv_mgr.get("MAX_WEIGHT") if inv_mgr.get("MAX_WEIGHT") != null else 15.0
	weight_label.text = "BEBAN: %.1f / %.1f KG" % [cur_w, max_w]

	var ratio: float = clampf(cur_w / max_w, 0.0, 1.0)
	weight_bar_fill.size.x = 130.0 * ratio

	var lvl: String = inv_mgr.get_encumbrance_level() if inv_mgr.has_method("get_encumbrance_level") else "LIGHT"
	var w_col: Color = COL_WEIGHT_LIGHT
	var w_txt: String = "[ RINGAN ]"
	if lvl == "HEAVY":
		w_col = COL_WEIGHT_HEAVY
		w_txt = "[ BERAT / LAMBAT ]"
	elif lvl == "MEDIUM":
		w_col = COL_WEIGHT_MED
		w_txt = "[ SEDANG ]"

	weight_bar_fill.color = w_col
	weight_status_badge.text = w_txt
	_apply_font(weight_status_badge, 1, 8, w_col)

	slot_list.refresh(inv_mgr, selected_slot_idx)
	item_detail.refresh(inv_mgr, selected_slot_idx, equipped_item_id)
	footer.refresh(inv_mgr, equipped_item_id)

func _on_slot_selected(idx: int) -> void:
	selected_slot_idx = idx
	item_detail.set_feedback("")
	_refresh_ui()

func _on_action_requested(action: String) -> void:
	var inv_mgr = _get_inv_mgr()
	if not inv_mgr: return

	match action:
		"use":
			if inv_mgr.has_method("use_item_at_slot"):
				item_detail.set_feedback(inv_mgr.use_item_at_slot(selected_slot_idx))
		"equip":
			var slot: Dictionary = inv_mgr.inventory[selected_slot_idx]
			if slot.has("id"):
				var id_str: String = slot["id"]
				if equipped_item_id == id_str:
					equipped_item_id = ""
					item_detail.set_feedback("Barang disimpan kembali.")
				else:
					equipped_item_id = id_str
					item_detail.set_feedback("Barang digenggam di tangan.")
		"hotbar":
			if inv_mgr.has_method("assign_to_hotbar"):
				item_detail.set_feedback(inv_mgr.assign_to_hotbar(selected_slot_idx))
		"drop":
			if inv_mgr.has_method("remove_item_at_slot") and inv_mgr.remove_item_at_slot(selected_slot_idx, 1):
				item_detail.set_feedback("Barang telah dibuang.")
	_refresh_ui()

func _on_hotbar_selected(hb_idx: int) -> void:
	var inv_mgr = _get_inv_mgr()
	if not inv_mgr or not inv_mgr.get("hotbar") or not inv_mgr.get("inventory"): return
	
	if hb_idx < inv_mgr.hotbar.size() and inv_mgr.hotbar[hb_idx].has("id"):
		var target_id: String = inv_mgr.hotbar[hb_idx]["id"]
		for i in range(inv_mgr.inventory.size()):
			if inv_mgr.inventory[i].has("id") and inv_mgr.inventory[i]["id"] == target_id:
				selected_slot_idx = i
				item_detail.set_feedback("")
				_refresh_ui()
				return

func _on_debug_add_item() -> void:
	var inv_mgr = _get_inv_mgr()
	if not inv_mgr or not inv_mgr.has_method("add_item"): return
	
	var item_id: String = _debug_item_cycle[_debug_idx % _debug_item_cycle.size()]
	_debug_idx += 1
	if inv_mgr.add_item(item_id, 1):
		var meta: Dictionary = inv_mgr.get_item_meta(item_id) if inv_mgr.has_method("get_item_meta") else {}
		item_detail.set_feedback("+ Diambil: " + meta.get("name", item_id))
	else:
		item_detail.set_feedback("Gagal: Tas penuh!")
	_refresh_ui()

func _get_inv_mgr() -> Node:
	var root_node = Engine.get_main_loop().root if Engine.get_main_loop() else null
	return root_node.get_node_or_null("InventoryManager") if root_node else null

func _apply_font(lbl: Control, type: int, f_size: int, col: Color) -> void:
	var root_node = Engine.get_main_loop().root if Engine.get_main_loop() else null
	var font_mgr = root_node.get_node_or_null("FontManager") if root_node else null
	if font_mgr and font_mgr.has_method("apply"):
		font_mgr.apply(lbl, type, f_size, col)
	else:
		lbl.add_theme_font_size_override("font_size", f_size)
		lbl.add_theme_color_override("font_color", col)
