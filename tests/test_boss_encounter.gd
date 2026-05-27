extends SceneTree

## Test script for boss encounter system.
## Verifies: BossData loading, phase transitions, armor changes, telegraph, victory milestone.
## Run with: godot --headless --path . -s tests/test_boss_encounter.gd

const TAG = "[TEST_BOSS_ENCOUNTER]"

var _tests_passed: int = 0
var _tests_failed: int = 0


func _init() -> void:
	root.ready.connect(_run_tests)


func _run_tests() -> void:
	print(TAG, " Starting tests...")

	_test_boss_data_resource_loads()
	_test_boss_data_phases_correct()
	_test_boss_controller_initial_phase()
	_test_phase_transition_at_hp_threshold()
	_test_armor_type_changes_on_phase_transition()
	_test_attack_defense_update_on_phase_change()
	_test_boss_telegraph_shows_current_phase_attack()
	_test_victory_grants_milestone()
	_test_integration_full_boss_fight()

	_print_results()
	quit()


# --- Test: BossData resource loads with correct phases ---

func _test_boss_data_resource_loads() -> void:
	var boss_data = load("res://scripts/combat/BossData.gd")
	if boss_data == null:
		_fail("Could not load BossData.gd script")
		return

	var boss = BossData.new()
	boss.boss_name = "Test Boss"
	boss.total_hp = 100
	boss.speed = 5
	boss.phases = [
		{"armor_type": "Heavy", "hp_threshold": 1.0, "attack": 10, "defense": 8, "attack_name": "Slam"},
		{"armor_type": "Agile", "hp_threshold": 0.5, "attack": 14, "defense": 4, "attack_name": "Slash"},
	]

	_assert(boss.boss_name == "Test Boss", "BossData boss_name is set")
	_assert(boss.total_hp == 100, "BossData total_hp is set")
	_assert(boss.speed == 5, "BossData speed is set")
	_assert(boss.phases.size() == 2, "BossData has 2 phases")
	_pass("BossData resource loads and holds data")


func _test_boss_data_phases_correct() -> void:
	var boss = _create_sentinel_data()
	_assert(boss.phases[0].armor_type == "Heavy", "Phase 1 armor is Heavy")
	_assert(boss.phases[0].attack == 10, "Phase 1 attack is 10")
	_assert(boss.phases[0].defense == 8, "Phase 1 defense is 8")
	_assert(boss.phases[0].attack_name == "Shield Bash", "Phase 1 attack name is Shield Bash")
	_assert(boss.phases[1].armor_type == "Agile", "Phase 2 armor is Agile")
	_assert(boss.phases[1].attack == 14, "Phase 2 attack is 14")
	_assert(boss.phases[1].defense == 4, "Phase 2 defense is 4")
	_assert(boss.phases[1].attack_name == "Frenzy Slash", "Phase 2 attack name is Frenzy Slash")
	_pass("BossData phases contain correct data")


# --- Test: BossController initial phase ---

func _test_boss_controller_initial_phase() -> void:
	var boss_data = _create_sentinel_data()
	var controller = BossController.new()

	var enemy_dict = controller.create_enemy_dict(boss_data)

	_assert(enemy_dict.name == "Corrupted Sentinel", "Enemy dict has boss name")
	_assert(enemy_dict.hp == 80, "Enemy dict HP equals total_hp")
	_assert(enemy_dict.max_hp == 80, "Enemy dict max_hp equals total_hp")
	_assert(enemy_dict.armor_type == "Heavy", "Initial armor_type is Heavy (phase 1)")
	_assert(enemy_dict.attack == 10, "Initial attack is 10 (phase 1)")
	_assert(enemy_dict.defense == 8, "Initial defense is 8 (phase 1)")
	_assert(enemy_dict.is_enemy == true, "Enemy dict is_enemy flag set")
	_assert(enemy_dict.has("phases"), "Enemy dict carries phases array")
	_assert(enemy_dict.has("boss_data"), "Enemy dict carries boss_data reference")
	_pass("BossController creates correct initial enemy dict")


# --- Test: Phase transition triggers at HP threshold ---

func _test_phase_transition_at_hp_threshold() -> void:
	var boss_data = _create_sentinel_data()
	var controller = BossController.new()
	var enemy_dict = controller.create_enemy_dict(boss_data)

	# HP is 80, threshold for phase 2 is 0.5 => 40 HP
	# Still in phase 1 at 41 HP
	enemy_dict.hp = 41
	var changed = controller.check_phase_transition(enemy_dict)
	_assert(changed == false, "No phase transition at 41/80 HP (above 50%%)")

	# Cross threshold at 40 HP
	enemy_dict.hp = 40
	changed = controller.check_phase_transition(enemy_dict)
	_assert(changed == true, "Phase transition triggered at 40/80 HP (exactly 50%%)")

	# Should now be in phase 2 (index 1)
	_assert(enemy_dict._current_phase_index == 1, "Phase index updated to 1")
	_pass("Phase transition triggers correctly at HP threshold")


# --- Test: Armor type changes on phase transition ---

func _test_armor_type_changes_on_phase_transition() -> void:
	var boss_data = _create_sentinel_data()
	var controller = BossController.new()
	var enemy_dict = controller.create_enemy_dict(boss_data)

	_assert(enemy_dict.armor_type == "Heavy", "Armor is Heavy before transition")

	enemy_dict.hp = 39
	controller.check_phase_transition(enemy_dict)

	_assert(enemy_dict.armor_type == "Agile", "Armor changed to Agile after transition")
	_pass("Armor type changes on phase transition")


