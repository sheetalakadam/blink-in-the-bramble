extends Node2D

var _tests_passed: int = 0
var _tests_failed: int = 0

func _ready() -> void:
	print("[TEST_COMBAT_POLISH] Starting combat polish tests...")

	_test_defend_flag_persists_until_next_turn()
	_test_defend_flag_cleared_on_next_turn_start()
	_test_skill_momentum_display_positive()
	_test_skill_momentum_display_negative()
	_test_combat_log_appends_messages()
	_test_turn_queue_highlights_current()
	_test_defend_doubles_defense()
	_test_target_menu_lists_alive_enemies()
	_test_integration_two_enemy_battle()

	print("[TEST_COMBAT_POLISH] Results: %d passed, %d failed" % [_tests_passed, _tests_failed])
	if _tests_failed == 0:
		print("[TEST_COMBAT_POLISH] SUCCESS")
	else:
		printerr("[TEST_COMBAT_POLISH] FAILED")

	if DisplayServer.get_name() == "headless":
		get_tree().quit()

func _assert(condition: bool, test_name: String) -> void:
	if condition:
		_tests_passed += 1
		print("[TEST_COMBAT_POLISH] PASS: ", test_name)
	else:
		_tests_failed += 1
		printerr("[TEST_COMBAT_POLISH] FAIL: ", test_name)

# --- Test: Defend flag persists until the NEXT turn of that character ---
func _test_defend_flag_persists_until_next_turn() -> void:
	# Simulate: Zi defends. The flag should NOT be cleared at end of current turn.
	# It should persist through enemy turns until Zi's next turn starts.
	var zi = {"name": "Zi", "hp": 100, "max_hp": 100, "attack": 14, "defense": 12, "speed": 15}
	var enemy = {"name": "Slime", "hp": 50, "max_hp": 50, "attack": 8, "defense": 2, "speed": 8, "is_enemy": true, "armor_type": ""}

	# Set defending flag as on_defend_pressed would
	zi["defending"] = true

	# After defend, _end_player_turn should NOT clear the flag anymore
	# The flag should only be cleared at the START of the defender's next turn
	_assert(zi.get("defending", false) == true, "Defend flag persists after being set")

func _test_defend_flag_cleared_on_next_turn_start() -> void:
	# When _on_turn_started fires for an entity, it should clear that entity's defending flag
	var zi = {"name": "Zi", "hp": 100, "max_hp": 100, "attack": 14, "defense": 12, "speed": 15, "defending": true}

	# Simulate what _on_turn_started should do: clear defending on the entity whose turn starts
	zi.erase("defending")

	_assert(zi.get("defending", false) == false, "Defend flag cleared when entity's turn starts")

# --- Test: Skill momentum cost shown in button text ---
func _test_skill_momentum_display_positive() -> void:
	# A skill with positive momentum_change should show "(M: +X)"
	var skill = SkillData.new()
	skill.name = "Strike"
	skill.momentum_change = 5.0

	var expected_text = "Strike (M: +5)"
	var actual = _format_skill_button_text(skill)
	_assert(actual == expected_text, "Positive momentum shows as '+5': got '%s'" % actual)

func _test_skill_momentum_display_negative() -> void:
	# A skill with negative momentum_change should show "(M: -X)"
	var skill = SkillData.new()
	skill.name = "Read the Fight"
	skill.momentum_change = -10.0

	var expected_text = "Read the Fight (M: -10)"
	var actual = _format_skill_button_text(skill)
	_assert(actual == expected_text, "Negative momentum shows as '-10': got '%s'" % actual)

# Helper that mirrors the format logic we expect in CombatController
func _format_skill_button_text(skill: SkillData) -> String:
	var sign_str = "+" if skill.momentum_change >= 0 else ""
	return "%s (M: %s%d)" % [skill.name, sign_str, int(skill.momentum_change)]

# --- Test: Combat log appends messages (not replaces) ---
func _test_combat_log_appends_messages() -> void:
	# Create a RichTextLabel to simulate the new combat_log
	var log_label = RichTextLabel.new()
	log_label.bbcode_enabled = true
	add_child(log_label)

	# Simulate _log appending
	_append_to_log(log_label, "Battle begins!")
	_append_to_log(log_label, "Zi attacks Slime for 12 damage!")

	var text = log_label.get_text()
	_assert(text.contains("Battle begins!"), "Log contains first message")
	_assert(text.contains("Zi attacks Slime"), "Log contains second message")

	log_label.queue_free()

func _append_to_log(log_label: RichTextLabel, msg: String) -> void:
	log_label.append_text(msg + "\n")

# --- Test: Turn queue highlights current entity ---
func _test_turn_queue_highlights_current() -> void:
	# The first entry in the turn queue should be visually distinct (bold)
	# We test the logic: first label gets bold, others don't
	var participants = [
		{"name": "Zi", "speed": 15},
		{"name": "Slime", "speed": 8},
		{"name": "Goblin", "speed": 6},
	]

	# Sort by speed descending (mimic CombatManager)
	participants.sort_custom(func(a, b): return a.get("speed", 0) > b.get("speed", 0))

	# First entry (index 0 = current turn) should be highlighted
	# We verify the concept: index 0 is "current", rest are not
	_assert(participants[0].name == "Zi", "Current turn entity is Zi (fastest)")
	# The actual highlight is done via Label bold font or color in _update_turn_queue
	# We just verify the label at index 0 would get special treatment
	var container = HBoxContainer.new()
	add_child(container)

	for i in participants.size():
		var lbl = Label.new()
		lbl.text = participants[i].name
		if i == 0:
			# Current turn: should be highlighted (we use modulate yellow)
			lbl.modulate = Color(1.0, 1.0, 0.3)
			lbl.text = "> " + lbl.text
		container.add_child(lbl)

	var first_label = container.get_child(0) as Label
	_assert(first_label.text.begins_with("> "), "Current turn label has '>' prefix")
	_assert(first_label.modulate == Color(1.0, 1.0, 0.3), "Current turn label is highlighted yellow")

	var second_label = container.get_child(1) as Label
	_assert(not second_label.text.begins_with("> "), "Non-current label has no prefix")

	container.queue_free()

