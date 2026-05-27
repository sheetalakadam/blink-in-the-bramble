extends Node2D

var _tests_passed: int = 0
var _tests_failed: int = 0

func _ready() -> void:
	print("[TEST_AFFINITY_COMBOS] Starting affinity combo tests...")

	_test_record_action()
	_test_reset_clears_state()
	_test_zi_caelan_combo_triggers()
	_test_combo_does_not_trigger_low_affinity()
	_test_suri_zi_combo_triggers()
	_test_passive_caelan_lex_vs_spirits()
	_test_passive_no_bonus_without_pair()
	_test_check_combo_returns_inactive_no_combo()
	_test_rynn_lex_combo_triggers()
	_test_suri_vyn_combo_triggers()
	_test_integration_zi_caelan_damage_bonus()

	print("[TEST_AFFINITY_COMBOS] Results: %d passed, %d failed" % [_tests_passed, _tests_failed])
	if _tests_failed == 0:
		print("[TEST_AFFINITY_COMBOS] SUCCESS")
	else:
		printerr("[TEST_AFFINITY_COMBOS] FAILED")

	if DisplayServer.get_name() == "headless":
		get_tree().quit()

func _assert(condition: bool, test_name: String) -> void:
	if condition:
		_tests_passed += 1
	else:
		_tests_failed += 1
		printerr("[TEST_AFFINITY_COMBOS] FAIL: ", test_name)

# --- Tests ---

func _test_record_action() -> void:
	ComboSystem.reset()
	ComboSystem.record_action("Zi", "Read")
	_assert(ComboSystem._last_actions.get("Zi") == "Read", "record_action tracks Zi's Read")
	ComboSystem.record_action("Suri", "Setup Strike")
	_assert(ComboSystem._last_actions.get("Suri") == "Setup Strike", "record_action tracks Suri's Setup Strike")
	ComboSystem.reset()

func _test_reset_clears_state() -> void:
	ComboSystem.record_action("Zi", "Read")
	ComboSystem.reset()
	_assert(ComboSystem._last_actions.is_empty(), "reset clears _last_actions")

func _test_zi_caelan_combo_triggers() -> void:
	ComboSystem.reset()
	AffinityManager.reset()
	# Set affinity >= 50 for both Zi and Caelan
	AffinityManager.add_affinity("Zi", 50)
	AffinityManager.add_affinity("Caelan", 50)

	# Zi uses Read
	ComboSystem.record_action("Zi", "Read")

	# Caelan attacks next
	var attacker = {"name": "Caelan", "attack": 10, "hp": 50, "max_hp": 50}
	var next_actor = {"name": "Zi", "hp": 50, "max_hp": 50}
	var result = ComboSystem.check_combo(attacker, "Attack", next_actor, [])

	_assert(result.active == true, "Zi+Caelan combo activates after Read then Caelan attacks")
	_assert(result.type == "zi_caelan_read", "Combo type is zi_caelan_read")
	_assert(result.bonus == 0.5, "Combo bonus is +50%")
	_assert(result.message != "", "Combo has a message")

	AffinityManager.reset()
	ComboSystem.reset()

func _test_combo_does_not_trigger_low_affinity() -> void:
	ComboSystem.reset()
	AffinityManager.reset()
	# Affinity below 50
	AffinityManager.add_affinity("Zi", 30)
	AffinityManager.add_affinity("Caelan", 30)

	ComboSystem.record_action("Zi", "Read")

	var attacker = {"name": "Caelan", "attack": 10, "hp": 50, "max_hp": 50}
	var next_actor = {"name": "Zi", "hp": 50, "max_hp": 50}
	var result = ComboSystem.check_combo(attacker, "Attack", next_actor, [])

	_assert(result.active == false, "Combo does NOT trigger when affinity < 50")

	AffinityManager.reset()
	ComboSystem.reset()

func _test_suri_zi_combo_triggers() -> void:
	ComboSystem.reset()
	AffinityManager.reset()
	AffinityManager.add_affinity("Zi", 60)
	AffinityManager.add_affinity("Suri", 60)

	# Suri uses Setup Strike
	ComboSystem.record_action("Suri", "Setup Strike")

	# Zi attacks next
	var attacker = {"name": "Zi", "attack": 12, "hp": 50, "max_hp": 50}
	var next_actor = {"name": "Suri", "hp": 50, "max_hp": 50}
	var result = ComboSystem.check_combo(attacker, "Attack", next_actor, [])

	_assert(result.active == true, "Suri+Zi combo activates after Setup Strike then Zi attacks")
	_assert(result.type == "suri_zi_setup", "Combo type is suri_zi_setup")

	AffinityManager.reset()
	ComboSystem.reset()

