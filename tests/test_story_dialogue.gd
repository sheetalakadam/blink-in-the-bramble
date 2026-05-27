extends Node2D

## Tests for story dialogue files — structure, navigation, and content.

const TAG = "[TEST_STORY]"
var _passed: int = 0
var _failed: int = 0

const DIALOGUE_FILES = [
	"res://data/dialogue/scene_01_the_fall.json",
	"res://data/dialogue/scene_02_first_steps.json",
	"res://data/dialogue/scene_03_valdrihn_gate.json",
	"res://data/dialogue/scene_04_ereivyn_threshold.json",
	"res://data/dialogue/camp_caelan_01.json",
	"res://data/dialogue/camp_caelan_02.json",
]

const VALID_SPEAKERS = ["Zi", "Caelan", "Guard", "Narrator"]

func _ready() -> void:
	print("%s Starting story dialogue tests..." % TAG)
	for path in DIALOGUE_FILES:
		_test_file_loads(path)
		_test_chain_navigable(path)
		_test_speakers_valid(path)
	_test_branching_scenes()
	_test_monologue_present()
	_report()

func _assert(condition: bool, name: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		printerr("%s FAIL: %s" % [TAG, name])

func _load_dialogue(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	return data if data != null else {}

func _test_file_loads(path: String) -> void:
	var fname = path.get_file()
	_assert(FileAccess.file_exists(path), "%s exists" % fname)
	var data = _load_dialogue(path)
	_assert(not data.is_empty(), "%s parses as JSON" % fname)
	_assert(data.get("start_node", "") != "", "%s has start_node" % fname)
	_assert(data.get("nodes", {}).has(data.get("start_node", "")), "%s start_node exists" % fname)

func _test_chain_navigable(path: String) -> void:
	var fname = path.get_file()
	var data = _load_dialogue(path)
	if data.is_empty():
		return
	var visited: Array[String] = []
	var current = data.get("start_node", "")
	while current != "" and current not in visited:
		visited.append(current)
		var node = data["nodes"].get(current, {})
		current = node.get("next_node", "")
		if current == null:
			current = ""
		# Also follow choice branches
		var choices = node.get("choices", [])
		for choice in choices:
			var cn = choice.get("next_node", "")
			if cn != "" and cn not in visited and data["nodes"].has(cn):
				visited.append(cn)
	_assert(visited.size() >= 3, "%s has >= 3 navigable nodes (has %d)" % [fname, visited.size()])

func _test_speakers_valid(path: String) -> void:
	var fname = path.get_file()
	var data = _load_dialogue(path)
	if data.is_empty():
		return
	for node_id in data.get("nodes", {}):
		var node = data["nodes"][node_id]
		for line in node.get("lines", []):
			var speaker = line.get("speaker", "")
			_assert(speaker != "", "%s node '%s' has speaker" % [fname, node_id])

func _test_branching_scenes() -> void:
	var data = _load_dialogue("res://data/dialogue/scene_03_valdrihn_gate.json")
	if data.is_empty():
		return
	var choice_node = data["nodes"].get("choice", {})
	var choices = choice_node.get("choices", [])
	_assert(choices.size() == 2, "Valdrihn gate has 2 choices")
	for choice in choices:
		var next = choice.get("next_node", "")
		_assert(data["nodes"].has(next), "Choice leads to valid node: %s" % next)

func _test_monologue_present() -> void:
	# scene_02 should have monologue in first node
	var data = _load_dialogue("res://data/dialogue/scene_02_first_steps.json")
	if data.is_empty():
		return
	var first_node = data["nodes"].get(data["start_node"], {})
	var has_mono = false
	for line in first_node.get("lines", []):
		if line.has("monologue"):
			has_mono = true
			break
	_assert(has_mono, "scene_02 first node has monologue")

func _report() -> void:
	print("%s Results: %d passed, %d failed" % [TAG, _passed, _failed])
	if _failed == 0:
		print("%s SUCCESS" % TAG)
	else:
		printerr("%s FAILED" % TAG)
	if DisplayServer.get_name() == "headless":
		get_tree().quit()
