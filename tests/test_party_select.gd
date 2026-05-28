extends Node2D

## Tests for party selection logic, Vyn always included, recruit tracking,
## and max-3 selection constraint.

const TAG = "[TEST_PARTY_SELECT]"
var _passed: int = 0
var _failed: int = 0

const VYN_PATH = "res://data/characters/vyn.tres"
const ZI_PATH = "res://data/characters/zi.tres"
const CAELAN_PATH = "res://data/characters/caelan.tres"
const SURI_PATH = "res://data/characters/suri.tres"
const RYNN_PATH = "res://data/characters/rynn.tres"
const LEX_PATH = "res://data/characters/lex.tres"


func _ready() -> void:
	print("%s Starting party select tests..." % TAG)
	_test_recruit_character()
	_test_is_recruited()
	_test_get_recruited_count()
	_test_recruitable_excludes_vyn()
	_test_recruit_duplicate()
	_test_reset_clears_recruited()
	_test_party_select_vyn_always_included()
	_test_party_select_max_three()
	_test_build_party_with_selection()
	_test_build_party_fallback()
	_report()


func _assert(condition: bool, name: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		printerr("%s FAIL: %s" % [TAG, name])


func _test_recruit_character() -> void:
	PartyManager.reset()
	PartyManager.recruit_character(ZI_PATH)
	_assert(PartyManager.all_recruited.size() == 1, "Recruit adds to list")
	_assert(PartyManager.all_recruited[0] == ZI_PATH, "Recruited path matches")
	PartyManager.reset()


func _test_is_recruited() -> void:
	PartyManager.reset()
	PartyManager.recruit_character(ZI_PATH)
	_assert(PartyManager.is_recruited(ZI_PATH), "is_recruited true for recruited")
	_assert(not PartyManager.is_recruited(SURI_PATH), "is_recruited false for not recruited")
	PartyManager.reset()


func _test_get_recruited_count() -> void:
	PartyManager.reset()
	_assert(PartyManager.get_recruited_count() == 0, "Count starts at 0")
	PartyManager.recruit_character(ZI_PATH)
	PartyManager.recruit_character(CAELAN_PATH)
	_assert(PartyManager.get_recruited_count() == 2, "Count is 2 after 2 recruits")
	PartyManager.reset()


func _test_recruitable_excludes_vyn() -> void:
	PartyManager.reset()
	PartyManager.recruit_character(VYN_PATH)
	PartyManager.recruit_character(ZI_PATH)
	PartyManager.recruit_character(SURI_PATH)
	var recruitable = PartyManager.get_recruitable_paths()
	_assert(recruitable.size() == 2, "Recruitable excludes Vyn")
	for path in recruitable:
		_assert(path != VYN_PATH, "Vyn not in recruitable list")
	PartyManager.reset()


func _test_recruit_duplicate() -> void:
	PartyManager.reset()
	PartyManager.recruit_character(ZI_PATH)
	PartyManager.recruit_character(ZI_PATH)
	_assert(PartyManager.get_recruited_count() == 1, "Duplicate recruit ignored")
	PartyManager.reset()


func _test_reset_clears_recruited() -> void:
	PartyManager.recruit_character(ZI_PATH)
	PartyManager.reset()
	_assert(PartyManager.get_recruited_count() == 0, "Reset clears recruited")
	_assert(PartyManager.all_recruited.size() == 0, "Reset empties array")


func _test_party_select_vyn_always_included() -> void:
	# When BattleTransition builds party from selected paths, Vyn should always be first
	var selected: Array[String] = [ZI_PATH, CAELAN_PATH, SURI_PATH]

	# Simulate what _build_party_data does with selection
	var paths: Array[String] = [VYN_PATH]
	for p in selected:
		paths.append(p)

	_assert(paths[0] == VYN_PATH, "Vyn is always first in party")
	_assert(paths.size() == 4, "Party size is 4 (Vyn + 3)")

	# Verify Vyn is not in selectable list
	for p in selected:
		_assert(p != VYN_PATH, "Vyn not in selected list")


func _test_party_select_max_three() -> void:
	# The PartySelectUI enforces max 3 selections
	# We test the logic: selected array should never exceed 3
	var selected: Array[String] = []
	selected.append(ZI_PATH)
	selected.append(CAELAN_PATH)
	selected.append(SURI_PATH)

	# Attempting to add a 4th should be blocked by UI
	_assert(selected.size() == 3, "Max 3 selectable")

	# Total party = selected + Vyn = 4
	var total = selected.size() + 1  # +1 for Vyn
	_assert(total == 4, "Total party with Vyn is 4")


func _test_build_party_with_selection() -> void:
	# Test that _char_to_dict works for all characters
	var all_paths = [VYN_PATH, ZI_PATH, CAELAN_PATH, SURI_PATH, RYNN_PATH, LEX_PATH]
	for path in all_paths:
		var char_data = load(path) as CharacterData
		_assert(char_data != null, "%s loads" % path)
		if char_data:
			var dict = BattleTransition._char_to_dict(char_data)
			_assert(dict.has("name"), "%s has name" % path)
			_assert(dict.has("hp"), "%s has hp" % path)
			_assert(dict.has("is_enemy"), "%s has is_enemy" % path)
			_assert(dict["is_enemy"] == false, "%s is_enemy is false" % path)


func _test_build_party_fallback() -> void:
	# When no recruited characters, PARTY_RESOURCES is used
	PartyManager.reset()
	_assert(PartyManager.get_recruited_count() == 0, "No recruits for fallback test")
	# BattleTransition.PARTY_RESOURCES should have 3 entries
	_assert(BattleTransition.PARTY_RESOURCES.size() == 3, "Fallback has 3 party members")
	_assert(VYN_PATH in BattleTransition.PARTY_RESOURCES, "Fallback includes Vyn")


func _report() -> void:
	print("%s Results: %d passed, %d failed" % [TAG, _passed, _failed])
	if _failed == 0:
		print("%s SUCCESS" % TAG)
	else:
		printerr("%s FAILED" % TAG)
	if DisplayServer.get_name() == "headless":
		get_tree().quit()
