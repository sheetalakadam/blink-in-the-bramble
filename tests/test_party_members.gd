extends Node2D

## Tests for Suri, Rynn, and Lex character data, skills, and stance advantages.

const TAG = "[TEST_PARTY]"
var _passed: int = 0
var _failed: int = 0

func _ready() -> void:
	print("%s Starting party member tests..." % TAG)
	_test_suri_loads()
	_test_rynn_loads()
	_test_lex_loads()
	_test_suri_skills()
	_test_rynn_skills()
	_test_lex_skills()
	_test_stance_advantages()
	_test_all_chars_have_combat_fields()
	_report()

func _assert(condition: bool, name: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		printerr("%s FAIL: %s" % [TAG, name])

func _test_suri_loads() -> void:
	var suri = load("res://data/characters/suri.tres") as CharacterData
	_assert(suri != null, "Suri loads")
	if suri == null:
		return
	_assert(suri.name == "Suri", "Suri name correct")
	_assert(suri.max_hp == 100, "Suri HP 100")
	_assert(suri.attack == 12, "Suri attack 12")
	_assert(suri.defense == 10, "Suri defense 10")
	_assert(suri.speed == 13, "Suri speed 13")
	_assert(suri.stances.size() == 3, "Suri has 3 stances")
	_assert(suri.skills.size() == 2, "Suri has 2 skills")

func _test_rynn_loads() -> void:
	var rynn = load("res://data/characters/rynn.tres") as CharacterData
	_assert(rynn != null, "Rynn loads")
	if rynn == null:
		return
	_assert(rynn.name == "Rynn", "Rynn name correct")
	_assert(rynn.max_hp == 90, "Rynn HP 90")
	_assert(rynn.attack == 13, "Rynn attack 13")
	_assert(rynn.defense == 9, "Rynn defense 9")
	_assert(rynn.speed == 12, "Rynn speed 12")
	_assert(rynn.stances.size() == 3, "Rynn has 3 stances")
	_assert(rynn.skills.size() == 2, "Rynn has 2 skills")

func _test_lex_loads() -> void:
	var lex = load("res://data/characters/lex.tres") as CharacterData
	_assert(lex != null, "Lex loads")
	if lex == null:
		return
	_assert(lex.name == "Lex", "Lex name correct")
	_assert(lex.max_hp == 85, "Lex HP 85")
	_assert(lex.attack == 11, "Lex attack 11")
	_assert(lex.defense == 11, "Lex defense 11")
	_assert(lex.speed == 10, "Lex speed 10")
	_assert(lex.stances.size() == 3, "Lex has 3 stances")
	_assert(lex.skills.size() == 2, "Lex has 2 skills")

func _test_suri_skills() -> void:
	var qs = load("res://data/skills/suri_quick_strike.tres") as SkillData
	_assert(qs != null, "Quick Strike loads")
	if qs:
		_assert(qs.name == "Quick Strike", "Quick Strike name")

	var ss = load("res://data/skills/suri_setup_strike.tres") as SkillData
	_assert(ss != null, "Setup Strike loads")
	if ss:
		_assert(ss.name == "Setup Strike", "Setup Strike name")
		_assert(ss.damage_multiplier == 0.7, "Setup Strike 0.7x mult")

func _test_rynn_skills() -> void:
	var toxin = load("res://data/skills/rynn_toxin.tres") as SkillData
	if toxin == null:
		toxin = load("res://data/skills/rynn_ereivyn_toxin.tres") as SkillData
	_assert(toxin != null, "Ereivyn Toxin loads")
	if toxin:
		_assert(toxin.damage_multiplier == 0.6, "Toxin 0.6x mult")

	var snare = load("res://data/skills/rynn_snare.tres") as SkillData
	_assert(snare != null, "Snare loads")
	if snare:
		_assert(snare.damage_multiplier == 0.8, "Snare 0.8x mult")

func _test_lex_skills() -> void:
	var ps = load("res://data/skills/lex_pressure_strike.tres") as SkillData
	_assert(ps != null, "Pressure Strike loads")
	if ps:
		_assert(ps.damage_multiplier == 1.1, "Pressure Strike 1.1x mult")

	var fn = load("res://data/skills/lex_field_notes.tres") as SkillData
	_assert(fn != null, "Field Notes loads")
	if fn:
		_assert(fn.damage_multiplier == 0.0, "Field Notes 0.0x mult (utility)")

func _test_stance_advantages() -> void:
	# Suri stances
	_assert(StanceSystem.get_multiplier("Market Way", "Agile") == 1.3, "Market Way vs Agile = 1.3x")
	_assert(StanceSystem.get_multiplier("Harbor Guard", "Heavy") == 1.3, "Harbor Guard vs Heavy = 1.3x")
	_assert(StanceSystem.get_multiplier("Open Hand", "Agile") == 1.0, "Open Hand neutral")

	# Rynn stances
	_assert(StanceSystem.get_multiplier("Forest Floor", "Heavy") == 1.3, "Forest Floor vs Heavy = 1.3x")
	_assert(StanceSystem.get_multiplier("Trader's Eye", "Magic") == 1.3, "Trader's Eye vs Magic = 1.3x")
	_assert(StanceSystem.get_multiplier("Prepared Ground", "Agile") == 1.3, "Prepared Ground vs Agile = 1.3x")

	# Lex stances
	_assert(StanceSystem.get_multiplier("Field Study", "Spirit") == 1.3, "Field Study vs Spirit = 1.3x")
	_assert(StanceSystem.get_multiplier("Anatomical", "Heavy") == 1.3, "Anatomical vs Heavy = 1.3x")
	_assert(StanceSystem.get_multiplier("Pattern Read", "Agile") == 1.3, "Pattern Read vs Agile = 1.3x")

	# Neutral checks
	_assert(StanceSystem.get_multiplier("Market Way", "Heavy") == 1.0, "Market Way vs Heavy neutral")
	_assert(StanceSystem.get_multiplier("Field Study", "Heavy") == 1.0, "Field Study vs Heavy neutral")

func _test_all_chars_have_combat_fields() -> void:
	for path in ["res://data/characters/suri.tres", "res://data/characters/rynn.tres", "res://data/characters/lex.tres"]:
		var char_data = load(path) as CharacterData
		if char_data == null:
			_assert(false, "%s loads" % path)
			continue
		var dict = BattleTransition._char_to_dict(char_data)
		var keys = ["name", "hp", "max_hp", "attack", "defense", "speed", "stances", "skills", "active_stance", "is_enemy"]
		for key in keys:
			_assert(dict.has(key), "%s dict has '%s'" % [char_data.name, key])

func _report() -> void:
	print("%s Results: %d passed, %d failed" % [TAG, _passed, _failed])
	if _failed == 0:
		print("%s SUCCESS" % TAG)
	else:
		printerr("%s FAILED" % TAG)
	if DisplayServer.get_name() == "headless":
		get_tree().quit()
