extends Node2D

## Tests for the base camp system.
## Run with: godot --headless --path . tests/test_base_camp.tscn

const TAG = "[TEST_BASE_CAMP]"

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	print("%s Starting base camp tests..." % TAG)
	_test_quarters_detects_conversation_at_threshold()
	_test_quarters_no_conversation_below_threshold()
	_test_quarters_marks_conversation_seen()
	_test_sanctum_heals_party()
	_test_sanctum_heals_only_once_per_visit()
	_test_camp_dialogue_file_loads()
	_test_forge_placeholder()
	_test_reset_camp()
	_test_integration_camp_visit()
	_report()


func _assert(condition: bool, name: String) -> void:
	if condition:
		_passed += 1
		print("%s PASS: %s" % [TAG, name])
	else:
		_failed += 1
		printerr("%s FAIL: %s" % [TAG, name])


## --- Test 1: Quarters detects available conversation when affinity >= 25 ---
func _test_quarters_detects_conversation_at_threshold() -> void:
	AffinityManager.reset()
	GlobalFlags.reset()

	# Below threshold — no conversation
	var controller = _make_camp_controller()
	var available = controller.is_quarters_conversation_available()
	_assert(not available, "Quarters: no conversation when all affinity < 25")

	# Set Caelan to threshold
	AffinityManager.add_affinity("Caelan", 25)
	available = controller.is_quarters_conversation_available()
	_assert(available, "Quarters: conversation available when Caelan affinity = 25")

	controller.queue_free()
	AffinityManager.reset()
	GlobalFlags.reset()


## --- Test 2: Quarters no conversation below threshold ---
func _test_quarters_no_conversation_below_threshold() -> void:
	AffinityManager.reset()
	GlobalFlags.reset()

	AffinityManager.add_affinity("Caelan", 24)
	var controller = _make_camp_controller()
	var available = controller.is_quarters_conversation_available()
	_assert(not available, "Quarters: no conversation at affinity 24")

	controller.queue_free()
	AffinityManager.reset()
	GlobalFlags.reset()


## --- Test 3: Quarters marks conversation as seen via GlobalFlags ---
func _test_quarters_marks_conversation_seen() -> void:
	AffinityManager.reset()
	GlobalFlags.reset()

	AffinityManager.add_affinity("Caelan", 30)
	var controller = _make_camp_controller()

	_assert(controller.is_quarters_conversation_available(), "Quarters: conversation available before visit")

	# Mark as seen
	controller.mark_quarters_conversation_seen()

	_assert(not controller.is_quarters_conversation_available(), "Quarters: conversation unavailable after seen")
	_assert(GlobalFlags.get_flag("camp_conversation_seen_Caelan"), "GlobalFlags has camp_conversation_seen_Caelan")

	controller.queue_free()
	AffinityManager.reset()
	GlobalFlags.reset()


## --- Test 4: Sanctum heals party to full HP ---
func _test_sanctum_heals_party() -> void:
	PartyManager.reset()
	GlobalFlags.reset()

	# Add party members with reduced HP
	var zi = CharacterData.new()
	zi.name = "Zi"
	zi.max_hp = 100
	PartyManager.add_to_party(zi)

	var caelan = CharacterData.new()
	caelan.name = "Caelan"
	caelan.max_hp = 80
	PartyManager.add_to_party(caelan)

	# Simulate damage via the camp controller's tracking
	var controller = _make_camp_controller()
	controller._party_current_hp["Zi"] = 50
	controller._party_current_hp["Caelan"] = 30

	controller.use_sanctum()

	_assert(controller._party_current_hp["Zi"] == 100, "Sanctum: Zi healed to max_hp")
	_assert(controller._party_current_hp["Caelan"] == 80, "Sanctum: Caelan healed to max_hp")

	controller.queue_free()
	PartyManager.reset()
	GlobalFlags.reset()


## --- Test 5: Sanctum only heals once per visit ---
func _test_sanctum_heals_only_once_per_visit() -> void:
	PartyManager.reset()
	GlobalFlags.reset()

	var zi = CharacterData.new()
	zi.name = "Zi"
	zi.max_hp = 100
	PartyManager.add_to_party(zi)

	var controller = _make_camp_controller()
	controller._party_current_hp["Zi"] = 50

	var healed = controller.use_sanctum()
	_assert(healed, "Sanctum: first use heals")

	# Damage again
	controller._party_current_hp["Zi"] = 50

	var healed_again = controller.use_sanctum()
	_assert(not healed_again, "Sanctum: second use does NOT heal")
	_assert(controller._party_current_hp["Zi"] == 50, "Sanctum: HP unchanged on second use")

	controller.queue_free()
	PartyManager.reset()
	GlobalFlags.reset()


