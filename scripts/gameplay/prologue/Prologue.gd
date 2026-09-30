extends Node2D

const TILE_SIZE: int = 32
const COLOR_TILE_A: Color = Color(0.22, 0.24, 0.30)
const COLOR_TILE_B: Color = Color(0.16, 0.18, 0.24)
const COLOR_TILE_BORDER: Color = Color(0.12, 0.13, 0.18)

const DOOR_SCENE_PATH: String = "res://scenes/entities/interactables/Door.tscn"
const MYSTERY_SPRITE_PATH: String = "res://assets/sprites/characters/mistery/misterius_sprite.png"

@onready var player: Player = $Player
@onready var camera: Camera2D = $Camera2D
@onready var floor_rect: TextureRect = $GridFloor/FloorTiles
@onready var save_point: SavePoint = $SavePoint
@onready var save_modal: SaveModal = $UILayer/SaveModal

var dialogue_box: DialogueBox
var pause_modal: PauseModal
var btn_talk_prompt: GameMenuButton
var is_near_mystery_npc: bool = false

func _ready() -> void:
	AudioManager.stop_bgm(0.4)
	_generate_checkerboard_floor()
	_create_visual_walls()
	_setup_horizontal_darkness_gradient()
	_create_darkness_markers()
	_create_test_doors()
	_spawn_mystery_npc(Vector2(-60, -10))

	# 1. Pasang Tombol Prompt Interaksi Bicara (Layer UI Dasar)
	_create_talk_prompt_button()

	# 2. Pasang Dialogue Box (Z-Index 5 agar di atas tombol prompt dunia)
	dialogue_box = DialogueBox.new()
	dialogue_box.name = "DialogueBox"
	dialogue_box.z_index = 5
	dialogue_box.dialogue_finished.connect(_on_dialogue_finished)
	$UILayer.add_child(dialogue_box)

	# 3. Pasang Pause Modal (Z-Index 10 agar tombol || PAUSE selalu bisa ditekan di atas blocker dialog)
	pause_modal = PauseModal.new()
	pause_modal.name = "PauseModal"
	pause_modal.z_index = 10
	$UILayer.add_child(pause_modal)

	if player:
		player.global_position = Vector2(-180, -20)
		camera.global_position = player.global_position

	if save_point and save_modal:
		save_point.save_station_triggered.connect(save_modal.open)


func _process(_delta: float) -> void:
	if player and camera:
		camera.global_position = player.global_position


func _unhandled_input(event: InputEvent) -> void:
	if is_near_mystery_npc and dialogue_box and not dialogue_box.is_active:
		if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
			_start_mystery_conversation()
			get_viewport().set_input_as_handled()


# ==============================================================================
# NPC MISTERIUS & TOMBOL PEMICU DIALOG
# ==============================================================================

func _spawn_mystery_npc(spawn_pos: Vector2) -> void:
	var npc_area := Area2D.new()
	npc_area.name = "MysteryNPC"
	npc_area.position = spawn_pos
	npc_area.collision_layer = 3
	npc_area.collision_mask = 3
	add_child(npc_area)

	var spr := Sprite2D.new()
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if ResourceLoader.exists(MYSTERY_SPRITE_PATH):
		spr.texture = load(MYSTERY_SPRITE_PATH)
	npc_area.add_child(spr)

	var static_body := StaticBody2D.new()
	var body_col := CollisionShape2D.new()
	var body_rect := RectangleShape2D.new()
	body_rect.size = Vector2(20, 24)
	body_col.shape = body_rect
	static_body.add_child(body_col)
	npc_area.add_child(static_body)

	var trigger_col := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 38.0
	trigger_col.shape = circle
	npc_area.add_child(trigger_col)

	npc_area.body_entered.connect(func(body: Node2D):
		if body is Player:
			is_near_mystery_npc = true
			_set_talk_prompt_visible(true)
	)
	npc_area.body_exited.connect(func(body: Node2D):
		if body is Player:
			is_near_mystery_npc = false
			_set_talk_prompt_visible(false)
	)


