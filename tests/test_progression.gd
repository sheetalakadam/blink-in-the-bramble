extends Node2D

## Progression & Affinity system tests
## Run with: godot --headless --path . tests/test_progression.tscn

const TAG = "[TEST_PROGRESSION]"

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	print("%s Starting progression & affinity tests..." % TAG)

	# PartyManager tests
	_test_add_party_member()
	_test_remove_party_member()
	_test_party_max_size()
	_test_grant_milestone_increases_level()
	_test_duplicate_milestone_ignored()
	_test_stats_update_on_level_up()

	# AffinityManager tests
	_test_add_affinity()
	_test_get_affinity_default()
	_test_affinity_clamp_upper()
	_test_affinity_clamp_lower()
	_test_highest_affinity_pair()
	_test_affinity_thresholds()

	# SaveManager round-trip
	_test_save_load_round_trip()

	# Integration
	_test_integration_milestone_updates_stats()
	_test_integration_affinity_signal()

	# ProgressionSystem skill unlock tests
	_test_progression_system_level_1()
	_test_progression_system_level_6()
	_test_progression_system_level_11()
	_test_progression_system_level_16_affinity()
	_test_progression_system_all_characters()
	_test_progression_system_unknown_character()

	_report()


func _assert(condition: bool, name: String) -> void:
	if condition:
		_passed += 1
		print("%s PASS: %s" % [TAG, name])
	else:
		_failed += 1
		printerr("%s FAIL: %s" % [TAG, name])


# --- PartyManager tests ---

func _test_add_party_member() -> void:
	var pm = get_node_or_null("/root/PartyManager")
	_assert(pm != null, "PartyManager autoload exists")
	if pm == null:
		return

	pm.reset()
	var char_data = CharacterData.new()
	char_data.name = "Caelan"
	char_data.max_hp = 100
	char_data.attack = 10
	char_data.defense = 10

	pm.add_to_party(char_data)
	var party = pm.get_active_party()
	_assert(party.size() == 1, "Party has 1 member after add")
	_assert(party[0].name == "Caelan", "Party member is Caelan")
	pm.reset()


func _test_remove_party_member() -> void:
	var pm = get_node_or_null("/root/PartyManager")
	if pm == null:
		return

	pm.reset()
	var c1 = CharacterData.new()
	c1.name = "Caelan"
	var c2 = CharacterData.new()
	c2.name = "Suri"

	pm.add_to_party(c1)
	pm.add_to_party(c2)
	_assert(pm.get_active_party().size() == 2, "Party has 2 members")

	pm.remove_from_party("Caelan")
	_assert(pm.get_active_party().size() == 1, "Party has 1 member after remove")
	_assert(pm.get_active_party()[0].name == "Suri", "Remaining member is Suri")
	pm.reset()


func _test_party_max_size() -> void:
	var pm = get_node_or_null("/root/PartyManager")
	if pm == null:
		return

	pm.reset()
	# Vyn is always slot 0, so max 3 additional
	var vyn = CharacterData.new()
	vyn.name = "Vyn"
	pm.add_to_party(vyn)

	for i in range(4):
		var c = CharacterData.new()
		c.name = "Member_%d" % i
		pm.add_to_party(c)

	# Max is 4 total (Vyn + 3)
	_assert(pm.get_active_party().size() == 4, "Party capped at 4 (Vyn + 3)")
	pm.reset()


func _test_grant_milestone_increases_level() -> void:
	var pm = get_node_or_null("/root/PartyManager")
	if pm == null:
		return

	pm.reset()
	_assert(pm.party_level == 1, "Party starts at level 1")

	pm.grant_milestone("first_boss_defeated")
	_assert(pm.party_level == 2, "Party level is 2 after first milestone")

	pm.grant_milestone("second_boss_defeated")
	_assert(pm.party_level == 3, "Party level is 3 after second milestone")
	pm.reset()


func _test_duplicate_milestone_ignored() -> void:
	var pm = get_node_or_null("/root/PartyManager")
	if pm == null:
		return

	pm.reset()
	pm.grant_milestone("first_boss_defeated")
	pm.grant_milestone("first_boss_defeated")
	_assert(pm.party_level == 2, "Duplicate milestone does not double-level")
	pm.reset()