func _test_passive_caelan_lex_vs_spirits() -> void:
	ComboSystem.reset()
	AffinityManager.reset()
	AffinityManager.add_affinity("Caelan", 55)
	AffinityManager.add_affinity("Lex", 55)

	var party_members = [
		{"name": "Caelan", "hp": 50, "max_hp": 50},
		{"name": "Lex", "hp": 40, "max_hp": 40},
	]
	var spirit_enemies = [
		{"name": "Wisp", "type": "Spirit", "hp": 20, "max_hp": 20, "is_enemy": true},
	]

	var bonus = ComboSystem.get_passive_bonus(party_members, spirit_enemies)
	_assert(bonus == 0.2, "Caelan+Lex passive gives +20% vs Spirit enemies")

	AffinityManager.reset()
	ComboSystem.reset()

func _test_passive_no_bonus_without_pair() -> void:
	ComboSystem.reset()
	AffinityManager.reset()
	AffinityManager.add_affinity("Caelan", 55)
	# Lex not in party

	var party_members = [
		{"name": "Caelan", "hp": 50, "max_hp": 50},
		{"name": "Zi", "hp": 50, "max_hp": 50},
	]
	var spirit_enemies = [
		{"name": "Wisp", "type": "Spirit", "hp": 20, "max_hp": 20, "is_enemy": true},
	]

	var bonus = ComboSystem.get_passive_bonus(party_members, spirit_enemies)
	_assert(bonus == 0.0, "No passive bonus without both Caelan and Lex in party")

	AffinityManager.reset()
	ComboSystem.reset()

func _test_check_combo_returns_inactive_no_combo() -> void:
	ComboSystem.reset()
	AffinityManager.reset()
	AffinityManager.add_affinity("Zi", 60)

	# No prior action recorded
	var attacker = {"name": "Zi", "attack": 12, "hp": 50, "max_hp": 50}
	var next_actor = {"name": "Caelan", "hp": 50, "max_hp": 50}
	var result = ComboSystem.check_combo(attacker, "Attack", next_actor, [])

	_assert(result.active == false, "check_combo returns inactive when no combo available")

	AffinityManager.reset()
	ComboSystem.reset()

func _test_rynn_lex_combo_triggers() -> void:
	ComboSystem.reset()
	AffinityManager.reset()
	AffinityManager.add_affinity("Rynn", 50)
	AffinityManager.add_affinity("Lex", 50)

	ComboSystem.record_action("Lex", "Field Notes")

	var attacker = {"name": "Rynn", "attack": 14, "hp": 50, "max_hp": 50}
	var next_actor = {"name": "Lex", "hp": 40, "max_hp": 40}
	var result = ComboSystem.check_combo(attacker, "Attack", next_actor, [])

	_assert(result.active == true, "Rynn+Lex combo activates after Field Notes then Rynn attacks")
	_assert(result.type == "rynn_lex_fieldnotes", "Combo type is rynn_lex_fieldnotes")

	AffinityManager.reset()
	ComboSystem.reset()

func _test_suri_vyn_combo_triggers() -> void:
	ComboSystem.reset()
	AffinityManager.reset()
	AffinityManager.add_affinity("Suri", 50)

	ComboSystem.record_action("Suri", "Stand Beside")

	# Vyn attacks next — Stand Beside was used for Vyn
	var attacker = {"name": "Vyn", "attack": 10, "hp": 50, "max_hp": 50}
	var next_actor = {"name": "Suri", "hp": 50, "max_hp": 50}
	var result = ComboSystem.check_combo(attacker, "Attack", next_actor, [])

	_assert(result.active == true, "Suri+Vyn combo activates after Stand Beside then Vyn acts")
	_assert(result.type == "suri_vyn_standbeside", "Combo type is suri_vyn_standbeside")

	AffinityManager.reset()
	ComboSystem.reset()

func _test_integration_zi_caelan_damage_bonus() -> void:
	ComboSystem.reset()
	AffinityManager.reset()
	AffinityManager.add_affinity("Zi", 50)
	AffinityManager.add_affinity("Caelan", 50)

	ComboSystem.record_action("Zi", "Read")

	var attacker = {"name": "Caelan", "attack": 20, "hp": 50, "max_hp": 50}
	var result = ComboSystem.check_combo(attacker, "Attack", {}, [])

	_assert(result.active == true, "Integration: combo detected")

	# Simulate damage with bonus applied
	var base_damage: int = attacker.attack
	var combo_mult: float = 1.0 + result.bonus
	var final_damage: int = int(base_damage * combo_mult)

	_assert(final_damage == 30, "Integration: 20 ATK * 1.5 combo = 30 damage")

	AffinityManager.reset()
	ComboSystem.reset()
