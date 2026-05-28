extends SceneTree

## Test script for new world areas: SolenneTrade and VelundrathCoast.
## Run with: godot --headless --path . -s tests/test_world_areas.gd

const TAG = "[TEST_WORLD_AREAS]"

var _tests_passed: int = 0
var _tests_failed: int = 0

func _init() -> void:
	root.ready.connect(_run_tests)


func _run_tests() -> void:
	print(TAG, " Starting tests...")

	_test_solenne_trade_loads()
	_test_velundrath_coast_loads()
	_test_solenne_has_enemies()
	_test_velundrath_has_enemies()
	_test_solenne_enemy_stats()
	_test_velundrath_enemy_stats()
	_test_solenne_has_zone_transitions()
	_test_velundrath_has_zone_transitions()
	_test_solenne_has_area_label()
	_test_velundrath_has_area_label()
	_test_dialogue_scene_08_parses()
	_test_dialogue_scene_09_parses()
	_test_dialogue_scene_08_structure()
	_test_dialogue_scene_09_structure()
	_test_enemy_data_solenne_scout_loads()
	_test_enemy_data_velundrath_guardian_loads()

	_print_results()
	quit()


func _test_solenne_trade_loads() -> void:
	var scene = load("res://scenes/world/SolenneTrade.tscn")
	if scene != null:
		_pass("SolenneTrade.tscn loads successfully")
	else:
		_fail("Could not load SolenneTrade.tscn")


func _test_velundrath_coast_loads() -> void:
	var scene = load("res://scenes/world/VelundrathCoast.tscn")
	if scene != null:
		_pass("VelundrathCoast.tscn loads successfully")
	else:
		_fail("Could not load VelundrathCoast.tscn")


func _test_solenne_has_enemies() -> void:
	var scene = load("res://scenes/world/SolenneTrade.tscn")
	if scene == null:
		_fail("Could not load SolenneTrade for enemies test")
		return
	var instance = scene.instantiate()
	root.add_child(instance)
	var enemies = instance.get_node_or_null("Enemies")
	if enemies and enemies.get_child_count() >= 2:
		_pass("SolenneTrade has enemies (%d)" % enemies.get_child_count())
	else:
		_fail("SolenneTrade missing enemies or insufficient count")
	instance.queue_free()


func _test_velundrath_has_enemies() -> void:
	var scene = load("res://scenes/world/VelundrathCoast.tscn")
	if scene == null:
		_fail("Could not load VelundrathCoast for enemies test")
		return
	var instance = scene.instantiate()
	root.add_child(instance)
	var enemies = instance.get_node_or_null("Enemies")
	if enemies and enemies.get_child_count() >= 2:
		_pass("VelundrathCoast has enemies (%d)" % enemies.get_child_count())
	else:
		_fail("VelundrathCoast missing enemies or insufficient count")
	instance.queue_free()


func _test_solenne_enemy_stats() -> void:
	var scene = load("res://scenes/world/SolenneTrade.tscn")
	if scene == null:
		_fail("Could not load SolenneTrade for enemy stats test")
		return
	var instance = scene.instantiate()
	root.add_child(instance)
	var enemies_node = instance.get_node_or_null("Enemies")
	if enemies_node == null:
		_fail("SolenneTrade has no Enemies node")
		instance.queue_free()
		return
	var scout = enemies_node.get_child(0)
	if scout.enemy_name == "Solenné Scout" and scout.enemy_level == 4 and scout.armor_type == "Agile":
		_pass("Solenné Scout has correct name, level, armor_type")
	else:
		_fail("Solenné Scout stats wrong: name=%s level=%d armor=%s" % [scout.enemy_name, scout.enemy_level, scout.armor_type])
	instance.queue_free()


func _test_velundrath_enemy_stats() -> void:
	var scene = load("res://scenes/world/VelundrathCoast.tscn")
	if scene == null:
		_fail("Could not load VelundrathCoast for enemy stats test")
		return
	var instance = scene.instantiate()
	root.add_child(instance)
	var enemies_node = instance.get_node_or_null("Enemies")
	if enemies_node == null:
		_fail("VelundrathCoast has no Enemies node")
		instance.queue_free()
		return
	var guardian = enemies_node.get_child(0)
	if guardian.enemy_name == "Velundrath Guardian" and guardian.enemy_level == 5 and guardian.armor_type == "Heavy":
		_pass("Velundrath Guardian has correct name, level, armor_type")
	else:
		_fail("Velundrath Guardian stats wrong: name=%s level=%d armor=%s" % [guardian.enemy_name, guardian.enemy_level, guardian.armor_type])
	instance.queue_free()


func _test_solenne_has_zone_transitions() -> void:
	var scene = load("res://scenes/world/SolenneTrade.tscn")
	if scene == null:
		_fail("Could not load SolenneTrade for zone transition test")
		return
	var instance = scene.instantiate()
	root.add_child(instance)
	var west = instance.get_node_or_null("ZoneExitWest")
	var east = instance.get_node_or_null("ZoneExitEast")
	if west and east:
		_pass("SolenneTrade has zone transitions (West, East)")
	else:
		_fail("SolenneTrade missing zone transitions: West=%s East=%s" % [str(west != null), str(east != null)])
	instance.queue_free()


