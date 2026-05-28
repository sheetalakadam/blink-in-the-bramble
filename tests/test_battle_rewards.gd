extends Node2D

## Tests for BattleRewards system: XP calculation, affinity gains, loot drops, level-up detection
## Run with: godot --headless --path . tests/test_battle_rewards.tscn

const TAG = "[TEST_BATTLE_REWARDS]"

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	print("%s Starting battle rewards tests..." % TAG)

	# XP calculation tests
	_test_xp_normal_enemies()
	_test_xp_boss_enemy()
	_test_xp_spirit_enemy()
	_test_xp_mixed_enemies()

	# Affinity gain tests
	_test_affinity_fought_together_two_members()
	_test_affinity_fought_together_three_members()
	_test_affinity_combo_bonus()

	# Loot tests
	_test_loot_from_enemy_drops()
	_test_loot_empty_drops()
	_test_loot_multiple_enemies()

	# Level-up detection tests
	_test_level_up_detection()
	_test_no_level_up_same_tier()
	_test_level_for_xp_thresholds()

	_report()


func _assert(condition: bool, name: String) -> void:
	if condition:
		_passed += 1
		print("%s PASS: %s" % [TAG, name])
	else:
		_failed += 1
		printerr("%s FAIL: %s" % [TAG, name])


# --- XP calculation tests ---

func _test_xp_normal_enemies() -> void:
	var party: Array[Dictionary] = [
		{"name": "Vyn", "hp": 50, "max_hp": 50, "attack": 10},
	]
	var enemies: Array[Dictionary] = [
		{"name": "Slime", "hp": 0, "max_hp": 20, "is_enemy": true},
		{"name": "Goblin", "hp": 0, "max_hp": 15, "is_enemy": true},
	]

	# Reset combo state so combo detection doesn't interfere
	ComboSystem.reset()

	var rewards = BattleRewards.calculate_rewards(party, enemies)
	_assert(rewards.milestone_xp == 20, "Two normal enemies give 20 XP (got %d)" % rewards.milestone_xp)


func _test_xp_boss_enemy() -> void:
	var party: Array[Dictionary] = [
		{"name": "Vyn", "hp": 50, "max_hp": 50, "attack": 10},
	]
	var enemies: Array[Dictionary] = [
		{"name": "Thornlord", "hp": 0, "max_hp": 100, "is_enemy": true, "is_boss": true},
	]

	ComboSystem.reset()
	var rewards = BattleRewards.calculate_rewards(party, enemies)
	_assert(rewards.milestone_xp == 50, "Boss enemy gives 50 XP (got %d)" % rewards.milestone_xp)


func _test_xp_spirit_enemy() -> void:
	var party: Array[Dictionary] = [
		{"name": "Vyn", "hp": 50, "max_hp": 50, "attack": 10},
	]
	var enemies: Array[Dictionary] = [
		{"name": "Wisp", "hp": 0, "max_hp": 15, "is_enemy": true, "type": "Spirit"},
	]

	ComboSystem.reset()
	var rewards = BattleRewards.calculate_rewards(party, enemies)
	_assert(rewards.milestone_xp == 15, "Spirit enemy gives 15 XP (got %d)" % rewards.milestone_xp)


func _test_xp_mixed_enemies() -> void:
	var party: Array[Dictionary] = [
		{"name": "Vyn", "hp": 50, "max_hp": 50, "attack": 10},
	]
	var enemies: Array[Dictionary] = [
		{"name": "Slime", "hp": 0, "max_hp": 20, "is_enemy": true},
		{"name": "Wisp", "hp": 0, "max_hp": 15, "is_enemy": true, "type": "Spirit"},
		{"name": "Thornlord", "hp": 0, "max_hp": 100, "is_enemy": true, "is_boss": true},
	]

	ComboSystem.reset()
	var rewards = BattleRewards.calculate_rewards(party, enemies)
	# 10 (normal) + 15 (spirit) + 50 (boss) = 75
	_assert(rewards.milestone_xp == 75, "Mixed enemies give 75 XP (got %d)" % rewards.milestone_xp)


