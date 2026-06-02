extends Node

signal dialogue_started(id: String)
signal dialogue_ended
signal dialogue_completed(scene_id: String)
signal line_presented(line_data: Dictionary)
signal choices_presented(choices: Array)

var current_dialogue: Dictionary = {}
var current_dialogue_id: String = ""
var current_node_id: String = ""
var current_line_index: int = 0
var is_active: bool = false
var awaiting_choice: bool = false

func start_dialogue(dialogue_id: String) -> void:
	print("[DialogueManager] start_dialogue called with: ", dialogue_id)
	var path = "res://data/dialogue/%s.json" % dialogue_id
	if not FileAccess.file_exists(path):
		printerr("[DialogueManager] Dialogue file not found: ", path)
		return
		
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	current_dialogue = JSON.parse_string(content)
	
	if current_dialogue == null or current_dialogue.is_empty():
		printerr("[DialogueManager] Failed to parse dialogue JSON: ", path)
		return
		
	is_active = true
	current_dialogue_id = dialogue_id
	current_node_id = current_dialogue.get("start_node", "")
	current_line_index = 0
	print("[DialogueManager] Dialogue loaded, emitting started signal")
	dialogue_started.emit(dialogue_id)
	_present_current_line()

func advance_dialogue() -> void:
	if not is_active or awaiting_choice:
		return
		
	var node = current_dialogue["nodes"][current_node_id]
	current_line_index += 1
	
	if current_line_index >= node["lines"].size():
		_handle_node_completion(node)
	else:
		_present_current_line()

func _present_current_line() -> void:
	var node = current_dialogue["nodes"][current_node_id]
	var line_data = node["lines"][current_line_index]
	print("[DialogueManager] Presenting line: ", line_data.get("text", "NO TEXT"))
	line_presented.emit(line_data)

func select_choice(index: int) -> void:
	if not awaiting_choice:
		return
	var node = current_dialogue["nodes"][current_node_id]
	var choices = node.get("choices", [])
	if index < 0 or index >= choices.size():
		return
	awaiting_choice = false
	var choice = choices[index]
	var target = choice.get("next_node", choice.get("next", ""))
	if target and target in current_dialogue["nodes"]:
		current_node_id = target
		current_line_index = 0
		_present_current_line()
	else:
		_end_dialogue()

func _handle_node_completion(node: Dictionary) -> void:
	var choices = node.get("choices", [])
	if choices.size() > 0:
		awaiting_choice = true
		choices_presented.emit(choices)
		return
	var next_node = node.get("next_node")
	if next_node and next_node in current_dialogue["nodes"]:
		current_node_id = next_node
		current_line_index = 0
		_present_current_line()
	else:
		_end_dialogue()

func _end_dialogue() -> void:
	is_active = false
	awaiting_choice = false
	var completed_id := current_dialogue_id
	dialogue_completed.emit(completed_id)
	dialogue_ended.emit()

# Convenience for player input
func _input(event: InputEvent) -> void:
	if is_active and event.is_action_pressed("ui_accept"):
		# Check if DialogueUI is mid-typewriter; if so, skip instead of advancing
		var dialogue_ui = get_tree().get_first_node_in_group("dialogue_ui")
		if dialogue_ui and dialogue_ui.is_typewriting:
			dialogue_ui.skip_typewriter()
		else:
			advance_dialogue()
