class_name InteractionPrompt
extends Control

var prompt_container: PanelContainer
var lbl_prompt: Label
var btn_talk_prompt: GameMenuButton
var current_talk_callable: Callable

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	_build_interaction_prompt()
	_build_talk_prompt()

func _process(_delta: float) -> void:
	if InteractionManager and InteractionManager.active_interactable != null:
		var target: Node2D = InteractionManager.active_interactable
		var target_name: String = "INTERACT"
		
		if "station_name" in target: target_name = target.station_name
		elif "door_name" in target: target_name = target.door_name
		
		show_prompt("PRESS [E] // " + target_name)
	else:
		hide_prompt()

func _build_interaction_prompt() -> void:
	prompt_container = PanelContainer.new()
	prompt_container.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	prompt_container.offset_top = -48
	prompt_container.offset_bottom = -30
	prompt_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	prompt_container.visible = false
	
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.BLACK_MODAL
	style.set_border_width_all(1)
	style.border_color = Palette.GOLD
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	prompt_container.add_theme_stylebox_override("panel", style)
	add_child(prompt_container)
	
	lbl_prompt = Label.new()
	lbl_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontManager.apply(lbl_prompt, FontManager.Type.BODY_BOLD, 10, Palette.GOLD)
	prompt_container.add_child(lbl_prompt)

func _build_talk_prompt() -> void:
	btn_talk_prompt = GameMenuButton.new()
	add_child(btn_talk_prompt)
	
	btn_talk_prompt.text = "[ E ] AJAK BICARA"
	btn_talk_prompt.set_dimensions(136, 24)
	btn_talk_prompt.set_variant(GameMenuButton.Variant.ACCENT)
	btn_talk_prompt.position = Vector2((640 - 136) / 2.0, 295)
	btn_talk_prompt.visible = false
	btn_talk_prompt.modulate.a = 0.0
	btn_talk_prompt.pressed.connect(func():
		if current_talk_callable.is_valid():
			current_talk_callable.call()
	)

func show_prompt(text_msg: String) -> void:
	lbl_prompt.text = text_msg
	prompt_container.visible = true

func hide_prompt() -> void:
	prompt_container.visible = false

func set_talk_prompt_visible(show_btn: bool, callable: Callable = Callable()) -> void:
	if not btn_talk_prompt: return
	
	var diag = HUD.instance.dialogue_box if HUD.instance else null
	if show_btn and (not diag or not diag.is_active):
		current_talk_callable = callable
		btn_talk_prompt.visible = true
		var tw := create_tween()
		tw.tween_property(btn_talk_prompt, "modulate:a", 1.0, 0.15)
	else:
		var tw := create_tween()
		tw.tween_property(btn_talk_prompt, "modulate:a", 0.0, 0.12)
		tw.tween_callback(func(): btn_talk_prompt.visible = false)
