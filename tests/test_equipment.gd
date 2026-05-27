extends Node2D

## Tests for the equipment system.
## Run with: godot --headless --path . tests/test_equipment.tscn

const TAG = "[TEST_EQUIPMENT]"

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	print("%s Starting equipment tests..." % TAG)
	_test_equipment_data_resource_fields()
	_test_equipment_tres_files_load()
	_test_get_stance_bonus_matching()
	_test_get_stance_bonus_no_match()
	_test_get_stat_bonuses_combines()
	_test_get_unlocked_skills()
	_test_forge_status_available()
	_test_integration_stance_multiplier_with_equipment()
	_report()


func _assert(condition: bool, name: String) -> void:
	if condition:
		_passed += 1
		print("%s PASS: %s" % [TAG, name])
	else:
		_failed += 1
		printerr("%s FAIL: %s" % [TAG, name])


## --- Test 1: EquipmentData resource creates with correct fields ---
func _test_equipment_data_resource_fields() -> void:
	var equip = EquipmentData.new()
	equip.name = "Test Blade"
	equip.description = "A test weapon"
	equip.slot = "weapon"
	equip.stance_bonus = "Soldier's Edge"
	equip.stance_bonus_amount = 0.1
	equip.stat_bonus = {"attack": 2}
	equip.unlocked_skill_path = ""

	_assert(equip.name == "Test Blade", "EquipmentData: name field")
	_assert(equip.description == "A test weapon", "EquipmentData: description field")
	_assert(equip.slot == "weapon", "EquipmentData: slot field")
	_assert(equip.stance_bonus == "Soldier's Edge", "EquipmentData: stance_bonus field")
	_assert(is_equal_approx(equip.stance_bonus_amount, 0.1), "EquipmentData: stance_bonus_amount field")
	_assert(equip.stat_bonus.get("attack") == 2, "EquipmentData: stat_bonus field")
	_assert(equip.unlocked_skill_path == "", "EquipmentData: unlocked_skill_path field")


## --- Test 2: Equipment .tres files load ---
func _test_equipment_tres_files_load() -> void:
	var paths = [
		"res://data/equipment/valdrihn_blade.tres",
		"res://data/equipment/ereivyn_charm.tres",
		"res://data/equipment/threshold_focus.tres",
	]
	for path in paths:
		var res = load(path)
		_assert(res != null, "Equipment .tres loads: %s" % path)
		if res != null:
			_assert(res is EquipmentData, "Equipment .tres is EquipmentData: %s" % path)
			_assert(res.name != "", "Equipment .tres has name: %s" % path)
			_assert(res.slot != "", "Equipment .tres has slot: %s" % path)


## --- Test 3: get_stance_bonus returns correct bonus for matching stance ---
func _test_get_stance_bonus_matching() -> void:
	var items: Array[EquipmentData] = []

	var blade = EquipmentData.new()
	blade.stance_bonus = "Soldier's Edge"
	blade.stance_bonus_amount = 0.1
	items.append(blade)

	var charm = EquipmentData.new()
	charm.stance_bonus = "Soldier's Edge"
	charm.stance_bonus_amount = 0.05
	items.append(charm)

	var bonus = EquipmentManager.get_stance_bonus(items, "Soldier's Edge")
	_assert(is_equal_approx(bonus, 0.15), "get_stance_bonus: returns 0.15 for two matching items")


## --- Test 4: get_stance_bonus returns 0 for non-matching stance ---
func _test_get_stance_bonus_no_match() -> void:
	var items: Array[EquipmentData] = []

	var blade = EquipmentData.new()
	blade.stance_bonus = "Soldier's Edge"
	blade.stance_bonus_amount = 0.1
	items.append(blade)

	var bonus = EquipmentManager.get_stance_bonus(items, "Forest Floor")
	_assert(is_equal_approx(bonus, 0.0), "get_stance_bonus: returns 0.0 for non-matching stance")


