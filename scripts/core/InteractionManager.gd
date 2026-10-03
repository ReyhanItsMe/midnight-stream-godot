## Manager pusat untuk mendeteksi dan mengeksekusi objek interaktif di dekat pemain.
##
## Cara pakai pada objek dunia (Pintu / Kunci / NPC):
##   # Saat player masuk Area2D:
##   InteractionManager.register_interactable(self)
##   # Saat player keluar Area2D:
##   InteractionManager.unregister_interactable(self)
##   # Objek wajib memiliki fungsi:
##   func interact() -> void:
##       print("Objek disentuh!")
class_name InteractionManagerClass
extends Node

signal interact_pressed

## Objek yang saat ini menjadi target utama interaksi (terdekat)
var active_interactable: Node2D = null

## Daftar semua objek yang sedang berada dalam jangkauan deteksi pemain
var _nearby_interactables: Array[Node2D] = []

## Mendaftarkan objek interaktif saat bersentuhan dengan area deteksi
func register_interactable(interactable: Node2D) -> void:
	if not _nearby_interactables.has(interactable):
		_nearby_interactables.append(interactable)
		_update_active_interactable()

## Menghapus objek saat pemain melangkah menjauh
func unregister_interactable(interactable: Node2D) -> void:
	_nearby_interactables.erase(interactable)
	if active_interactable == interactable:
		active_interactable = null
		_update_active_interactable()

## Mengevaluasi objek mana yang paling valid untuk diajak interaksi
func _update_active_interactable() -> void:
	# Bersihkan objek yang mungkin sudah terhapus dari memory (queue_free)
	_nearby_interactables = _nearby_interactables.filter(func(item): return is_instance_valid(item))
	
	if _nearby_interactables.is_empty():
		active_interactable = null
	else:
		# Objek paling akhir didaftarkan menjadi target aktif prioritas
		active_interactable = _nearby_interactables.back()

func _unhandled_input(event: InputEvent) -> void:
	var triggered: bool = false

	# Periksa action jika action "interact" sudah terdaftar di Project Settings
	if InputMap.has_action("interact"):
		if event.is_action_pressed("interact"):
			triggered = true

	# Fallback tombol fisik 'E' keyboard
	if not triggered and event is InputEventKey:
		if event.pressed and not event.echo and event.keycode == KEY_E:
			triggered = true

	if triggered and is_instance_valid(active_interactable):
		get_viewport().set_input_as_handled()
		trigger_interact()

## Dieksekusi via tombol keyboard atau tombol layar sentuh [E] di VirtualControls
func trigger_interact() -> void:
	if is_instance_valid(active_interactable) and active_interactable.has_method("interact"):
		active_interactable.interact()
		interact_pressed.emit()
