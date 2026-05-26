extends SceneTree

## Test script for world expansion: ZoneTransition, new areas, enemy variants.
## Run with: godot --headless --path . -s tests/test_world_expansion.gd

const TAG = "[TEST_WORLD_EXPANSION]"

var _tests_passed: int = 0
var _tests_failed: int = 0

func _init() -> void:
	root.ready.connect(_run_tests)


func _run_tests() -> void:
	print(TAG, " Starting tests...")

	_test_zone_transition_blocks_without_flag()
	_test_zone_transition_allows_with_flag()
	_test_zone_transition_signal()
	_test_zone_transition_message_on_block()
	_test_valdrihn_outpost_loads()
	_test_ereivyn_path_loads()
	_test_enemy_armor_type_export()
	_test_valdrihn_knight_stats()
	_test_forest_spirit_stats()
	_test_integration_flag_then_transition()

	_print_results()
	quit()


func _test_zone_transition_blocks_without_flag() -> void:
	GlobalFlags.reset()
	var zt = _make_zone_transition("res://scenes/world/ValdrihnOutpost.tscn", "opening_dialogue_done")
	var result = zt.can_transition()
	if result == false:
		_pass("ZoneTransition blocks access when required flag not set")
	else:
		_fail("ZoneTransition should block when flag not set, got: %s" % str(result))
	zt.queue_free()


func _test_zone_transition_allows_with_flag() -> void:
	GlobalFlags.reset()
	GlobalFlags.set_flag("opening_dialogue_done", true)
	var zt = _make_zone_transition("res://scenes/world/ValdrihnOutpost.tscn", "opening_dialogue_done")
	var result = zt.can_transition()
	if result == true:
		_pass("ZoneTransition allows access when required flag is set")
	else:
		_fail("ZoneTransition should allow when flag set, got: %s" % str(result))
	zt.queue_free()
	GlobalFlags.reset()


func _test_zone_transition_signal() -> void:
	GlobalFlags.reset()
	GlobalFlags.set_flag("opening_dialogue_done", true)
	var zt = _make_zone_transition("res://scenes/world/ValdrihnOutpost.tscn", "opening_dialogue_done")

	var signal_received := false
	var from_zone := ""
	var to_zone := ""
	zt.zone_changed.connect(func(f: String, t: String):
		signal_received = true
		from_zone = f
		to_zone = t
	)

	# Simulate the transition check (don't actually change scene)
	zt._emit_zone_changed("NaevoriaRuins", "ValdrihnOutpost")

	if signal_received and from_zone == "NaevoriaRuins" and to_zone == "ValdrihnOutpost":
		_pass("zone_changed signal emitted with correct from/to")
	else:
		_fail("zone_changed signal not emitted or wrong values: from=%s to=%s" % [from_zone, to_zone])
	zt.queue_free()
	GlobalFlags.reset()


func _test_zone_transition_message_on_block() -> void:
	GlobalFlags.reset()
	var zt = _make_zone_transition("res://scenes/world/ValdrihnOutpost.tscn", "opening_dialogue_done")
	var msg = zt.get_blocked_message()
	if msg != "" and msg.length() > 0:
		_pass("ZoneTransition returns blocked message: '%s'" % msg)
	else:
		_fail("ZoneTransition should return a non-empty blocked message")
	zt.queue_free()


func _test_valdrihn_outpost_loads() -> void:
	var scene = load("res://scenes/world/ValdrihnOutpost.tscn")
	if scene != null:
		var instance = scene.instantiate()
		root.add_child(instance)
		# Check it has enemies
		var enemies = instance.get_node_or_null("Enemies")
		if enemies and enemies.get_child_count() >= 2:
			_pass("ValdrihnOutpost loads with enemies")
		else:
			_fail("ValdrihnOutpost missing enemies node or insufficient enemies")
		instance.queue_free()
	else:
		_fail("Could not load ValdrihnOutpost.tscn")


func _test_ereivyn_path_loads() -> void:
	var scene = load("res://scenes/world/EreivynPath.tscn")
	if scene != null:
		var instance = scene.instantiate()
		root.add_child(instance)
		var enemies = instance.get_node_or_null("Enemies")
		if enemies and enemies.get_child_count() >= 2:
			_pass("EreivynPath loads with enemies")
		else:
			_fail("EreivynPath missing enemies node or insufficient enemies")
		instance.queue_free()
	else:
		_fail("Could not load EreivynPath.tscn")