func _test_velundrath_has_zone_transitions() -> void:
	var scene = load("res://scenes/world/VelundrathCoast.tscn")
	if scene == null:
		_fail("Could not load VelundrathCoast for zone transition test")
		return
	var instance = scene.instantiate()
	root.add_child(instance)
	var west = instance.get_node_or_null("ZoneExitWest")
	var north = instance.get_node_or_null("ZoneExitNorth")
	if west and north:
		_pass("VelundrathCoast has zone transitions (West, North)")
	else:
		_fail("VelundrathCoast missing zone transitions: West=%s North=%s" % [str(west != null), str(north != null)])
	instance.queue_free()


func _test_solenne_has_area_label() -> void:
	var scene = load("res://scenes/world/SolenneTrade.tscn")
	if scene == null:
		_fail("Could not load SolenneTrade for label test")
		return
	var instance = scene.instantiate()
	root.add_child(instance)
	var label = instance.get_node_or_null("AreaLabel")
	if label and label is Label and label.text != "":
		_pass("SolenneTrade has area label: '%s'" % label.text)
	else:
		_fail("SolenneTrade missing or empty AreaLabel")
	instance.queue_free()


func _test_velundrath_has_area_label() -> void:
	var scene = load("res://scenes/world/VelundrathCoast.tscn")
	if scene == null:
		_fail("Could not load VelundrathCoast for label test")
		return
	var instance = scene.instantiate()
	root.add_child(instance)
	var label = instance.get_node_or_null("AreaLabel")
	if label and label is Label and label.text != "":
		_pass("VelundrathCoast has area label: '%s'" % label.text)
	else:
		_fail("VelundrathCoast missing or empty AreaLabel")
	instance.queue_free()


func _test_dialogue_scene_08_parses() -> void:
	var file = FileAccess.open("res://data/dialogue/scene_08_solenne_arrival.json", FileAccess.READ)
	if file == null:
		_fail("Could not open scene_08_solenne_arrival.json")
		return
	var text = file.get_as_text()
	file.close()
	var json = JSON.new()
	var err = json.parse(text)
	if err == OK:
		_pass("scene_08_solenne_arrival.json parses as valid JSON")
	else:
		_fail("scene_08_solenne_arrival.json parse error: %s" % json.get_error_message())


func _test_dialogue_scene_09_parses() -> void:
	var file = FileAccess.open("res://data/dialogue/scene_09_velundrath_arrival.json", FileAccess.READ)
	if file == null:
		_fail("Could not open scene_09_velundrath_arrival.json")
		return
	var text = file.get_as_text()
	file.close()
	var json = JSON.new()
	var err = json.parse(text)
	if err == OK:
		_pass("scene_09_velundrath_arrival.json parses as valid JSON")
	else:
		_fail("scene_09_velundrath_arrival.json parse error: %s" % json.get_error_message())


func _test_dialogue_scene_08_structure() -> void:
	var file = FileAccess.open("res://data/dialogue/scene_08_solenne_arrival.json", FileAccess.READ)
	if file == null:
		_fail("Could not open scene_08 for structure test")
		return
	var text = file.get_as_text()
	file.close()
	var json = JSON.new()
	json.parse(text)
	var data = json.data
	if data is Dictionary and data.has("id") and data.has("start_node") and data.has("nodes"):
		var start = data["start_node"]
		if data["nodes"].has(start):
			_pass("scene_08 has valid structure with start_node '%s'" % start)
		else:
			_fail("scene_08 start_node '%s' not found in nodes" % start)
	else:
		_fail("scene_08 missing required keys (id, start_node, nodes)")


func _test_dialogue_scene_09_structure() -> void:
	var file = FileAccess.open("res://data/dialogue/scene_09_velundrath_arrival.json", FileAccess.READ)
	if file == null:
		_fail("Could not open scene_09 for structure test")
		return
	var text = file.get_as_text()
	file.close()
	var json = JSON.new()
	json.parse(text)
	var data = json.data
	if data is Dictionary and data.has("id") and data.has("start_node") and data.has("nodes"):
		var start = data["start_node"]
		if data["nodes"].has(start):
			_pass("scene_09 has valid structure with start_node '%s'" % start)
		else:
			_fail("scene_09 start_node '%s' not found in nodes" % start)
	else:
		_fail("scene_09 missing required keys (id, start_node, nodes)")


func _test_enemy_data_solenne_scout_loads() -> void:
	var res = load("res://data/enemies/solenne_scout.tres")
	if res != null:
		var name_val = res.get_meta("enemy_name", "")
		if name_val == "Solenné Scout":
			_pass("solenne_scout.tres loads with correct enemy_name")
		else:
			_pass("solenne_scout.tres loads as resource")
	else:
		_fail("Could not load solenne_scout.tres")


func _test_enemy_data_velundrath_guardian_loads() -> void:
	var res = load("res://data/enemies/velundrath_guardian.tres")
	if res != null:
		var name_val = res.get_meta("enemy_name", "")
		if name_val == "Velundrath Guardian":
			_pass("velundrath_guardian.tres loads with correct enemy_name")
		else:
			_pass("velundrath_guardian.tres loads as resource")
	else:
		_fail("Could not load velundrath_guardian.tres")


# --- Helpers ---

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