func _create_talk_prompt_button() -> void:
	btn_talk_prompt = GameMenuButton.new()
	btn_talk_prompt.text = "[ E ] AJAK BICARA"
	btn_talk_prompt.set_dimensions(136, 24)
	btn_talk_prompt.font_size_override = 9
	btn_talk_prompt.set_variant(GameMenuButton.Variant.ACCENT)
	btn_talk_prompt.position = Vector2((640 - 136) / 2.0, 295)
	btn_talk_prompt.visible = false
	btn_talk_prompt.modulate.a = 0.0
	btn_talk_prompt.pressed.connect(_start_mystery_conversation)
	$UILayer.add_child(btn_talk_prompt)


func _set_talk_prompt_visible(show_btn: bool) -> void:
	if not btn_talk_prompt:
		return

	if show_btn and (not dialogue_box or not dialogue_box.is_active):
		btn_talk_prompt.visible = true
		var tw := create_tween()
		tw.tween_property(btn_talk_prompt, "modulate:a", 1.0, 0.15)
	else:
		var tw := create_tween()
		tw.tween_property(btn_talk_prompt, "modulate:a", 0.0, 0.12)
		tw.tween_callback(func(): btn_talk_prompt.visible = false)


func _start_mystery_conversation() -> void:
	if not dialogue_box or dialogue_box.is_active:
		return

	_set_talk_prompt_visible(false)

	dialogue_box.start_dialogue([
		{
			"speaker": "Rian",
			"side": "left",
			"expression": "cemas",
			"text": "Permisi?! Ada orang di sini? Sinyal live stream-ku mendadak putus sejak masuk ke lorong ini."
		},
		{
			"speaker": "Sosok Misterius",
			"side": "right",
			"expression": "biasa",
			"text": "Matikan kamera itu... Sesuatu di balik pintu ujung sedang mendengarkan langkah kakimu."
		},
		{
			"speaker": "Rian",
			"side": "left",
			"expression": "takut",
			"text": "A-apa maksudmu? Semua pintu di ruangan ini malah membawaku berputar-putar!"
		},
		{
			"speaker": "Sosok Misterius",
			"side": "right",
			"expression": "biasa",
			"text": "Simpan rekamanmu di terminal sebelum sentermu redup. Jangan percaya pada pintu yang mengintip."
		}
	])


func _on_dialogue_finished() -> void:
	if is_near_mystery_npc:
		_set_talk_prompt_visible(true)


# ==============================================================================
# ENVIRONMENT, DINDING, GRADASI CAHAYA & PINTU
# ==============================================================================

func _create_visual_walls() -> void:
	var wall_container := Node2D.new()
	wall_container.name = "VisualWalls"
	wall_container.z_index = 2
	add_child(wall_container)

	var wall_top := ColorRect.new()
	wall_top.position = Vector2(-320, -180)
	wall_top.size = Vector2(640, 42)
	wall_top.color = Color(0.08, 0.09, 0.13, 1.0)
	wall_container.add_child(wall_top)

	var skirting_top := ColorRect.new()
	skirting_top.position = Vector2(-320, -138)
	skirting_top.size = Vector2(640, 4)
	skirting_top.color = Color(0.18, 0.20, 0.28, 1.0)
	wall_container.add_child(skirting_top)


func _setup_horizontal_darkness_gradient() -> void:
	var ambient_light := PointLight2D.new()
	ambient_light.name = "AmbientGradientLight"
	ambient_light.position = Vector2(0, 0)
	ambient_light.energy = 1.0
	ambient_light.shadow_enabled = false

	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.35, 0.65, 0.85, 1.0])
	grad.colors = PackedColorArray([
		Color(0.65, 0.70, 0.85, 1.0),
		Color(0.35, 0.40, 0.50, 1.0),
		Color(0.12, 0.14, 0.20, 1.0),
		Color(0.03, 0.03, 0.05, 1.0),
		Color(0.00, 0.00, 0.00, 1.0)
	])

	var grad_tex := GradientTexture2D.new()
	grad_tex.gradient = grad
	grad_tex.width = 640
	grad_tex.height = 360
	grad_tex.fill = GradientTexture2D.FILL_LINEAR
	grad_tex.fill_from = Vector2(0.0, 0.5)
	grad_tex.fill_to = Vector2(1.0, 0.5)

	ambient_light.texture = grad_tex
	add_child(ambient_light)


