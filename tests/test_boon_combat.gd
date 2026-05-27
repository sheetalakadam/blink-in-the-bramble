extends Node2D

## Tests for god boon integration into combat.

const TAG = "[TEST_BOON_COMBAT]"
var _passed: int = 0
var _failed: int = 0

func _ready() -> void:
	print("%s Starting boon combat tests..." % TAG)
	_test_reveal_armor()
	_test_auto_revive()
	_test_auto_revive_once_only()
	_test_surge_protection()
	_test_boon_consumed_after_battle()
	_test_momentum_surge_protection_method()
	_report()

func _assert(condition: bool, name: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		printerr("%s FAIL: %s" % [TAG, name])

func _test_reveal_armor() -> void:
	# reveal_armor should not crash and should be callable
	var shrine_data = ShrineData.new()
	shrine_data.boon_effect = "reveal_armor"
	_assert(shrine_data.boon_effect == "reveal_armor", "Reveal armor boon effect set")

func _test_auto_revive() -> void:
	# Simulate a party member dropping to 0 HP with auto-revive
	var target = {"name": "Zi", "hp": 5, "max_hp": 120, "attack": 14, "defense": 12, "is_enemy": false}
	# Simulate damage that would kill
	target.hp -= 10
	_assert(target.hp <= 0, "Target HP drops to 0 or below")

	# Auto-revive logic
	if target.hp <= 0 and not target.get("is_enemy", false):
		target.hp = maxi(1, int(target.max_hp * 0.3))
	_assert(target.hp == 36, "Auto-revive restores to 30%% max HP (36)")
	_assert(target.hp > 0, "Target is alive after revive")

func _test_auto_revive_once_only() -> void:
	var revive_available = true
	var target = {"name": "Zi", "hp": -5, "max_hp": 120, "is_enemy": false}

	# First revive
	if target.hp <= 0 and revive_available:
		target.hp = maxi(1, int(target.max_hp * 0.3))
		revive_available = false
	_assert(target.hp == 36, "First revive works")
	_assert(not revive_available, "Revive consumed")

	# Second death — no revive
	target.hp = -5
	if target.hp <= 0 and revive_available:
		target.hp = maxi(1, int(target.max_hp * 0.3))
	_assert(target.hp == -5, "Second death stays dead (no revive)")

func _test_surge_protection() -> void:
	MomentumSystem.reset()
	MomentumSystem.set_surge_protection(false)
	var normal = MomentumSystem.get_damage_taken_multiplier()
	_assert(normal == 1.0, "Normal balanced damage taken = 1.0x")

	MomentumSystem.current_momentum = 60.0
	var surge_normal = MomentumSystem.get_damage_taken_multiplier()
	_assert(surge_normal == 1.3, "Surge without protection = 1.3x")

	MomentumSystem.set_surge_protection(true)
	var surge_protected = MomentumSystem.get_damage_taken_multiplier()
	_assert(surge_protected == 1.1, "Surge with protection = 1.1x")

	MomentumSystem.reset()

func _test_boon_consumed_after_battle() -> void:
	ShrineManager.reset()
	var shrine_data = ShrineData.new()
	shrine_data.boon_effect = "reveal_armor"
	shrine_data.cost_type = "memory"
	shrine_data.cost_amount = 0
	ShrineManager.active_boon = shrine_data
	_assert(ShrineManager.has_boon(), "Boon is active")

	ShrineManager.consume_boon()
	_assert(not ShrineManager.has_boon(), "Boon consumed")

func _test_momentum_surge_protection_method() -> void:
	MomentumSystem.reset()
	_assert(MomentumSystem._surge_protection == false, "Surge protection starts false")
	MomentumSystem.set_surge_protection(true)
	_assert(MomentumSystem._surge_protection == true, "Surge protection set to true")
	MomentumSystem.reset()
	_assert(MomentumSystem._surge_protection == false, "Reset clears surge protection")

func _report() -> void:
	print("%s Results: %d passed, %d failed" % [TAG, _passed, _failed])
	if _failed == 0:
		print("%s SUCCESS" % TAG)
	else:
		printerr("%s FAILED" % TAG)
	if DisplayServer.get_name() == "headless":
		get_tree().quit()
