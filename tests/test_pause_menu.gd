extends Node2D

const TAG = "[TEST_PAUSE_MENU]"
var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	print("%s Starting pause menu tests..." % TAG)
	_test_pause_menu_script_loads()
	_test_party_stats_loads()
	_test_party_stats_shows_all_characters()
	_test_pause_menu_scene_loads()
	_report()


func _assert(condition: bool, name: String) -> void:
	if condition:
		_passed += 1
		print("%s PASS: %s" % [TAG, name])
	else:
		_failed += 1
		printerr("%s FAIL: %s" % [TAG, name])


func _test_pause_menu_script_loads() -> void:
	var script = load("res://scripts/ui/PauseMenu.gd")
	_assert(script != null, "PauseMenu script loads")


func _test_party_stats_loads() -> void:
	var script = load("res://scripts/ui/PartyStatsUI.gd")
	_assert(script != null, "PartyStatsUI script loads")


func _test_party_stats_shows_all_characters() -> void:
	var paths := [
		"res://data/characters/zi.tres",
		"res://data/characters/caelan.tres",
		"res://data/characters/suri.tres",
		"res://data/characters/rynn.tres",
		"res://data/characters/lex.tres",
		"res://data/characters/vyn.tres",
	]
	for path in paths:
		var data = load(path) as CharacterData
		_assert(data != null, "char loads: %s" % path.get_file())
		if data:
			_assert(data.name != "", "has name: %s" % path.get_file())
			_assert(data.max_hp > 0, "has HP: %s" % path.get_file())


func _test_pause_menu_scene_loads() -> void:
	var scene = load("res://scenes/ui/PauseMenu.tscn")
	_assert(scene != null, "PauseMenu scene loads")
	var stats_scene = load("res://scenes/ui/PartyStatsUI.tscn")
	_assert(stats_scene != null, "PartyStatsUI scene loads")


func _report() -> void:
	print("%s Results: %d passed, %d failed" % [TAG, _passed, _failed])
	if _failed == 0:
		print("%s ALL TESTS PASSED" % TAG)
	else:
		printerr("%s SOME TESTS FAILED" % TAG)
	if DisplayServer.get_name() == "headless":
		get_tree().quit()