func _test_stats_update_on_level_up() -> void:
	var pm = get_node_or_null("/root/PartyManager")
	if pm == null:
		return

	pm.reset()
	var c = CharacterData.new()
	c.name = "Caelan"
	c.max_hp = 100
	c.attack = 10
	c.defense = 10

	pm.add_to_party(c)
	pm.grant_milestone("test_milestone")

	# After 1 level up: hp +10% = 110, attack +1 = 11, defense +1 = 11
	var party = pm.get_active_party()
	_assert(party[0].max_hp == 110, "HP increased by 10%% after level up (got %d)" % party[0].max_hp)
	_assert(party[0].attack == 11, "Attack increased by 1 after level up (got %d)" % party[0].attack)
	_assert(party[0].defense == 11, "Defense increased by 1 after level up (got %d)" % party[0].defense)
	pm.reset()


# --- AffinityManager tests ---

func _test_add_affinity() -> void:
	var am = get_node_or_null("/root/AffinityManager")
	_assert(am != null, "AffinityManager autoload exists")
	if am == null:
		return

	am.reset()
	am.add_affinity("Caelan", 15)
	_assert(am.get_affinity("Caelan") == 15, "Caelan affinity is 15")
	am.add_affinity("Caelan", 10)
	_assert(am.get_affinity("Caelan") == 25, "Caelan affinity accumulated to 25")
	am.reset()


func _test_get_affinity_default() -> void:
	var am = get_node_or_null("/root/AffinityManager")
	if am == null:
		return

	am.reset()
	_assert(am.get_affinity("Caelan") == 0, "Default affinity is 0")
	am.reset()


func _test_affinity_clamp_upper() -> void:
	var am = get_node_or_null("/root/AffinityManager")
	if am == null:
		return

	am.reset()
	am.add_affinity("Caelan", 150)
	_assert(am.get_affinity("Caelan") == 100, "Affinity clamped at 100")
	am.reset()


func _test_affinity_clamp_lower() -> void:
	var am = get_node_or_null("/root/AffinityManager")
	if am == null:
		return

	am.reset()
	am.add_affinity("Caelan", -50)
	_assert(am.get_affinity("Caelan") == 0, "Affinity clamped at 0")
	am.reset()


func _test_highest_affinity_pair() -> void:
	var am = get_node_or_null("/root/AffinityManager")
	if am == null:
		return

	am.reset()
	am.add_affinity("Caelan", 30)
	am.add_affinity("Suri", 50)
	am.add_affinity("Rynn", 20)
	_assert(am.get_highest_affinity_pair() == "Suri", "Highest affinity pair is Suri (got %s)" % am.get_highest_affinity_pair())
	am.reset()


func _test_affinity_thresholds() -> void:
	var am = get_node_or_null("/root/AffinityManager")
	if am == null:
		return

	am.reset()
	am.add_affinity("Caelan", 10)
	_assert(am.get_threshold("Caelan") == "neutral", "10 is neutral")

	am.add_affinity("Caelan", 15)  # now 25
	_assert(am.get_threshold("Caelan") == "friendly", "25 is friendly")

	am.add_affinity("Caelan", 25)  # now 50
	_assert(am.get_threshold("Caelan") == "close", "50 is close")

	am.add_affinity("Caelan", 25)  # now 75
	_assert(am.get_threshold("Caelan") == "bonded", "75 is bonded")
	am.reset()


# --- SaveManager round-trip ---

func _test_save_load_round_trip() -> void:
	var pm = get_node_or_null("/root/PartyManager")
	var am = get_node_or_null("/root/AffinityManager")
	var sm = get_node_or_null("/root/SaveManager")
	if pm == null or am == null or sm == null:
		_assert(false, "Required autoloads exist for save test")
		return

	pm.reset()
	am.reset()

	# Set up state
	var c = CharacterData.new()
	c.name = "Caelan"
	c.max_hp = 100
	c.attack = 10
	c.defense = 10
	pm.add_to_party(c)
	pm.grant_milestone("save_test_milestone")

	am.add_affinity("Caelan", 40)
	am.add_affinity("Suri", 60)

	# Save to test slot
	sm.save_game(99)

	# Reset state
	pm.reset()
	am.reset()
	_assert(pm.party_level == 1, "Party level reset to 1 before load")
	_assert(am.get_affinity("Caelan") == 0, "Affinity reset before load")

	# Load back
	var data = sm.load_game(99)
	_assert(data != null, "Save data loaded successfully")
	if data == null:
		return

	_assert(pm.party_level == 2, "Party level restored to 2 after load (got %d)" % pm.party_level)
	_assert(am.get_affinity("Caelan") == 40, "Caelan affinity restored to 40 (got %d)" % am.get_affinity("Caelan"))
	_assert(am.get_affinity("Suri") == 60, "Suri affinity restored to 60 (got %d)" % am.get_affinity("Suri"))

	# Clean up test save
	var path = "user://save_slot_99.res"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

	pm.reset()
	am.reset()