## --- Test 5: get_stat_bonuses combines multiple items ---
func _test_get_stat_bonuses_combines() -> void:
	var items: Array[EquipmentData] = []

	var blade = EquipmentData.new()
	blade.stat_bonus = {"attack": 2, "speed": 1}
	items.append(blade)

	var charm = EquipmentData.new()
	charm.stat_bonus = {"attack": 1, "defense": 3}
	items.append(charm)

	var combined = EquipmentManager.get_stat_bonuses(items)
	_assert(combined.get("attack", 0) == 3, "get_stat_bonuses: attack combined = 3")
	_assert(combined.get("defense", 0) == 3, "get_stat_bonuses: defense combined = 3")
	_assert(combined.get("speed", 0) == 1, "get_stat_bonuses: speed combined = 1")


## --- Test 6: get_unlocked_skills returns skill paths ---
func _test_get_unlocked_skills() -> void:
	var items: Array[EquipmentData] = []

	var focus = EquipmentData.new()
	focus.unlocked_skill_path = "res://data/skills/zi_strike.tres"
	items.append(focus)

	var blade = EquipmentData.new()
	blade.unlocked_skill_path = ""
	items.append(blade)

	var charm = EquipmentData.new()
	charm.unlocked_skill_path = "res://data/skills/zi_read.tres"
	items.append(charm)

	var skills = EquipmentManager.get_unlocked_skills(items)
	_assert(skills.size() == 2, "get_unlocked_skills: returns 2 paths")
	_assert("res://data/skills/zi_strike.tres" in skills, "get_unlocked_skills: contains zi_strike path")
	_assert("res://data/skills/zi_read.tres" in skills, "get_unlocked_skills: contains zi_read path")


## --- Test 7: Forge status returns "available" ---
func _test_forge_status_available() -> void:
	var controller = _make_camp_controller()
	var result = controller.get_forge_status()
	_assert(result == "available", "Forge: returns available status")
	controller.queue_free()


## --- Test 8: Integration — equip item, verify stance multiplier increases ---
func _test_integration_stance_multiplier_with_equipment() -> void:
	# Base stance multiplier without equipment
	var base_mult = StanceSystem.get_multiplier("Soldier's Edge", "")
	_assert(is_equal_approx(base_mult, 1.0), "Integration: base stance mult is 1.0 for neutral")

	# Create equipment that enhances Soldier's Edge
	var items: Array[EquipmentData] = []
	var blade = EquipmentData.new()
	blade.stance_bonus = "Soldier's Edge"
	blade.stance_bonus_amount = 0.1
	items.append(blade)

	# Simulate damage calc: stance_mult + equipment bonus
	var stance_mult = StanceSystem.get_multiplier("Soldier's Edge", "")
	var equip_bonus = EquipmentManager.get_stance_bonus(items, "Soldier's Edge")
	var total_mult = stance_mult + equip_bonus
	_assert(is_equal_approx(total_mult, 1.1), "Integration: stance mult + equipment = 1.1")

	# With advantage AND equipment
	var advantage_mult = StanceSystem.get_multiplier("Counter Step", "Agile")
	equip_bonus = EquipmentManager.get_stance_bonus(items, "Counter Step")
	total_mult = advantage_mult + equip_bonus
	# Equipment doesn't match Counter Step, so bonus is 0
	_assert(is_equal_approx(total_mult, 1.3), "Integration: advantage stance + no equip bonus = 1.3")

	# CharacterData can hold equipment
	var zi = CharacterData.new()
	zi.name = "Zi"
	zi.equipment.append(blade)
	_assert(zi.equipment.size() == 1, "Integration: CharacterData holds equipment")
	var zi_bonus = EquipmentManager.get_stance_bonus(zi.equipment, "Soldier's Edge")
	_assert(is_equal_approx(zi_bonus, 0.1), "Integration: CharacterData equipment stance bonus works")


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