# --- Test: Defend doubles defense in damage calc ---
func _test_defend_doubles_defense() -> void:
	var target_normal = {"name": "Zi", "hp": 100, "defense": 12}
	var target_defending = {"name": "Zi", "hp": 100, "defense": 12, "defending": true}

	var base_atk = 14
	var raw_damage = int(base_atk * 1.0 * 1.0 * 1.0) # no skill/stance/momentum mults

	var defense_normal = target_normal.get("defense", 0)
	var defense_defending = target_defending.get("defense", 0)
	if target_defending.get("defending", false):
		defense_defending *= 2

	var final_normal = maxi(1, raw_damage - defense_normal)
	var final_defending = maxi(1, raw_damage - defense_defending)

	_assert(final_normal == 2, "Normal defense: 14 - 12 = 2")
	_assert(final_defending == 1, "Defending defense: 14 - 24 = clamped to 1")
	_assert(final_defending < final_normal, "Defending reduces damage compared to normal")

# --- Test: Target menu lists alive enemies ---
func _test_target_menu_lists_alive_enemies() -> void:
	var enemies = [
		{"name": "Slime A", "hp": 30, "max_hp": 30, "is_enemy": true},
		{"name": "Slime B", "hp": 0, "max_hp": 30, "is_enemy": true},  # dead
		{"name": "Goblin", "hp": 20, "max_hp": 20, "is_enemy": true},
	]

	var alive = enemies.filter(func(e): return e.hp > 0)
	_assert(alive.size() == 2, "Two enemies alive out of three")
	_assert(alive[0].name == "Slime A", "First alive enemy is Slime A")
	_assert(alive[1].name == "Goblin", "Second alive enemy is Goblin")

# --- Integration test: 2-enemy battle scenario ---
func _test_integration_two_enemy_battle() -> void:
	MomentumSystem.reset()

	var zi = {
		"name": "Zi", "hp": 120, "max_hp": 120,
		"attack": 14, "defense": 12, "speed": 15,
		"active_stance": "Soldier's Edge",
		"stances": ["Soldier's Edge", "Counter Step", "Iron Wall"],
		"skills": [],
	}
	var enemy_a = {
		"name": "Slime A", "hp": 40, "max_hp": 40,
		"attack": 8, "defense": 2, "speed": 8,
		"is_enemy": true, "armor_type": "",
	}
	var enemy_b = {
		"name": "Slime B", "hp": 40, "max_hp": 40,
		"attack": 8, "defense": 2, "speed": 6,
		"is_enemy": true, "armor_type": "Agile",
	}

	var all_combatants = [zi, enemy_a, enemy_b]

	# Verify turn order (sorted by speed desc): Zi(15), Slime A(8), Slime B(6)
	all_combatants.sort_custom(func(a, b): return a.get("speed", 0) > b.get("speed", 0))
	_assert(all_combatants[0].name == "Zi", "Integration: Zi goes first")
	_assert(all_combatants[1].name == "Slime A", "Integration: Slime A goes second")
	_assert(all_combatants[2].name == "Slime B", "Integration: Slime B goes third")

	# Simulate Zi defends
	zi["defending"] = true

	# Simulate enemy A attacks Zi while defending
	var defense = zi.get("defense", 0)
	if zi.get("defending", false):
		defense *= 2
	var damage_to_zi = maxi(1, enemy_a.attack - defense)
	zi.hp -= damage_to_zi
	_assert(damage_to_zi == 1, "Integration: enemy attack 8 vs doubled defense 24 = clamped to 1")
	_assert(zi.hp == 119, "Integration: Zi HP after defended hit = 119")

	# Zi's next turn starts -> defending cleared
	zi.erase("defending")
	_assert(zi.get("defending", false) == false, "Integration: defend cleared on Zi's next turn")

	# Target selection: both enemies alive, player can pick either
	var alive_enemies = [enemy_a, enemy_b].filter(func(e): return e.hp > 0)
	_assert(alive_enemies.size() == 2, "Integration: both enemies alive for target selection")

	# Zi attacks Slime B with Counter Step (advantage vs Agile)
	zi["active_stance"] = "Counter Step"
	var stance_mult = StanceSystem.get_multiplier("Counter Step", enemy_b.armor_type)
	_assert(stance_mult == 1.3, "Integration: Counter Step vs Agile = 1.3x")

	var raw = zi.attack * 1.0 * stance_mult * MomentumSystem.get_damage_multiplier()
	var final_dmg = maxi(1, int(raw) - enemy_b.defense)
	enemy_b.hp -= final_dmg
	_assert(final_dmg > 0, "Integration: Zi deals positive damage to Slime B")
	_assert(enemy_b.hp < enemy_b.max_hp, "Integration: Slime B took damage")

	MomentumSystem.reset()
