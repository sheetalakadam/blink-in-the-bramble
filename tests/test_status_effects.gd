extends Node2D

## Tests for the status effects system.
## Run with: godot --headless --path . tests/test_status_effects.tscn

const TAG = "[TEST_STATUS_EFFECTS]"

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	print("%s Starting status effects tests..." % TAG)
	_test_apply_effect_adds_to_entity()
	_test_poison_deals_damage_each_turn()
	_test_rooted_prevents_acting()
	_test_marked_gives_bonus_then_consumed()
	_test_analyzed_sets_permanent_flag()
	_test_effects_expire_after_duration()
	_test_process_turn_end_decrements_duration()
	_test_has_effect_returns_correct_state()
	_test_reset_clears_everything()
	_test_integration_ereivyn_toxin_poison_ticks()
	_report()


func _assert(condition: bool, name: String) -> void:
	if condition:
		_passed += 1
		print("%s PASS: %s" % [TAG, name])
	else:
		_failed += 1
		printerr("%s FAIL: %s" % [TAG, name])


## --- Test 1: apply_effect adds effect to entity ---
func _test_apply_effect_adds_to_entity() -> void:
	StatusEffectSystem.reset()
	var entity := {"name": "Slime", "hp": 20, "max_hp": 20, "attack": 10}
	StatusEffectSystem.apply_effect(entity, "poison", 3, 8)
	_assert(StatusEffectSystem.has_effect(entity, "poison"), "apply_effect: poison is present")
	_assert(not StatusEffectSystem.has_effect(entity, "marked"), "apply_effect: marked is not present")
	StatusEffectSystem.reset()


## --- Test 2: poison deals damage each turn ---
func _test_poison_deals_damage_each_turn() -> void:
	StatusEffectSystem.reset()
	var entity := {"name": "Slime", "hp": 100, "max_hp": 100, "attack": 10}
	StatusEffectSystem.apply_effect(entity, "poison", 3, 20)
	# Poison deals 15% of source_attack (20) = 3 damage per tick
	var msgs = StatusEffectSystem.process_turn_start(entity)
	_assert(entity.hp == 97, "poison: deals 3 damage (15%% of 20 attack)")
	_assert(msgs.size() > 0, "poison: returns log message")
	_assert("poison" in msgs[0].to_lower(), "poison: log mentions poison")
	StatusEffectSystem.reset()


## --- Test 3: rooted prevents entity from acting ---
func _test_rooted_prevents_acting() -> void:
	StatusEffectSystem.reset()
	var entity := {"name": "Slime", "hp": 20, "max_hp": 20, "attack": 10}
	StatusEffectSystem.apply_effect(entity, "rooted", 2, 0)
	var msgs = StatusEffectSystem.process_turn_start(entity)
	_assert(StatusEffectSystem.has_effect(entity, "rooted"), "rooted: effect is present")
	var found_skip = false
	for msg in msgs:
		if "rooted" in msg.to_lower() or "cannot" in msg.to_lower():
			found_skip = true
	_assert(found_skip, "rooted: log indicates skip turn")
	StatusEffectSystem.reset()


## --- Test 4: marked gives +30% bonus then is consumed ---
func _test_marked_gives_bonus_then_consumed() -> void:
	StatusEffectSystem.reset()
	var target := {"name": "Slime", "hp": 100, "max_hp": 100, "attack": 10}
	StatusEffectSystem.apply_effect(target, "marked", 2, 0)
	_assert(StatusEffectSystem.has_effect(target, "marked"), "marked: effect is present before hit")

	var bonus = StatusEffectSystem.consume_marked(target)
	_assert(is_equal_approx(bonus, 0.3), "marked: returns 0.3 bonus multiplier")
	_assert(not StatusEffectSystem.has_effect(target, "marked"), "marked: consumed after hit")
	StatusEffectSystem.reset()


## --- Test 5: analyzed sets permanent flag ---
func _test_analyzed_sets_permanent_flag() -> void:
	StatusEffectSystem.reset()
	var entity := {"name": "Slime", "hp": 20, "max_hp": 20, "attack": 10}
	StatusEffectSystem.apply_effect(entity, "analyzed", 0, 0)
	_assert(StatusEffectSystem.has_effect(entity, "analyzed"), "analyzed: flag is set")

	# Process multiple turn ends - should not expire
	StatusEffectSystem.process_turn_end(entity)
	StatusEffectSystem.process_turn_end(entity)
	StatusEffectSystem.process_turn_end(entity)
	_assert(StatusEffectSystem.has_effect(entity, "analyzed"), "analyzed: persists after multiple turns")
	StatusEffectSystem.reset()


