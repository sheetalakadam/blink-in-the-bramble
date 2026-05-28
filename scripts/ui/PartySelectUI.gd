extends CanvasLayer

## Party selection screen shown before combat.
## Lets the player choose exactly 3 companions (Vyn is always auto-included).

signal party_selected(selected: Array[String])
signal cancelled

const VYN_PATH: String = "res://data/characters/vyn.tres"
const MAX_SELECTABLE: int = 3

var _available_paths: Array[String] = []
var _selected_paths: Array[String] = []
var _card_buttons: Array[Button] = []

@onready var title_label: Label = $Panel/VBox/Title
@onready var cards_container: VBoxContainer = $Panel/VBox/Cards
@onready var vyn_label: Label = $Panel/VBox/VynStatus
@onready var confirm_btn: Button = $Panel/VBox/Buttons/Confirm
@onready var cancel_btn: Button = $Panel/VBox/Buttons/Cancel


func _ready() -> void:
	confirm_btn.pressed.connect(_on_confirm)
	cancel_btn.pressed.connect(_on_cancel)
	confirm_btn.disabled = true
	visible = false


func show_selection(available_paths: Array[String]) -> void:
	_available_paths = available_paths.duplicate()
	_selected_paths.clear()
	_card_buttons.clear()

	# Remove old cards
	for child in cards_container.get_children():
		child.queue_free()

	# We need to wait a frame for queue_free to take effect
	await get_tree().process_frame

	# Build a card for each available (non-Vyn) character
	for path in _available_paths:
		if path == VYN_PATH:
			continue
		var char_data = load(path) as CharacterData
		if char_data == null:
			continue
		var btn = _create_card(char_data, path)
		cards_container.add_child(btn)
		_card_buttons.append(btn)

	vyn_label.text = "Vyn (always in party)"
	confirm_btn.disabled = true
	visible = true
	get_tree().paused = true


func _create_card(char_data: CharacterData, path: String) -> Button:
	var btn = Button.new()
	var stance_text = char_data.stances[0] if char_data.stances.size() > 0 else "None"
	var role_line = char_data.bio.substr(0, 60) + "..." if char_data.bio.length() > 60 else char_data.bio
	btn.text = "%s  |  HP: %d  |  Stance: %s\n%s" % [char_data.name, char_data.max_hp, stance_text, role_line]
	btn.set_meta("char_path", path)
	btn.set_meta("char_name", char_data.name)
	btn.toggle_mode = true
	btn.toggled.connect(_on_card_toggled.bind(path, btn))
	btn.custom_minimum_size = Vector2(400, 50)
	return btn


func _on_card_toggled(is_pressed: bool, path: String, btn: Button) -> void:
	if is_pressed:
		if _selected_paths.size() >= MAX_SELECTABLE:
			# Already at max — reject this toggle
			btn.set_pressed_no_signal(false)
			return
		if path not in _selected_paths:
			_selected_paths.append(path)
	else:
		_selected_paths.erase(path)

	_update_confirm_state()


func _update_confirm_state() -> void:
	confirm_btn.disabled = _selected_paths.size() != MAX_SELECTABLE


func _on_confirm() -> void:
	if _selected_paths.size() != MAX_SELECTABLE:
		return
	visible = false
	get_tree().paused = false
	var result: Array[String] = []
	for p in _selected_paths:
		result.append(p)
	party_selected.emit(result)


func _on_cancel() -> void:
	_selected_paths.clear()
	visible = false
	get_tree().paused = false
	cancelled.emit()


## Returns currently selected paths (for testing).
func get_selected() -> Array[String]:
	return _selected_paths


## Returns whether confirm is enabled (for testing).
func is_confirm_enabled() -> bool:
	return not confirm_btn.disabled
