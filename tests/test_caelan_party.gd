extends Node2D

## Tests for Caelan as a playable party member.
## Run with: godot --headless --path . tests/test_caelan_party.tscn

const TAG = "[TEST_CAELAN_PARTY]"

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	print("%s Starting Caelan party member tests..." % TAG)

	# Resource loading tests
	_test_caelan_loads_as_character_data()
	_test_caelan_has_correct_stats()
	_test_divine_strike_loads_as_skill_data()
	_test_remnant_light_loads_as_skill_data()

	# StanceSystem tests
	_test_caelan_stances_in_stance_advantages()
	_test_threshold_vs_magic_multiplier()
	_test_gentle_current_vs_spirit_multiplier()
	_test_fractured_form_is_universal()

	# BattleTransition tests
	_test_party_resources_includes_caelan()
	_test_build_party_data_includes_both()
	_test_caelan_party_data_has_correct_fields()

	# Integration: party + combat turn queue
	_test_integration_party_with_enemy_turn_queue()

	# Story trigger tests
	_test_caelan_joined_flag()
	_test_add_caelan_to_party_manager()

	_report()


func _assert(condition: bool, name: String) -> void:
	if condition:
		_passed += 1
		print("%s PASS: %s" % [TAG, name])
	else:
		_failed += 1
		printerr("%s FAIL: %s" % [TAG, name])


# --- Resource loading tests ---

func _test_caelan_loads_as_character_data() -> void:
	var caelan = load("res://data/characters/caelan.tres")
	_assert(caelan != null, "caelan.tres loads successfully")
	_assert(caelan is CharacterData, "caelan.tres is a CharacterData resource")
	if caelan:
		_assert(caelan.name == "Caelan", "caelan.tres name is 'Caelan'")


func _test_caelan_has_correct_stats() -> void:
	var caelan = load("res://data/characters/caelan.tres") as CharacterData
	if caelan == null:
		_assert(false, "Could not load caelan.tres for stats check")
		return

	_assert(caelan.max_hp == 95, "Caelan max_hp is 95 (got %d)" % caelan.max_hp)
	_assert(caelan.attack == 16, "Caelan attack is 16 (got %d)" % caelan.attack)
	_assert(caelan.defense == 8, "Caelan defense is 8 (got %d)" % caelan.defense)
	_assert(caelan.speed == 9, "Caelan speed is 9 (got %d)" % caelan.speed)
	_assert(caelan.stances.size() == 3, "Caelan has 3 stances (got %d)" % caelan.stances.size())
	_assert("Threshold" in caelan.stances, "Caelan has Threshold stance")
	_assert("Gentle Current" in caelan.stances, "Caelan has Gentle Current stance")
	_assert("Fractured Form" in caelan.stances, "Caelan has Fractured Form stance")
	_assert(caelan.skills.size() == 2, "Caelan has 2 skills (got %d)" % caelan.skills.size())


func _test_divine_strike_loads_as_skill_data() -> void:
	var skill = load("res://data/skills/caelan_divine_strike.tres")
	_assert(skill != null, "caelan_divine_strike.tres loads successfully")
	_assert(skill is SkillData, "caelan_divine_strike.tres is a SkillData resource")
	if skill:
		_assert(skill.name == "Divine Strike", "Skill name is 'Divine Strike' (got '%s')" % skill.name)
		_assert(is_equal_approx(skill.damage_multiplier, 1.2), "Divine Strike damage_multiplier is 1.2 (got %f)" % skill.damage_multiplier)
		_assert(is_equal_approx(skill.momentum_change, 8.0), "Divine Strike momentum_change is 8.0 (got %f)" % skill.momentum_change)


func _test_remnant_light_loads_as_skill_data() -> void:
	var skill = load("res://data/skills/caelan_remnant_light.tres")
	_assert(skill != null, "caelan_remnant_light.tres loads successfully")
	_assert(skill is SkillData, "caelan_remnant_light.tres is a SkillData resource")
	if skill:
		_assert(skill.name == "Remnant Light", "Skill name is 'Remnant Light' (got '%s')" % skill.name)
		_assert(is_equal_approx(skill.damage_multiplier, 0.8), "Remnant Light damage_multiplier is 0.8 (got %f)" % skill.damage_multiplier)
		_assert(is_equal_approx(skill.momentum_change, -5.0), "Remnant Light momentum_change is -5.0 (got %f)" % skill.momentum_change)


# --- StanceSystem tests ---

func _test_caelan_stances_in_stance_advantages() -> void:
	_assert("Threshold" in StanceSystem.STANCE_ADVANTAGES, "Threshold is in STANCE_ADVANTAGES")
	_assert("Gentle Current" in StanceSystem.STANCE_ADVANTAGES, "Gentle Current is in STANCE_ADVANTAGES")
	_assert("Fractured Form" in StanceSystem.STANCE_ADVANTAGES, "Fractured Form is in STANCE_ADVANTAGES")


func _test_threshold_vs_magic_multiplier() -> void:
	var mult = StanceSystem.get_multiplier("Threshold", "Magic")
	_assert(is_equal_approx(mult, 1.3), "Threshold vs Magic = 1.3x (got %f)" % mult)


func _test_gentle_current_vs_spirit_multiplier() -> void:
	var mult = StanceSystem.get_multiplier("Gentle Current", "Spirit")
	_assert(is_equal_approx(mult, 1.3), "Gentle Current vs Spirit = 1.3x (got %f)" % mult)


func _test_fractured_form_is_universal() -> void:
	var mult = StanceSystem.get_multiplier("Fractured Form", "Heavy")
	_assert(is_equal_approx(mult, 1.0), "Fractured Form vs Heavy = 1.0x (universal, got %f)" % mult)