# --- Integration tests ---

func _test_integration_milestone_updates_stats() -> void:
	var pm = get_node_or_null("/root/PartyManager")
	if pm == null:
		return

	pm.reset()
	var c = CharacterData.new()
	c.name = "Suri"
	c.max_hp = 80
	c.attack = 12
	c.defense = 8

	pm.add_to_party(c)
	pm.grant_milestone("integration_test")

	var party = pm.get_active_party()
	_assert(party[0].max_hp == 88, "Integration: HP updated after milestone (got %d)" % party[0].max_hp)
	_assert(party[0].attack == 13, "Integration: Attack updated after milestone (got %d)" % party[0].attack)
	_assert(party[0].defense == 9, "Integration: Defense updated after milestone (got %d)" % party[0].defense)
	pm.reset()


func _test_integration_affinity_signal() -> void:
	var am = get_node_or_null("/root/AffinityManager")
	if am == null:
		return

	am.reset()
	var signal_received = false
	var received_char = ""
	var received_value = 0

	var callback = func(character: String, new_value: int) -> void:
		signal_received = true
		received_char = character
		received_value = new_value

	am.affinity_changed.connect(callback)
	am.add_affinity("Rynn", 30)

	_assert(signal_received, "affinity_changed signal emitted")
	_assert(received_char == "Rynn", "Signal received correct character")
	_assert(received_value == 30, "Signal received correct value")

	am.affinity_changed.disconnect(callback)
	am.reset()


# --- ProgressionSystem skill unlock tests ---

func _test_progression_system_level_1() -> void:
	var skills = ProgressionSystem.get_available_skills("Zi", 1)
	_assert(skills.size() == 2, "Level 1 Zi has 2 skills (got %d)" % skills.size())
	if skills.size() >= 2:
		_assert(skills[0] == "res://data/skills/zi_strike.tres", "Level 1 Zi first skill is Strike")
		_assert(skills[1] == "res://data/skills/zi_read.tres", "Level 1 Zi second skill is Read")


func _test_progression_system_level_6() -> void:
	var skills = ProgressionSystem.get_available_skills("Zi", 6)
	_assert(skills.size() == 3, "Level 6 Zi has 3 skills (got %d)" % skills.size())
	if skills.size() >= 3:
		_assert(skills[2] == "res://data/skills/zi_cleave.tres", "Level 6 Zi third skill is Cleave")

	# Level 5 should still be 2
	var skills_5 = ProgressionSystem.get_available_skills("Zi", 5)
	_assert(skills_5.size() == 2, "Level 5 Zi still has 2 skills (got %d)" % skills_5.size())


func _test_progression_system_level_11() -> void:
	var skills = ProgressionSystem.get_available_skills("Zi", 11)
	_assert(skills.size() == 4, "Level 11 Zi has 4 skills (got %d)" % skills.size())
	if skills.size() >= 4:
		_assert(skills[3] == "res://data/skills/zi_pressure_point.tres", "Level 11 Zi fourth skill is Pressure Point")

	# Level 10 should still be 3
	var skills_10 = ProgressionSystem.get_available_skills("Zi", 10)
	_assert(skills_10.size() == 3, "Level 10 Zi still has 3 skills (got %d)" % skills_10.size())


func _test_progression_system_level_16_affinity() -> void:
	_assert(ProgressionSystem.has_affinity_combos(16), "Level 16 has affinity combos")
	_assert(not ProgressionSystem.has_affinity_combos(15), "Level 15 does not have affinity combos")


func _test_progression_system_all_characters() -> void:
	var characters = ["Zi", "Caelan", "Suri", "Rynn", "Lex"]
	for char_name in characters:
		var skills_1 = ProgressionSystem.get_available_skills(char_name, 1)
		_assert(skills_1.size() == 2, "%s level 1 has 2 skills (got %d)" % [char_name, skills_1.size()])

		var skills_11 = ProgressionSystem.get_available_skills(char_name, 11)
		_assert(skills_11.size() >= 3, "%s level 11 has >= 3 skills (got %d)" % [char_name, skills_11.size()])


func _test_progression_system_unknown_character() -> void:
	var skills = ProgressionSystem.get_available_skills("Nobody", 10)
	_assert(skills.size() == 0, "Unknown character returns empty skill list")


func _report() -> void:
	print("%s Results: %d passed, %d failed" % [TAG, _passed, _failed])
	if _failed == 0:
		print("%s SUCCESS" % TAG)
	else:
		printerr("%s FAILED" % TAG)
	if DisplayServer.get_name() == "headless":
		get_tree().quit()