func _create_darkness_markers() -> void:
	var markers: Array[Dictionary] = [
		{"pos": Vector2(-220, 90), "col": Color(0.2, 0.85, 0.3),  "label": "TERANG (100%)"},
		{"pos": Vector2(-110, 90), "col": Color(0.9, 0.85, 0.2),  "label": "SEDANG (60%)"},
		{"pos": Vector2(0, 90),    "col": Color(0.95, 0.5, 0.1),  "label": "REMANG (30%)"},
		{"pos": Vector2(120, 90),  "col": Color(0.9, 0.2, 0.2),   "label": "GELAP (10%)"},
		{"pos": Vector2(240, 90),  "col": Color(0.6, 0.1, 0.9),   "label": "GELAP TOTAL (0%)"}
	]

	var marker_container := Node2D.new()
	marker_container.name = "DarknessMarkers"
	add_child(marker_container)

	var font_mgr: Node = get_node_or_null("/root/FontManager")

	for m in markers:
		var box := ColorRect.new()
		box.size = Vector2(18, 48)
		box.position = m["pos"] - Vector2(9, 24)
		box.color = m["col"]
		marker_container.add_child(box)

		var lbl := Label.new()
		lbl.text = m["label"]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.position = m["pos"] + Vector2(-60, 28)
		lbl.size = Vector2(120, 20)

		if font_mgr and font_mgr.has_method("apply"):
			font_mgr.apply(lbl, font_mgr.Type.DIGITAL, 9, m["col"])
		else:
			lbl.add_theme_font_size_override("font_size", 9)
			lbl.add_theme_color_override("font_color", m["col"])

		marker_container.add_child(lbl)


func _create_test_doors() -> void:
	if not ResourceLoader.exists(DOOR_SCENE_PATH):
		push_warning("[Prologue] Scene Door tidak ditemukan di: " + DOOR_SCENE_PATH)
		return

	var door_packed: PackedScene = load(DOOR_SCENE_PATH)
	var door_container := Node2D.new()
	door_container.name = "TestDoors"
	door_container.z_index = 3
	add_child(door_container)

	var doors_data: Array[Dictionary] = [
		{
			"pos": Vector2(-180, -130),
			"type": Door.DoorType.KAYU_1DAUN,
			"name": "1. PINTU KAYU (TERANG)",
			"tp_pos": Vector2(-40, -30),
			"spawn_dir": "depan"
		},
		{
			"pos": Vector2(-40, -130),
			"type": Door.DoorType.BESI_GANDA,
			"name": "2. PINTU BESI GANDA (REMANG)",
			"tp_pos": Vector2(100, -30),
			"spawn_dir": "depan"
		},
		{
			"pos": Vector2(100, -130),
			"type": Door.DoorType.RUMAH_SAKIT_1DAUN,
			"name": "3. PINTU RUMAH SAKIT (GELAP)",
			"tp_pos": Vector2(230, -30),
			"spawn_dir": "depan"
		},
		{
			"pos": Vector2(230, -130),
			"type": Door.DoorType.TERBUKA_MATA_1DAUN,
			"name": "4. PINTU HOROR MATA (GELAP TOTAL)",
			"tp_pos": Vector2(-180, -30),
			"spawn_dir": "depan"
		}
	]

	for data in doors_data:
		var door_inst: Door = door_packed.instantiate() as Door
		door_inst.position = data["pos"]
		door_inst.door_type = data["type"]
		door_inst.door_name = data["name"]
		door_inst.target_teleport_position = data["tp_pos"]
		door_inst.spawn_direction = data["spawn_dir"]
		door_inst.auto_teleport_on_touch = true
		door_inst.custom_scale = Vector2(1.2, 1.2)
		door_container.add_child(door_inst)


func _generate_checkerboard_floor() -> void:
	var pattern_size: int = TILE_SIZE * 2
	var img := Image.create(pattern_size, pattern_size, false, Image.FORMAT_RGBA8)

	for y in range(pattern_size):
		for x in range(pattern_size):
			var is_even_x: bool = (x / TILE_SIZE) % 2 == 0
			var is_even_y: bool = (y / TILE_SIZE) % 2 == 0
			var col: Color = COLOR_TILE_A if (is_even_x == is_even_y) else COLOR_TILE_B

			if x % TILE_SIZE == 0 or y % TILE_SIZE == 0:
				col = COLOR_TILE_BORDER

			img.set_pixel(x, y, col)

	var tex := ImageTexture.create_from_image(img)
	floor_rect.texture = tex
	floor_rect.stretch_mode = TextureRect.STRETCH_TILE
