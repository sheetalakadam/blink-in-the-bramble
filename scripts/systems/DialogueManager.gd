extends Node

signal dialogue_started(id: String)
signal dialogue_ended
signal line_presented(line_data: Dictionary)

var current_dialogue: Dictionary = {}
var current_node_id: String = ""
var current_line_index: int = 0
var is_active: bool = false

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
	current_node_id = current_dialogue.get("start_node", "")
	current_line_index = 0
	print("[DialogueManager] Dialogue loaded, emitting started signal")
	dialogue_started.emit(dialogue_id)
	_present_current_line()

func advance_dialogue() -> void:
	if not is_active:
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

func _handle_node_completion(node: Dictionary) -> void:
	var next_node = node.get("next_node")
	if next_node and next_node in current_dialogue["nodes"]:
		current_node_id = next_node
		current_line_index = 0
		_present_current_line()
	else:
		is_active = false
		dialogue_ended.emit()

# Convenience for player input
func _input(event: InputEvent) -> void:
	if is_active and event.is_action_pressed("ui_accept"):
		advance_dialogue()
