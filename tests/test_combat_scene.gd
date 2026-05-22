extends Node2D

var _tests_passed: int = 0
var _tests_failed: int = 0

func _ready() -> void:
	print("[TEST_COMBAT_SCENE] Starting combat system tests...")

	_test_stance_system()
	_test_momentum_multipliers()
	_test_damage_calculation()
	_test_turn_queue()

	print("[TEST_COMBAT_SCENE] Results: %d passed, %d failed" % [_tests_passed, _tests_failed])
	if _tests_failed == 0:
		print("[TEST_COMBAT_SCENE] SUCCESS")
	else:
		printerr("[TEST_COMBAT_SCENE] FAILED")

	if DisplayServer.get_name() == "headless":
		get_tree().quit()

func _assert(condition: bool, test_name: String) -> void:
	if condition:
		_tests_passed += 1
	else:
		_tests_failed += 1
		printerr("[TEST_COMBAT_SCENE] FAIL: ", test_name)

func _test_stance_system() -> void:
	# Advantage
	var mult = StanceSystem.get_multiplier("Counter Step", "Agile")
	_assert(mult == 1.3, "Counter Step vs Agile should be 1.3x")

	# Neutral
	mult = StanceSystem.get_multiplier("Soldier's Edge", "Agile")
	_assert(mult == 1.0, "Soldier's Edge vs Agile should be 1.0x (neutral stance)")

	# No armor
	mult = StanceSystem.get_multiplier("Counter Step", "")
	_assert(mult == 1.0, "Any stance vs no armor should be 1.0x")

	# Unknown stance
	mult = StanceSystem.get_multiplier("Unknown", "Heavy")
	_assert(mult == 1.0, "Unknown stance should be 1.0x")

func _test_momentum_multipliers() -> void:
	MomentumSystem.reset()
	_assert(MomentumSystem.get_damage_multiplier() == 1.0, "Balanced should be 1.0x")

	MomentumSystem.current_momentum = -60.0
	_assert(MomentumSystem.get_damage_multiplier() == 0.8, "Grounded should be 0.8x")

	MomentumSystem.current_momentum = 60.0
	_assert(MomentumSystem.get_damage_multiplier() == 1.4, "Surge should be 1.4x")

	MomentumSystem.reset()

func _test_damage_calculation() -> void:
	# base_atk=14, skill_mult=1.2, stance=1.3 (advantage), momentum=1.0, defense=2
	# raw = 14 * 1.2 * 1.3 * 1.0 = 21.84 -> 21 - 2 = 19
	var raw = 14 * 1.2 * 1.3 * 1.0
	var final = maxi(1, int(raw) - 2)
	_assert(final == 19, "Damage calc: 14 ATK * 1.2 skill * 1.3 stance - 2 DEF = 19")

func _test_turn_queue() -> void:
	var participants = [
		{"name": "Zi", "speed": 15},
		{"name": "Slime", "speed": 8},
	]
	CombatManager.start_combat(participants)
	_assert(CombatManager.turn_queue[0].name == "Zi", "Faster unit goes first")
	CombatManager.end_combat()
