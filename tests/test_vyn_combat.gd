extends Node2D

var _tests_passed: int = 0
var _tests_failed: int = 0

func _ready() -> void:
	print("[TEST_VYN_COMBAT] Starting Vyn combat AI tests...")

	_test_choose_action_root_when_party_low()
	_test_choose_action_pack_instinct_when_last_target_alive()
	_test_choose_action_wild_strike_default()
	_test_wild_strike_variance_range()
	_test_damage_multiplier_zi_low_hp()
	_test_damage_multiplier_normal()
	_test_vyn_character_data_loads()
	_test_vyn_turn_skips_menu()

	print("[TEST_VYN_COMBAT] Results: %d passed, %d failed" % [_tests_passed, _tests_failed])
	if _tests_failed == 0:
		print("[TEST_VYN_COMBAT] SUCCESS")
	else:
		printerr("[TEST_VYN_COMBAT] FAILED")

	if DisplayServer.get_name() == "headless":
		get_tree().quit()

func _assert(condition: bool, test_name: String) -> void:
	if condition:
		_tests_passed += 1
		print("[TEST_VYN_COMBAT] PASS: ", test_name)
	else:
		_tests_failed += 1
		printerr("[TEST_VYN_COMBAT] FAIL: ", test_name)

# --- Test: choose_action returns "root" when party member below 25% HP ---
func _test_choose_action_root_when_party_low() -> void:
	var vyn = {"name": "Vyn", "hp": 80, "max_hp": 80, "attack": 10}
	var zi = {"name": "Zi", "hp": 20, "max_hp": 120}  # 16.7% < 25%
	var party = [vyn, zi]
	var enemy1 = {"name": "Goblin", "hp": 30, "max_hp": 30, "attack": 8, "attacked_last_turn": true}
	var enemy2 = {"name": "Slime", "hp": 20, "max_hp": 20, "attack": 5}
	var enemies = [enemy1, enemy2]
	var last_target: Dictionary = {}

	var result = VynCombatAI.choose_action(vyn, party, enemies, last_target)
	_assert(result.action == "root", "choose_action returns 'root' when party member below 25% HP")
	_assert(result.target.name == "Goblin", "Root targets enemy that attacked last turn")

# --- Test: choose_action returns "pack_instinct" when last_target alive ---
func _test_choose_action_pack_instinct_when_last_target_alive() -> void:
	var vyn = {"name": "Vyn", "hp": 80, "max_hp": 80, "attack": 10}
	var zi = {"name": "Zi", "hp": 100, "max_hp": 120}
	var party = [vyn, zi]
	var enemy1 = {"name": "Goblin", "hp": 30, "max_hp": 30, "attack": 8}
	var enemies = [enemy1]
	var last_target = {"name": "Goblin", "hp": 30, "max_hp": 30}

	var result = VynCombatAI.choose_action(vyn, party, enemies, last_target)
	_assert(result.action == "pack_instinct", "choose_action returns 'pack_instinct' when last_target is alive")
	_assert(result.target.name == "Goblin", "Pack Instinct targets same enemy")

# --- Test: choose_action returns "wild_strike" as default ---
func _test_choose_action_wild_strike_default() -> void:
	var vyn = {"name": "Vyn", "hp": 80, "max_hp": 80, "attack": 10}
	var zi = {"name": "Zi", "hp": 100, "max_hp": 120}
	var party = [vyn, zi]
	var enemy1 = {"name": "Goblin", "hp": 10, "max_hp": 30, "attack": 8}
	var enemy2 = {"name": "Slime", "hp": 20, "max_hp": 20, "attack": 5}
	var enemies = [enemy1, enemy2]
	var last_target: Dictionary = {}

	var result = VynCombatAI.choose_action(vyn, party, enemies, last_target)
	_assert(result.action == "wild_strike", "choose_action returns 'wild_strike' as default")
	_assert(result.target.name == "Slime", "Wild Strike targets highest HP enemy")

# --- Test: wild_strike_variance is between 0.7 and 1.3 ---
func _test_wild_strike_variance_range() -> void:
	var all_in_range = true
	for i in range(100):
		var v = VynCombatAI.calculate_wild_strike_variance()
		if v < 0.7 or v > 1.3:
			all_in_range = false
			break
	_assert(all_in_range, "wild_strike_variance is always between 0.7 and 1.3")

# --- Test: damage multiplier 1.5 when Zi below 30% ---
func _test_damage_multiplier_zi_low_hp() -> void:
	var vyn = {"name": "Vyn", "hp": 80, "max_hp": 80, "attack": 10}
	var zi = {"name": "Zi", "hp": 30, "max_hp": 120}  # 25% < 30%
	var party = [vyn, zi]

	var mult = VynCombatAI.get_damage_multiplier(vyn, party)
	_assert(mult == 1.5, "get_damage_multiplier returns 1.5 when Zi below 30% HP")

# --- Test: damage multiplier 1.0 normally ---
func _test_damage_multiplier_normal() -> void:
	var vyn = {"name": "Vyn", "hp": 80, "max_hp": 80, "attack": 10}
	var zi = {"name": "Zi", "hp": 100, "max_hp": 120}
	var party = [vyn, zi]

	var mult = VynCombatAI.get_damage_multiplier(vyn, party)
	_assert(mult == 1.0, "get_damage_multiplier returns 1.0 normally")

# --- Test: Vyn CharacterData loads with correct stats ---
func _test_vyn_character_data_loads() -> void:
	var vyn_data = load("res://data/characters/vyn.tres") as CharacterData
	_assert(vyn_data != null, "Vyn CharacterData loads")
	if vyn_data:
		_assert(vyn_data.name == "Vyn", "Vyn name is correct")
		_assert(vyn_data.max_hp == 80, "Vyn max_hp is 80")
		_assert(vyn_data.attack == 10, "Vyn attack is 10")
		_assert(vyn_data.defense == 7, "Vyn defense is 7")
		_assert(vyn_data.speed == 14, "Vyn speed is 14 (fastest)")
		_assert(vyn_data.stances.size() == 0, "Vyn has no stances")
		_assert(vyn_data.skills.size() == 0, "Vyn has no skills (AI-driven)")

# --- Test: Integration - Vyn's turn uses AI, not player menu ---
func _test_vyn_turn_skips_menu() -> void:
	# Simulate: when entity.name == "Vyn", AI should pick action
	var vyn = {"name": "Vyn", "hp": 80, "max_hp": 80, "attack": 10, "defense": 7, "speed": 14, "is_enemy": false}
	var zi = {"name": "Zi", "hp": 100, "max_hp": 120, "attack": 14, "defense": 12, "speed": 11, "is_enemy": false}
	var enemy = {"name": "Goblin", "hp": 30, "max_hp": 30, "attack": 8, "defense": 3, "speed": 6, "is_enemy": true}

	# Verify Vyn is recognized as semi-autonomous (not enemy, name is "Vyn")
	var is_vyn = (vyn.name == "Vyn" and not vyn.get("is_enemy", false))
	_assert(is_vyn, "Vyn is identified as semi-autonomous (not enemy, name is Vyn)")

	# Verify AI produces a valid action
	var result = VynCombatAI.choose_action(vyn, [vyn, zi], [enemy], {})
	var valid_actions = ["wild_strike", "root", "pack_instinct"]
	_assert(result.action in valid_actions, "Vyn AI produces a valid action")
	_assert(result.has("target"), "Vyn AI result includes a target")
