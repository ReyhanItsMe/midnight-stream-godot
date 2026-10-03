class_name HotbarContainer
extends HBoxContainer

var hotbar_slots_ui: Array[PanelContainer] = []
var btn_bag: GameMenuButton

func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	offset_right = -12
	offset_top = 10
	alignment = BoxContainer.ALIGNMENT_END
	add_theme_constant_override("separation", 8)
	
	var hotbar_hbox := HBoxContainer.new()
	hotbar_hbox.add_theme_constant_override("separation", 4)
	add_child(hotbar_hbox)
	
	for i in range(3):
		var box := PanelContainer.new()
		box.custom_minimum_size = Vector2(26, 26)
		var st := StyleBoxFlat.new()
		st.bg_color = Palette.BLACK_MODAL
		st.set_border_width_all(1)
		st.border_color = Palette.SLATE
		box.add_theme_stylebox_override("panel", st)
		
		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		box.add_child(icon)
		
		hotbar_hbox.add_child(box)
		hotbar_slots_ui.append(box)
	
	btn_bag = GameMenuButton.new()
	add_child(btn_bag)
	btn_bag.text = "[ TAS ]"
	btn_bag.set_dimensions(54, 26)
	btn_bag.set_variant(GameMenuButton.Variant.DEFAULT)
	btn_bag.pressed.connect(func():
		var diag = HUD.instance.dialogue_box if HUD.instance else null
		var inv = HUD.instance.inventory_modal if HUD.instance else null
		if inv and not (diag and diag.is_active):
			if inv.has_method("open"): inv.open()
	)
	
	var inv_mgr: Node = get_node_or_null("/root/InventoryManager")
	if inv_mgr:
		inv_mgr.hotbar_updated.connect(_refresh_hotbar)
		_refresh_hotbar()

func _refresh_hotbar() -> void:
	var inv_mgr: Node = get_node_or_null("/root/InventoryManager")
	if not inv_mgr: return
	
	for i in range(hotbar_slots_ui.size()):
		var box: PanelContainer = hotbar_slots_ui[i]
		var icon: TextureRect = box.get_node("Icon")
		
		if i < inv_mgr.hotbar.size() and inv_mgr.hotbar[i].has("id"):
			var item_id: String = inv_mgr.hotbar[i]["id"]
			var meta: Dictionary = inv_mgr.get_item_meta(item_id)
			var path: String = meta.get("icon_path", "")
			if path != "" and ResourceLoader.exists(path):
				icon.texture = load(path)
			else:
				icon.texture = null
			box.get_theme_stylebox("panel").border_color = Palette.GOLD
		else:
			icon.texture = null
			box.get_theme_stylebox("panel").border_color = Palette.SLATE