## --- Test 6: Camp dialogue file loads and parses ---
func _test_camp_dialogue_file_loads() -> void:
	var path = "res://data/dialogue/camp_caelan_01.json"
	if not FileAccess.file_exists(path):
		_assert(false, "Camp dialogue file exists at %s" % path)
		return

	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	var data = JSON.parse_string(content)

	_assert(data != null, "Camp dialogue JSON parses")
	_assert(data.has("id"), "Dialogue has id field")
	_assert(data.has("start_node"), "Dialogue has start_node")
	_assert(data.has("nodes"), "Dialogue has nodes")

	# Check that nodes have lines
	var start_node_key = data.get("start_node", "")
	_assert(data["nodes"].has(start_node_key), "Start node exists in nodes")

	var node = data["nodes"][start_node_key]
	_assert(node.has("lines"), "Start node has lines")
	_assert(node["lines"].size() >= 3, "Start node has at least 3 lines")

	# Check for monologue field
	var has_monologue = false
	for line in node["lines"]:
		if line.has("monologue") and line["monologue"] != "":
			has_monologue = true
			break
	_assert(has_monologue, "Dialogue has at least one monologue")


## --- Test 7: Forge shows placeholder ---
func _test_forge_placeholder() -> void:
	var controller = _make_camp_controller()
	var result = controller.get_forge_status()
	_assert(result == "coming_soon", "Forge: returns coming_soon status")
	controller.queue_free()


## --- Test 8: reset_camp resets sanctum healing ---
func _test_reset_camp() -> void:
	PartyManager.reset()
	GlobalFlags.reset()

	var zi = CharacterData.new()
	zi.name = "Zi"
	zi.max_hp = 100
	PartyManager.add_to_party(zi)

	var controller = _make_camp_controller()
	controller._party_current_hp["Zi"] = 50

	controller.use_sanctum()
	_assert(controller._sanctum_used, "Sanctum: used flag set")

	controller.reset_camp()
	_assert(not controller._sanctum_used, "Sanctum: used flag cleared after reset")

	# Can heal again after reset
	controller._party_current_hp["Zi"] = 50
	var healed = controller.use_sanctum()
	_assert(healed, "Sanctum: can heal again after reset_camp")

	controller.queue_free()
	PartyManager.reset()
	GlobalFlags.reset()


## --- Test 9: Integration — enter camp, visit sanctum, verify healing, visit quarters ---
func _test_integration_camp_visit() -> void:
	AffinityManager.reset()
	GlobalFlags.reset()
	PartyManager.reset()

	# Set up party
	var zi = CharacterData.new()
	zi.name = "Zi"
	zi.max_hp = 100
	PartyManager.add_to_party(zi)

	# Set affinity for quarters conversation
	AffinityManager.add_affinity("Caelan", 30)

	var controller = _make_camp_controller()
	controller._party_current_hp["Zi"] = 40

	# Visit sanctum — heals party
	var healed = controller.use_sanctum()
	_assert(healed, "Integration: sanctum heals")
	_assert(controller._party_current_hp["Zi"] == 100, "Integration: Zi at full HP after sanctum")

	# Visit quarters — conversation available
	_assert(controller.is_quarters_conversation_available(), "Integration: quarters conversation available")

	# Mark conversation seen
	controller.mark_quarters_conversation_seen()
	_assert(not controller.is_quarters_conversation_available(), "Integration: quarters conversation no longer available")

	# Forge is placeholder
	_assert(controller.get_forge_status() == "coming_soon", "Integration: forge is coming soon")

	controller.queue_free()
	AffinityManager.reset()
	GlobalFlags.reset()
	PartyManager.reset()


## --- Helper: create a CampController node without the full scene ---
func _make_camp_controller() -> Node:
	var script = load("res://scripts/camps/CampController.gd")
	var node = Node.new()
	node.set_script(script)
	add_child(node)
	return node


func _report() -> void:
	print("%s Results: %d passed, %d failed" % [TAG, _passed, _failed])
	if _failed == 0:
		print("%s ALL TESTS PASSED" % TAG)
	else:
		printerr("%s SOME TESTS FAILED" % TAG)
	if DisplayServer.get_name() == "headless":
		get_tree().quit()
