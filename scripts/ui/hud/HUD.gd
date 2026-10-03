class_name HUD
extends CanvasLayer

static var instance: HUD

# Referensi ke parts
var sanity_bar: Control
var stamina_bar: ProgressBar
var prompt_ui: Control
var hotbar_ui: Container
var virtual_controls: Control

# Modals
var pause_modal: PauseModal
var inventory_modal: InventoryModal
var dialogue_box: DialogueBox

func _enter_tree() -> void:
	instance = self

func _ready() -> void:
	layer = 10 # HUD_LAYER_INDEX
	
	# 1. Merakit UI Parts langsung via class_name
	virtual_controls = VirtualControls.new()
	add_child(virtual_controls)
	
	sanity_bar = SanityBar.new()
	add_child(sanity_bar)
	
	stamina_bar = StaminaBar.new()
	add_child(stamina_bar)
	
	prompt_ui = InteractionPrompt.new()
	add_child(prompt_ui)
	
	hotbar_ui = HotbarContainer.new()
	add_child(hotbar_ui)
	
	# 2. Inisialisasi Modals
	_init_modals()

func _init_modals() -> void:
	dialogue_box = DialogueBox.new()
	dialogue_box.name = "DialogueBox"
	dialogue_box.z_index = 5
	add_child(dialogue_box)

	inventory_modal = InventoryModal.new()
	inventory_modal.name = "InventoryModal"
	inventory_modal.z_index = 9
	add_child(inventory_modal)
	
	# Menyambungkan tombol HUD Tas dengan Modal Inventory
	if inventory_modal.get("hud_bag_btn") != null:
		inventory_modal.hud_bag_btn.queue_free()
		inventory_modal.hud_bag_btn = hotbar_ui.btn_bag

	pause_modal = PauseModal.new()
	pause_modal.name = "PauseModal"
	pause_modal.z_index = 10
	add_child(pause_modal)

# Proxy fungsi global agar kode game lama tidak rusak
func start_dialogue(lines: Array[Dictionary], callback: Callable = Callable()) -> void:
	if dialogue_box:
		prompt_ui.set_talk_prompt_visible(false)
		dialogue_box.start_dialogue(lines)
		if callback.is_valid():
			if not dialogue_box.dialogue_finished.is_connected(callback):
				dialogue_box.dialogue_finished.connect(callback, CONNECT_ONE_SHOT)

## Proxy helper untuk menampilkan atau menyembunyikan tombol ajak bicara [E]
func set_talk_prompt_visible(show_btn: bool, callable: Callable = Callable()) -> void:
	if prompt_ui and prompt_ui.has_method("set_talk_prompt_visible"):
		prompt_ui.set_talk_prompt_visible(show_btn, callable)