func _test_enemy_armor_type_export() -> void:
	var enemy_scene = load("res://scenes/characters/OverworldEnemy.tscn")
	if enemy_scene == null:
		_fail("Could not load OverworldEnemy.tscn")
		return
	var enemy = enemy_scene.instantiate()
	root.add_child(enemy)
	# Default armor_type should be "Agile"
	if enemy.armor_type == "Agile":
		_pass("OverworldEnemy default armor_type is 'Agile'")
	else:
		_fail("OverworldEnemy default armor_type expected 'Agile', got '%s'" % enemy.armor_type)

	# Check that get_enemy_data returns armor_type
	var data = enemy.get_enemy_data()
	if data.get("armor_type") == "Agile":
		_pass("get_enemy_data() returns armor_type='Agile'")
	else:
		_fail("get_enemy_data() armor_type expected 'Agile', got '%s'" % str(data.get("armor_type")))
	enemy.queue_free()


func _test_valdrihn_knight_stats() -> void:
	var scene = load("res://scenes/world/ValdrihnOutpost.tscn")
	if scene == null:
		_fail("Could not load ValdrihnOutpost for knight stats test")
		return
	var instance = scene.instantiate()
	root.add_child(instance)
	var enemies_node = instance.get_node_or_null("Enemies")
	if enemies_node == null:
		_fail("ValdrihnOutpost has no Enemies node")
		instance.queue_free()
		return
	var knight = enemies_node.get_child(0)
	if knight.enemy_name == "Valdrihn Knight" and knight.enemy_level == 3 and knight.armor_type == "Heavy":
		_pass("Valdrihn Knight has correct name, level, armor_type")
	else:
		_fail("Valdrihn Knight stats wrong: name=%s level=%d armor=%s" % [knight.enemy_name, knight.enemy_level, knight.armor_type])
	instance.queue_free()


func _test_forest_spirit_stats() -> void:
	var scene = load("res://scenes/world/EreivynPath.tscn")
	if scene == null:
		_fail("Could not load EreivynPath for spirit stats test")
		return
	var instance = scene.instantiate()
	root.add_child(instance)
	var enemies_node = instance.get_node_or_null("Enemies")
	if enemies_node == null:
		_fail("EreivynPath has no Enemies node")
		instance.queue_free()
		return
	var spirit = enemies_node.get_child(0)
	if spirit.enemy_name == "Forest Spirit" and spirit.enemy_level == 2 and spirit.armor_type == "Spirit":
		_pass("Forest Spirit has correct name, level, armor_type")
	else:
		_fail("Forest Spirit stats wrong: name=%s level=%d armor=%s" % [spirit.enemy_name, spirit.enemy_level, spirit.armor_type])
	instance.queue_free()


func _test_integration_flag_then_transition() -> void:
	GlobalFlags.reset()
	var zt = _make_zone_transition("res://scenes/world/ValdrihnOutpost.tscn", "opening_dialogue_done")

	# Should be blocked first
	if zt.can_transition():
		_fail("Integration: should be blocked before flag set")
		zt.queue_free()
		return

	# Set the flag
	GlobalFlags.set_flag("opening_dialogue_done", true)

	# Now should be allowed
	if zt.can_transition():
		_pass("Integration: flag set -> transition allowed")
	else:
		_fail("Integration: transition should be allowed after flag set")
	zt.queue_free()
	GlobalFlags.reset()


# --- Helpers ---

func _make_zone_transition(target: String, flag: String) -> Node:
	var zt_scene = load("res://scenes/world/ZoneTransition.tscn")
	var zt = zt_scene.instantiate()
	zt.target_scene_path = target
	zt.required_flag = flag
	root.add_child(zt)
	return zt


func _pass(msg: String) -> void:
	_tests_passed += 1
	print(TAG, " PASS: ", msg)


func _fail(msg: String) -> void:
	_tests_failed += 1
	print(TAG, " FAIL: ", msg)


func _print_results() -> void:
	print(TAG, " ---")
	print(TAG, " Passed: ", _tests_passed, " Failed: ", _tests_failed)
	if _tests_failed == 0:
		print(TAG, " SUCCESS")
	else:
		print(TAG, " FAILED")
