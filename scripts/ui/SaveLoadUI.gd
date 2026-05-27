extends CanvasLayer

## Player-facing save/load menu with 3 save slots.

signal save_completed(slot: int)
signal load_completed(slot: int)

enum Mode { SAVE, LOAD }

var _current_mode: Mode = Mode.SAVE

@onready var title_label: Label = $Panel/Title
@onready var slot_container: VBoxContainer = $Panel/Slots
@onready var close_button: Button = $Panel/CloseButton


func _ready() -> void:
	visible = false
	close_button.pressed.connect(close)


func open(mode: Mode) -> void:
	_current_mode = mode
	title_label.text = "Save Game" if mode == Mode.SAVE else "Load Game"
	_refresh_slots()
	visible = true
	get_tree().paused = true


func close() -> void:
	visible = false
	get_tree().paused = false


func _refresh_slots() -> void:
	for child in slot_container.get_children():
		child.queue_free()

	for i in range(1, 4):
		var btn = Button.new()
		var save_path = "user://save_slot_%d.res" % i
		if FileAccess.file_exists(save_path):
			var data = ResourceLoader.load(save_path) as SaveData
			if data:
				btn.text = "Slot %d — Lv.%d — %s" % [i, data.party_level, data.timestamp]
			else:
				btn.text = "Slot %d — Corrupted" % i
		else:
			btn.text = "Slot %d — Empty —" % i

		btn.pressed.connect(_on_slot_pressed.bind(i))
		slot_container.add_child(btn)


func _on_slot_pressed(slot: int) -> void:
	if _current_mode == Mode.SAVE:
		SaveManager.save_game(slot)
		save_completed.emit(slot)
		_show_message("Saved to slot %d!" % slot)
		_refresh_slots()
	else:
		var data = SaveManager.load_game(slot)
		if data:
			load_completed.emit(slot)
			close()
		else:
			_show_message("No save in slot %d" % slot)


func _show_message(text: String) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(40, 180)
	$Panel.add_child(lbl)
	await get_tree().create_timer(1.5).timeout
	if is_instance_valid(lbl):
		lbl.queue_free()