# --- Test: Attack/defense update on phase change ---

func _test_attack_defense_update_on_phase_change() -> void:
	var boss_data = _create_sentinel_data()
	var controller = BossController.new()
	var enemy_dict = controller.create_enemy_dict(boss_data)

	_assert(enemy_dict.attack == 10, "Attack is 10 before transition")
	_assert(enemy_dict.defense == 8, "Defense is 8 before transition")

	enemy_dict.hp = 30
	controller.check_phase_transition(enemy_dict)

	_assert(enemy_dict.attack == 14, "Attack updated to 14 after phase change")
	_assert(enemy_dict.defense == 4, "Defense updated to 4 after phase change")
	_pass("Attack/defense update on phase change")


# --- Test: Boss telegraph shows current phase attack name ---

func _test_boss_telegraph_shows_current_phase_attack() -> void:
	var boss_data = _create_sentinel_data()
	var controller = BossController.new()
	var enemy_dict = controller.create_enemy_dict(boss_data)

	var telegraph = controller.get_boss_telegraph(enemy_dict)
	_assert(telegraph == "Corrupted Sentinel: preparing Shield Bash", "Phase 1 telegraph shows Shield Bash")

	enemy_dict.hp = 35
	controller.check_phase_transition(enemy_dict)
	telegraph = controller.get_boss_telegraph(enemy_dict)
	_assert(telegraph == "Corrupted Sentinel: preparing Frenzy Slash", "Phase 2 telegraph shows Frenzy Slash")
	_pass("Boss telegraph shows current phase attack name")


# --- Test: Victory grants milestone ---

func _test_victory_grants_milestone() -> void:
	var boss_data = _create_sentinel_data()
	var controller = BossController.new()

	# Reset PartyManager state for clean test
	PartyManager.reset()

	controller.on_boss_defeated(boss_data)

	var milestones = PartyManager.get_granted_milestones()
	_assert("corrupted_sentinel_defeated" in milestones, "Milestone 'corrupted_sentinel_defeated' granted on boss defeat")
	_pass("Victory grants milestone")


# --- Test: Integration — simulate full boss fight across both phases ---

func _test_integration_full_boss_fight() -> void:
	var boss_data = _create_sentinel_data()
	var controller = BossController.new()
	var enemy_dict = controller.create_enemy_dict(boss_data)

	# Simulate combat: player deals damage over multiple "turns"
	var log_messages: Array[String] = []
	var phase_transitions: int = 0

	# Phase 1: Heavy armor, attack 10, defense 8
	_assert(enemy_dict.armor_type == "Heavy", "Integration: starts in Heavy armor")

	# Simulate a series of attacks bringing HP from 80 down
	var damage_sequence = [15, 15, 12]  # Total 42 damage, HP goes to 38
	for dmg in damage_sequence:
		enemy_dict.hp -= dmg
		if controller.check_phase_transition(enemy_dict):
			phase_transitions += 1
			log_messages.append("Phase transition at HP %d" % enemy_dict.hp)

	_assert(phase_transitions == 1, "Integration: exactly 1 phase transition after crossing 50%% (got %d)" % phase_transitions)
	_assert(enemy_dict.armor_type == "Agile", "Integration: armor changed to Agile in phase 2")
	_assert(enemy_dict.attack == 14, "Integration: attack is 14 in phase 2")
	_assert(enemy_dict.defense == 4, "Integration: defense is 4 in phase 2")

	# Phase 2: continue dealing damage
	var more_damage = [20, 20]  # HP goes to -2
	for dmg in more_damage:
		enemy_dict.hp -= dmg
		if controller.check_phase_transition(enemy_dict):
			phase_transitions += 1

	_assert(phase_transitions == 1, "Integration: no extra transitions after final phase")
	_assert(enemy_dict.hp <= 0, "Integration: boss is defeated (HP <= 0)")

	# Grant milestone on defeat
	PartyManager.reset()
	controller.on_boss_defeated(boss_data)
	var milestones = PartyManager.get_granted_milestones()
	_assert("corrupted_sentinel_defeated" in milestones, "Integration: milestone granted after boss defeat")

	_pass("Integration: full boss fight across both phases works correctly")


# --- Helpers ---

func _create_sentinel_data() -> BossData:
	var boss = BossData.new()
	boss.boss_name = "Corrupted Sentinel"
	boss.total_hp = 80
	boss.speed = 7
	boss.phases = [
		{"armor_type": "Heavy", "hp_threshold": 1.0, "attack": 10, "defense": 8, "attack_name": "Shield Bash"},
		{"armor_type": "Agile", "hp_threshold": 0.5, "attack": 14, "defense": 4, "attack_name": "Frenzy Slash"},
	]
	boss.dialogue_on_phase_change = ""
	return boss


func _assert(condition: bool, msg: String) -> void:
	if condition:
		_tests_passed += 1
		print(TAG, " PASS: ", msg)
	else:
		_tests_failed += 1
		print(TAG, " FAIL: ", msg)


func _pass(msg: String) -> void:
	print(TAG, " -- ", msg)


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