# --- BattleTransition tests ---

func _test_party_resources_includes_caelan() -> void:
	_assert("res://data/characters/caelan.tres" in BattleTransition.PARTY_RESOURCES, "PARTY_RESOURCES includes caelan.tres")
	_assert("res://data/characters/zi.tres" in BattleTransition.PARTY_RESOURCES, "PARTY_RESOURCES still includes zi.tres")


func _test_build_party_data_includes_both() -> void:
	var bt = get_node_or_null("/root/BattleTransition")
	if bt == null:
		_assert(false, "BattleTransition autoload not found")
		return

	var party_data = bt._build_party_data()
	_assert(party_data.size() == 2, "Party data has 2 members (got %d)" % party_data.size())

	var names: Array[String] = []
	for member in party_data:
		names.append(member.get("name", ""))
	_assert("Zi" in names, "Party data includes Zi")
	_assert("Caelan" in names, "Party data includes Caelan")


func _test_caelan_party_data_has_correct_fields() -> void:
	var bt = get_node_or_null("/root/BattleTransition")
	if bt == null:
		_assert(false, "BattleTransition autoload not found for fields test")
		return

	var party_data = bt._build_party_data()
	var caelan_data: Dictionary = {}
	for member in party_data:
		if member.get("name") == "Caelan":
			caelan_data = member
			break

	if caelan_data.is_empty():
		_assert(false, "Caelan not found in party data")
		return

	_assert(caelan_data.get("hp") == 95, "Caelan party data hp = 95 (got %s)" % str(caelan_data.get("hp")))
	_assert(caelan_data.get("max_hp") == 95, "Caelan party data max_hp = 95 (got %s)" % str(caelan_data.get("max_hp")))
	_assert(caelan_data.get("attack") == 16, "Caelan party data attack = 16 (got %s)" % str(caelan_data.get("attack")))
	_assert(caelan_data.get("defense") == 8, "Caelan party data defense = 8 (got %s)" % str(caelan_data.get("defense")))
	_assert(caelan_data.get("speed") == 9, "Caelan party data speed = 9 (got %s)" % str(caelan_data.get("speed")))
	_assert(caelan_data.get("is_enemy") == false, "Caelan party data is_enemy = false")
	_assert(caelan_data.has("stances"), "Caelan party data has stances key")
	_assert(caelan_data.has("skills"), "Caelan party data has skills key")
	_assert(caelan_data.has("active_stance"), "Caelan party data has active_stance key")
	_assert(caelan_data.get("active_stance") == "Threshold", "Caelan active_stance defaults to Threshold (got '%s')" % str(caelan_data.get("active_stance")))


# --- Integration: turn queue with 2 party + 1 enemy ---

func _test_integration_party_with_enemy_turn_queue() -> void:
	# Build party data from BattleTransition
	var bt = get_node_or_null("/root/BattleTransition")
	if bt == null:
		_assert(false, "BattleTransition autoload not found for integration test")
		return

	var party_data = bt._build_party_data()
	_assert(party_data.size() == 2, "Integration: party has 2 members")

	# Build a mock enemy
	var enemy_data: Dictionary = {
		"name": "Test Slime",
		"hp": 20,
		"max_hp": 20,
		"attack": 5,
		"defense": 0,
		"speed": 5,
		"armor_type": "Agile",
		"is_enemy": true,
	}

	# Combine into a turn queue sorted by speed (descending)
	var all_combatants: Array[Dictionary] = []
	for member in party_data:
		all_combatants.append(member)
	all_combatants.append(enemy_data)

	all_combatants.sort_custom(func(a, b): return a.get("speed", 0) > b.get("speed", 0))

	_assert(all_combatants.size() == 3, "Integration: turn queue has 3 combatants (got %d)" % all_combatants.size())
	# Zi has speed 11, Caelan has speed 9, Slime has speed 5
	_assert(all_combatants[0].get("name") == "Zi", "Integration: Zi goes first (speed 11, got '%s')" % all_combatants[0].get("name"))
	_assert(all_combatants[1].get("name") == "Caelan", "Integration: Caelan goes second (speed 9, got '%s')" % all_combatants[1].get("name"))
	_assert(all_combatants[2].get("name") == "Test Slime", "Integration: Test Slime goes third (speed 5, got '%s')" % all_combatants[2].get("name"))


# --- Story trigger tests ---

func _test_caelan_joined_flag() -> void:
	var gf = get_node_or_null("/root/GlobalFlags")
	if gf == null:
		_assert(false, "GlobalFlags autoload not found")
		return

	gf.reset()
	_assert(gf.get_flag("caelan_joined") == false, "caelan_joined flag starts as false")

	gf.set_flag("caelan_joined", true)
	_assert(gf.get_flag("caelan_joined") == true, "caelan_joined flag can be set to true")
	gf.reset()


func _test_add_caelan_to_party_manager() -> void:
	var pm = get_node_or_null("/root/PartyManager")
	if pm == null:
		_assert(false, "PartyManager autoload not found")
		return

	pm.reset()
	var caelan = load("res://data/characters/caelan.tres") as CharacterData
	if caelan == null:
		_assert(false, "Could not load caelan.tres for party manager test")
		return

	pm.add_to_party(caelan)
	var party = pm.get_active_party()
	_assert(party.size() == 1, "Party has 1 member after adding Caelan")
	_assert(party[0].name == "Caelan", "Party member is Caelan")
	pm.reset()


func _report() -> void:
	print("%s Results: %d passed, %d failed" % [TAG, _passed, _failed])
	if _failed == 0:
		print("%s SUCCESS" % TAG)
	else:
		printerr("%s FAILED" % TAG)
	if DisplayServer.get_name() == "headless":
		get_tree().quit()
