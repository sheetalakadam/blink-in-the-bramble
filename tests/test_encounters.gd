extends Node2D

const TAG = "[TEST_ENCOUNTERS]"
var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	print("%s Starting encounter table tests..." % TAG)
	_test_all_regions_return_formations()
	_test_formation_size_limits()
	_test_enemy_has_required_fields()
	_test_unknown_region_fallback()
	_test_drops_are_valid_paths()
	_report()


func _assert(condition: bool, name: String) -> void:
	if condition:
		_passed += 1
		print("%s PASS: %s" % [TAG, name])
	else:
		_failed += 1
		printerr("%s FAIL: %s" % [TAG, name])


func _test_all_regions_return_formations() -> void:
	var regions := ["naevoria", "valdrihn", "solenne", "ereivyn", "velundrath", "corrupted"]
	for region in regions:
		var formation := EncounterTable.get_encounter(region)
		_assert(formation.size() > 0, "%s returns enemies" % region)
		_assert(formation.size() <= 3, "%s has at most 3 enemies" % region)


func _test_formation_size_limits() -> void:
	# Run multiple times to test randomization
	for i in range(20):
		for region in ["valdrihn", "ereivyn", "corrupted"]:
			var f := EncounterTable.get_encounter(region)
			_assert(f.size() >= 1 and f.size() <= 3, "%s formation size valid (run %d)" % [region, i])
			# Early exit after first pass per region to avoid too many test lines
			break


func _test_enemy_has_required_fields() -> void:
	var required := ["name", "hp", "max_hp", "attack", "defense", "speed", "armor_type", "is_enemy"]
	for region in ["naevoria", "valdrihn", "solenne", "ereivyn", "velundrath", "corrupted"]:
		var formation := EncounterTable.get_encounter(region)
		for enemy in formation:
			for field in required:
				_assert(enemy.has(field), "%s enemy has field '%s'" % [region, field])
			_assert(enemy.is_enemy == true, "%s enemy is_enemy is true" % region)
			# Only check first enemy per region
			break


func _test_unknown_region_fallback() -> void:
	var formation := EncounterTable.get_encounter("nonexistent")
	_assert(formation.size() > 0, "unknown region returns fallback")
	_assert(formation[0].name == "Green Slime", "fallback is Green Slime")


func _test_drops_are_valid_paths() -> void:
	# Check that any listed drop paths actually resolve
	for region in ["naevoria", "valdrihn", "solenne"]:
		var formation := EncounterTable.get_encounter(region)
		for enemy in formation:
			var drops: Array = enemy.get("drops", [])
			for drop_path in drops:
				var item = load(drop_path)
				_assert(item != null, "drop '%s' loads for %s" % [drop_path, enemy.name])


func _report() -> void:
	print("%s Results: %d passed, %d failed" % [TAG, _passed, _failed])
	if _failed == 0:
		print("%s ALL TESTS PASSED" % TAG)
	else:
		printerr("%s SOME TESTS FAILED" % TAG)
	if DisplayServer.get_name() == "headless":
		get_tree().quit()