## --- Test 6: effects expire after duration ---
func _test_effects_expire_after_duration() -> void:
	StatusEffectSystem.reset()
	var entity := {"name": "Slime", "hp": 100, "max_hp": 100, "attack": 10}
	StatusEffectSystem.apply_effect(entity, "poison", 2, 10)

	# Turn 1
	StatusEffectSystem.process_turn_start(entity)
	StatusEffectSystem.process_turn_end(entity)
	_assert(StatusEffectSystem.has_effect(entity, "poison"), "expire: poison still active after 1 turn")

	# Turn 2
	StatusEffectSystem.process_turn_start(entity)
	StatusEffectSystem.process_turn_end(entity)
	_assert(not StatusEffectSystem.has_effect(entity, "poison"), "expire: poison expired after 2 turns")
	StatusEffectSystem.reset()


## --- Test 7: process_turn_end decrements duration ---
func _test_process_turn_end_decrements_duration() -> void:
	StatusEffectSystem.reset()
	var entity := {"name": "Slime", "hp": 100, "max_hp": 100, "attack": 10}
	StatusEffectSystem.apply_effect(entity, "poison", 3, 10)

	StatusEffectSystem.process_turn_end(entity)
	_assert(StatusEffectSystem.has_effect(entity, "poison"), "decrement: poison still active after 1 decrement")

	StatusEffectSystem.process_turn_end(entity)
	_assert(StatusEffectSystem.has_effect(entity, "poison"), "decrement: poison still active after 2 decrements")

	StatusEffectSystem.process_turn_end(entity)
	_assert(not StatusEffectSystem.has_effect(entity, "poison"), "decrement: poison expired after 3 decrements")
	StatusEffectSystem.reset()


## --- Test 8: has_effect returns correct state ---
func _test_has_effect_returns_correct_state() -> void:
	StatusEffectSystem.reset()
	var entity := {"name": "Slime", "hp": 20, "max_hp": 20, "attack": 10}

	_assert(not StatusEffectSystem.has_effect(entity, "poison"), "has_effect: false when no effects")

	StatusEffectSystem.apply_effect(entity, "poison", 3, 10)
	_assert(StatusEffectSystem.has_effect(entity, "poison"), "has_effect: true after applying")

	StatusEffectSystem.clear_effects(entity)
	_assert(not StatusEffectSystem.has_effect(entity, "poison"), "has_effect: false after clearing")
	StatusEffectSystem.reset()


## --- Test 9: reset clears everything ---
func _test_reset_clears_everything() -> void:
	StatusEffectSystem.reset()
	var entity_a := {"name": "Slime", "hp": 20, "max_hp": 20, "attack": 10}
	var entity_b := {"name": "Wolf", "hp": 30, "max_hp": 30, "attack": 12}
	StatusEffectSystem.apply_effect(entity_a, "poison", 3, 10)
	StatusEffectSystem.apply_effect(entity_b, "rooted", 2, 0)

	StatusEffectSystem.reset()
	_assert(not StatusEffectSystem.has_effect(entity_a, "poison"), "reset: entity_a poison cleared")
	_assert(not StatusEffectSystem.has_effect(entity_b, "rooted"), "reset: entity_b rooted cleared")


## --- Test 10: Integration - Ereivyn Toxin applies poison that ticks for 3 turns ---
func _test_integration_ereivyn_toxin_poison_ticks() -> void:
	StatusEffectSystem.reset()
	var target := {"name": "Slime", "hp": 100, "max_hp": 100, "attack": 10, "is_enemy": true}
	var attacker_attack := 16

	# Simulate Ereivyn Toxin: status_effect = "poison", effect_chance = 1.0
	# Apply poison with source_attack = 16 -> 15% of 16 = 2.4 -> 2 damage per tick
	StatusEffectSystem.apply_effect(target, "poison", 3, attacker_attack)

	var total_damage := 0
	# Tick 3 turns
	for i in range(3):
		var hp_before = target.hp
		StatusEffectSystem.process_turn_start(target)
		total_damage += hp_before - target.hp
		StatusEffectSystem.process_turn_end(target)

	_assert(total_damage == 6, "integration: poison ticked 3 times for 2 dmg each = 6 total (got %d)" % total_damage)
	_assert(not StatusEffectSystem.has_effect(target, "poison"), "integration: poison expired after 3 turns")
	_assert(target.hp == 94, "integration: target HP is 94 after 6 total damage (got %d)" % target.hp)
	StatusEffectSystem.reset()


func _report() -> void:
	print("%s Results: %d passed, %d failed" % [TAG, _passed, _failed])
	if _failed == 0:
		print("%s ALL TESTS PASSED" % TAG)
	else:
		printerr("%s SOME TESTS FAILED" % TAG)
	if DisplayServer.get_name() == "headless":
		get_tree().quit()