# --- Affinity gain tests ---

func _test_affinity_fought_together_two_members() -> void:
	var party: Array[Dictionary] = [
		{"name": "Vyn", "hp": 50, "max_hp": 50, "attack": 10},
		{"name": "Caelan", "hp": 40, "max_hp": 40, "attack": 12},
	]
	var enemies: Array[Dictionary] = [
		{"name": "Slime", "hp": 0, "max_hp": 20, "is_enemy": true},
	]

	ComboSystem.reset()
	var rewards = BattleRewards.calculate_rewards(party, enemies)
	var gains: Dictionary = rewards.affinity_gains
	_assert(gains.get("Vyn", 0) == 5, "Vyn gets +5 affinity for fighting with Caelan (got %d)" % gains.get("Vyn", 0))
	_assert(gains.get("Caelan", 0) == 5, "Caelan gets +5 affinity for fighting with Vyn (got %d)" % gains.get("Caelan", 0))


func _test_affinity_fought_together_three_members() -> void:
	var party: Array[Dictionary] = [
		{"name": "Vyn", "hp": 50, "max_hp": 50, "attack": 10},
		{"name": "Caelan", "hp": 40, "max_hp": 40, "attack": 12},
		{"name": "Zi", "hp": 35, "max_hp": 35, "attack": 14},
	]
	var enemies: Array[Dictionary] = [
		{"name": "Slime", "hp": 0, "max_hp": 20, "is_enemy": true},
	]

	ComboSystem.reset()
	var rewards = BattleRewards.calculate_rewards(party, enemies)
	var gains: Dictionary = rewards.affinity_gains
	# Each member pairs with 2 others: 2 * 5 = 10
	_assert(gains.get("Vyn", 0) == 10, "Vyn gets +10 affinity with 3-member party (got %d)" % gains.get("Vyn", 0))
	_assert(gains.get("Caelan", 0) == 10, "Caelan gets +10 affinity with 3-member party (got %d)" % gains.get("Caelan", 0))
	_assert(gains.get("Zi", 0) == 10, "Zi gets +10 affinity with 3-member party (got %d)" % gains.get("Zi", 0))


func _test_affinity_combo_bonus() -> void:
	var party: Array[Dictionary] = [
		{"name": "Zi", "hp": 35, "max_hp": 35, "attack": 14},
		{"name": "Caelan", "hp": 40, "max_hp": 40, "attack": 12},
	]
	var enemies: Array[Dictionary] = [
		{"name": "Slime", "hp": 0, "max_hp": 20, "is_enemy": true},
	]

	# Simulate a Zi+Caelan combo by recording Zi's Read action
	ComboSystem.reset()
	ComboSystem.record_action("Zi", "Read")

	var rewards = BattleRewards.calculate_rewards(party, enemies)
	var gains: Dictionary = rewards.affinity_gains
	# 5 (fought together) + 10 (combo bonus) = 15
	_assert(gains.get("Zi", 0) == 15, "Zi gets +15 affinity with combo bonus (got %d)" % gains.get("Zi", 0))
	_assert(gains.get("Caelan", 0) == 15, "Caelan gets +15 affinity with combo bonus (got %d)" % gains.get("Caelan", 0))

	ComboSystem.reset()


# --- Loot tests ---

func _test_loot_from_enemy_drops() -> void:
	var party: Array[Dictionary] = [
		{"name": "Vyn", "hp": 50, "max_hp": 50, "attack": 10},
	]
	var enemies: Array[Dictionary] = [
		{"name": "Slime", "hp": 0, "max_hp": 20, "is_enemy": true, "drops": ["res://data/items/slime_gel.tres"]},
	]

	ComboSystem.reset()
	var rewards = BattleRewards.calculate_rewards(party, enemies)
	_assert(rewards.loot.size() == 1, "One loot item from enemy drop (got %d)" % rewards.loot.size())
	if rewards.loot.size() > 0:
		_assert(rewards.loot[0] == "res://data/items/slime_gel.tres", "Correct loot path")


