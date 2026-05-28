extends Node2D

## Tests that all skill .tres files load correctly and have valid fields.
## Run with: godot --headless --path . tests/test_skill_data.tscn

const TAG = "[TEST_SKILL_DATA]"

var _passed: int = 0
var _failed: int = 0

# Every skill resource that should exist
const ALL_SKILL_PATHS: Array[String] = [
	# Zi
	"res://data/skills/zi_strike.tres",
	"res://data/skills/zi_read.tres",
	"res://data/skills/zi_cleave.tres",
	"res://data/skills/zi_pressure_point.tres",
	# Caelan
	"res://data/skills/caelan_divine_strike.tres",
	"res://data/skills/caelan_remnant_light.tres",
	"res://data/skills/caelan_threshold_hold.tres",
	"res://data/skills/caelan_fracture_touch.tres",
	# Suri
	"res://data/skills/suri_quick_strike.tres",
	"res://data/skills/suri_setup_strike.tres",
	"res://data/skills/suri_double_tap.tres",
	# Rynn
	"res://data/skills/rynn_snare.tres",
	"res://data/skills/rynn_ereivyn_toxin.tres",
	"res://data/skills/rynn_valdrihn_flash.tres",
	"res://data/skills/rynn_solenne_charm.tres",
	"res://data/skills/rynn_velundrath_vial.tres",
	# Lex
	"res://data/skills/lex_pressure_strike.tres",
	"res://data/skills/lex_field_notes.tres",
	"res://data/skills/lex_pattern_break.tres",
	"res://data/skills/lex_studied_strike.tres",
]

# Expected values: path -> [name, damage_multiplier, momentum_change]
const EXPECTED_VALUES: Dictionary = {
	"res://data/skills/zi_strike.tres": ["Strike", 1.0, 5.0],
	"res://data/skills/zi_read.tres": ["Read", 0.0, 0.0],
	"res://data/skills/zi_cleave.tres": ["Cleave", 0.7, 3.0],
	"res://data/skills/zi_pressure_point.tres": ["Pressure Point", 0.9, 5.0],
	"res://data/skills/caelan_divine_strike.tres": ["Divine Strike", 1.2, 5.0],
	"res://data/skills/caelan_remnant_light.tres": ["Remnant Light", 0.5, -10.0],
	"res://data/skills/caelan_threshold_hold.tres": ["Threshold Hold", 0.8, -5.0],
	"res://data/skills/caelan_fracture_touch.tres": ["Fracture Touch", 1.8, 10.0],
	"res://data/skills/suri_quick_strike.tres": ["Quick Strike", 0.8, 3.0],
	"res://data/skills/suri_setup_strike.tres": ["Setup Strike", 0.7, 3.0],
	"res://data/skills/suri_double_tap.tres": ["Double Tap", 1.4, 6.0],
	"res://data/skills/rynn_snare.tres": ["Snare", 0.6, 2.0],
	"res://data/skills/rynn_ereivyn_toxin.tres": ["Ereivyn Toxin", 0.6, 4.0],
	"res://data/skills/rynn_valdrihn_flash.tres": ["Valdrihn Flash Charge", 1.0, 5.0],
	"res://data/skills/rynn_solenne_charm.tres": ["Solenne Charm", 0.7, 4.0],
	"res://data/skills/rynn_velundrath_vial.tres": ["Velundrath Pressure Vial", 0.5, 3.0],
	"res://data/skills/lex_pressure_strike.tres": ["Pressure Strike", 0.8, 4.0],
	"res://data/skills/lex_field_notes.tres": ["Field Notes", 0.0, 0.0],
	"res://data/skills/lex_pattern_break.tres": ["Pattern Break", 0.7, 5.0],
	"res://data/skills/lex_studied_strike.tres": ["Studied Strike", 1.0, 5.0],
}


func _ready() -> void:
	print("%s Starting skill data tests..." % TAG)
	_test_all_skills_load()
	_test_all_skills_are_skill_data()
	_test_all_skills_have_name()
	_test_all_skills_have_description()
	_test_expected_values()
	_test_target_types_valid()
	_report()


func _assert(condition: bool, name: String) -> void:
	if condition:
		_passed += 1
		print("%s PASS: %s" % [TAG, name])
	else:
		_failed += 1
		printerr("%s FAIL: %s" % [TAG, name])


## --- Test: all skill .tres files can be loaded ---
func _test_all_skills_load() -> void:
	for path in ALL_SKILL_PATHS:
		var res = load(path)
		_assert(res != null, "Skill loads: %s" % path)


## --- Test: all loaded skills are SkillData resources ---
func _test_all_skills_are_skill_data() -> void:
	for path in ALL_SKILL_PATHS:
		var res = load(path)
		if res != null:
			_assert(res is SkillData, "Skill is SkillData: %s" % path)


## --- Test: all skills have a non-empty name ---
func _test_all_skills_have_name() -> void:
	for path in ALL_SKILL_PATHS:
		var res = load(path) as SkillData
		if res != null:
			_assert(res.name != "", "Skill has name: %s" % path)


## --- Test: all skills have a non-empty description ---
func _test_all_skills_have_description() -> void:
	for path in ALL_SKILL_PATHS:
		var res = load(path) as SkillData
		if res != null:
			_assert(res.description != "", "Skill has description: %s" % path)


## --- Test: expected numeric values match the combat plan ---
func _test_expected_values() -> void:
	for path in EXPECTED_VALUES:
		var res = load(path) as SkillData
		if res == null:
			_assert(false, "Expected values — skill not found: %s" % path)
			continue
		var expected: Array = EXPECTED_VALUES[path]
		_assert(res.name == expected[0],
			"Name matches for %s (expected '%s', got '%s')" % [path, expected[0], res.name])
		_assert(is_equal_approx(res.damage_multiplier, expected[1]),
			"Damage multiplier for %s (expected %s, got %s)" % [path, expected[1], res.damage_multiplier])
		_assert(is_equal_approx(res.momentum_change, expected[2]),
			"Momentum change for %s (expected %s, got %s)" % [path, expected[2], res.momentum_change])


## --- Test: target_type is a valid enum value (0-4) ---
func _test_target_types_valid() -> void:
	for path in ALL_SKILL_PATHS:
		var res = load(path) as SkillData
		if res != null:
			_assert(res.target_type >= 0 and res.target_type <= 4,
				"Target type valid for %s (got %d)" % [path, res.target_type])


func _report() -> void:
	print("%s Results: %d passed, %d failed" % [TAG, _passed, _failed])
	if _failed == 0:
		print("%s ALL TESTS PASSED" % TAG)
	else:
		printerr("%s SOME TESTS FAILED" % TAG)
	if DisplayServer.get_name() == "headless":
		get_tree().quit()
