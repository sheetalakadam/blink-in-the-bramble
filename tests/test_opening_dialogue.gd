extends Node

const TEST_PREFIX = "[TEST_OPENING_DIALOGUE]"
const DIALOGUE_PATH = "res://data/dialogue/scene_01_the_fall.json"

var failed := false

func _ready() -> void:
	_run_tests()

func _run_tests() -> void:
	# --- Test 1: File exists and parses ---
	if not FileAccess.file_exists(DIALOGUE_PATH):
		_fail("Dialogue file not found: %s" % DIALOGUE_PATH)
		_finish()
		return

	var file = FileAccess.open(DIALOGUE_PATH, FileAccess.READ)
	var content = file.get_as_text()
	var data = JSON.parse_string(content)

	if data == null:
		_fail("JSON parse returned null")
		_finish()
		return

	_pass("JSON parses correctly")

	# --- Test 2: Root structure ---
	if not data.has("id"):
		_fail("Missing 'id' field")
	else:
		_pass("Has 'id' field: %s" % data["id"])

	if not data.has("start_node"):
		_fail("Missing 'start_node' field")
	else:
		_pass("Has 'start_node' field: %s" % data["start_node"])

	if not data.has("nodes"):
		_fail("Missing 'nodes' field")
		_finish()
		return
	else:
		_pass("Has 'nodes' field")

	# --- Test 3: Start node exists in nodes ---
	var start_node = data["start_node"]
	if not data["nodes"].has(start_node):
		_fail("start_node '%s' not found in nodes" % start_node)
	else:
		_pass("start_node '%s' exists in nodes" % start_node)

	# --- Test 4: All next_node references are valid ---
	var nodes: Dictionary = data["nodes"]
	for node_id in nodes:
		var node = nodes[node_id]
		var next_node = node.get("next_node")
		if next_node != null and not nodes.has(next_node):
			_fail("Node '%s' references non-existent next_node '%s'" % [node_id, next_node])

		# Also check choice next_node references
		var choices = node.get("choices", [])
		for choice in choices:
			var choice_next = choice.get("next_node", "")
			if choice_next != "" and not nodes.has(choice_next):
				_fail("Choice in node '%s' references non-existent next_node '%s'" % [node_id, choice_next])

	_pass("All next_node references are valid")

	# --- Test 5: At least one choice exists ---
	var has_choice := false
	for node_id in nodes:
		var node = nodes[node_id]
		if node.has("choices") and node["choices"].size() > 0:
			has_choice = true
			break

	if not has_choice:
		_fail("No choices found in dialogue")
	else:
		_pass("At least one choice exists")

	# --- Test 6: Monologue fields present on Zi's lines ---
	var zi_lines_total := 0
	var zi_lines_with_monologue := 0
	for node_id in nodes:
		var node = nodes[node_id]
		for line in node["lines"]:
			if line.get("speaker", "") == "Zi":
				zi_lines_total += 1
				if line.has("monologue") and line["monologue"] != "":
					zi_lines_with_monologue += 1

	if zi_lines_total == 0:
		_fail("No lines from speaker 'Zi' found")
	elif zi_lines_with_monologue == 0:
		_fail("Zi has %d lines but none have monologue" % zi_lines_total)
	else:
		_pass("Zi has %d/%d lines with monologue" % [zi_lines_with_monologue, zi_lines_total])

	# --- Test 7: All lines have required fields ---
	for node_id in nodes:
		var node = nodes[node_id]
		for i in range(node["lines"].size()):
			var line = node["lines"][i]
			if not line.has("speaker"):
				_fail("Node '%s', line %d missing 'speaker'" % [node_id, i])
			if not line.has("text"):
				_fail("Node '%s', line %d missing 'text'" % [node_id, i])
			if not line.has("portrait"):
				_fail("Node '%s', line %d missing 'portrait'" % [node_id, i])

	_pass("All lines have required fields (speaker, text, portrait)")

	# --- Test 8: Line count in range ---
	var total_lines := 0
	for node_id in nodes:
		total_lines += nodes[node_id]["lines"].size()

	if total_lines < 15:
		_fail("Total lines (%d) is below minimum of 15" % total_lines)
	elif total_lines > 35:
		_fail("Total lines (%d) exceeds reasonable maximum of 35" % total_lines)
	else:
		_pass("Total line count: %d (within expected range)" % total_lines)

	_finish()

func _pass(msg: String) -> void:
	print("%s PASS: %s" % [TEST_PREFIX, msg])

func _fail(msg: String) -> void:
	failed = true
	print("%s FAIL: %s" % [TEST_PREFIX, msg])

func _finish() -> void:
	if failed:
		print("%s FAILED" % TEST_PREFIX)
	else:
		print("%s SUCCESS" % TEST_PREFIX)