func _test_loot_empty_drops() -> void:
	var party: Array[Dictionary] = [
		{"name": "Vyn", "hp": 50, "max_hp": 50, "attack": 10},
	]
	var enemies: Array[Dictionary] = [
		{"name": "Slime", "hp": 0, "max_hp": 20, "is_enemy": true},
	]

	ComboSystem.reset()
	var rewards = BattleRewards.calculate_rewards(party, enemies)
	_assert(rewards.loot.size() == 0, "No loot when enemy has no drops")


func _test_loot_multiple_enemies() -> void:
	var party: Array[Dictionary] = [
		{"name": "Vyn", "hp": 50, "max_hp": 50, "attack": 10},
	]
	var enemies: Array[Dictionary] = [
		{"name": "Slime", "hp": 0, "max_hp": 20, "is_enemy": true, "drops": ["res://data/items/slime_gel.tres"]},
		{"name": "Wolf", "hp": 0, "max_hp": 25, "is_enemy": true, "drops": ["res://data/items/wolf_pelt.tres", "res://data/items/wolf_fang.tres"]},
	]

	ComboSystem.reset()
	var rewards = BattleRewards.calculate_rewards(party, enemies)
	_assert(rewards.loot.size() == 3, "Three loot items from two enemies (got %d)" % rewards.loot.size())


# --- Level-up detection tests ---

func _test_level_up_detection() -> void:
	# 0 -> 25 crosses the level 2 threshold
	_assert(BattleRewards.check_level_up(0, 25), "0 to 25 XP triggers level up")
	# 25 -> 60 crosses the level 3 threshold
	_assert(BattleRewards.check_level_up(25, 60), "25 to 60 XP triggers level up")
	# 60 -> 120 crosses the level 4 threshold
	_assert(BattleRewards.check_level_up(60, 120), "60 to 120 XP triggers level up")
	# 120 -> 200 crosses the level 5 threshold
	_assert(BattleRewards.check_level_up(120, 200), "120 to 200 XP triggers level up")


func _test_no_level_up_same_tier() -> void:
	# 10 -> 20 stays at level 1
	_assert(not BattleRewards.check_level_up(10, 20), "10 to 20 XP does not trigger level up")
	# 30 -> 50 stays at level 2
	_assert(not BattleRewards.check_level_up(30, 50), "30 to 50 XP does not trigger level up")


func _test_level_for_xp_thresholds() -> void:
	_assert(BattleRewards.get_level_for_xp(0) == 1, "0 XP is level 1")
	_assert(BattleRewards.get_level_for_xp(24) == 1, "24 XP is level 1")
	_assert(BattleRewards.get_level_for_xp(25) == 2, "25 XP is level 2")
	_assert(BattleRewards.get_level_for_xp(59) == 2, "59 XP is level 2")
	_assert(BattleRewards.get_level_for_xp(60) == 3, "60 XP is level 3")
	_assert(BattleRewards.get_level_for_xp(119) == 3, "119 XP is level 3")
	_assert(BattleRewards.get_level_for_xp(120) == 4, "120 XP is level 4")
	_assert(BattleRewards.get_level_for_xp(199) == 4, "199 XP is level 4")
	_assert(BattleRewards.get_level_for_xp(200) == 5, "200 XP is level 5")
	_assert(BattleRewards.get_level_for_xp(500) == 5, "500 XP is level 5")


func _report() -> void:
	print("%s Results: %d passed, %d failed" % [TAG, _passed, _failed])
	if _failed == 0:
		print("%s SUCCESS" % TAG)
	else:
		printerr("%s FAILED" % TAG)
	if DisplayServer.get_name() == "headless":
		get_tree().quit()
