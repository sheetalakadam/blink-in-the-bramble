extends Node2D

const TAG = "[TEST_GAME_WIRING]"
var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	print("%s Starting game wiring tests..." % TAG)
	_test_pause_menu_loads()
	_test_flag_triggers_recruitment_suri()
	_test_flag_triggers_recruitment_rynn()
	_test_flag_triggers_recruitment_lex()
	_test_met_lex_starts_main_01()
	_test_investigated_distortion_starts_main_03()
	_test_all_companions_met_starts_main_02()
	_test_main_02_not_started_without_all_three()
	_test_duplicate_recruitment_ignored()
	_test_dialogue_completed_signal_exists()
	_test_dialogue_completed_sets_flag()
	_report()


func _assert(condition: bool, name: String) -> void:
	if condition:
		_passed += 1
		print("%s PASS: %s" % [TAG, name])
	else:
		_failed += 1
		printerr("%s FAIL: %s" % [TAG, name])


func _reset_all() -> void:
	GlobalFlags.reset()
	QuestManager.reset()
	PartyManager.reset()


func _test_pause_menu_loads() -> void:
	var scene = load("res://scenes/ui/PauseMenu.tscn")
	_assert(scene != null, "PauseMenu scene loads")
	if scene:
		var instance = scene.instantiate()
		_assert(instance != null, "PauseMenu instantiates")
		_assert(instance is CanvasLayer, "PauseMenu is CanvasLayer")
		instance.queue_free()


func _test_flag_triggers_recruitment_suri() -> void:
	_reset_all()
	GlobalFlags.set_flag("met_suri", true)
	# GameWiring should have reacted if it's loaded. We test the logic directly.
	var wiring = _get_or_create_wiring()
	wiring._on_flag_changed("met_suri", true)
	_assert(PartyManager.is_recruited("res://data/characters/suri.tres"), "met_suri recruits Suri")
	wiring.queue_free()
	_reset_all()


func _test_flag_triggers_recruitment_rynn() -> void:
	_reset_all()
	var wiring = _get_or_create_wiring()
	wiring._on_flag_changed("met_rynn", true)
	_assert(PartyManager.is_recruited("res://data/characters/rynn.tres"), "met_rynn recruits Rynn")
	wiring.queue_free()
	_reset_all()


func _test_flag_triggers_recruitment_lex() -> void:
	_reset_all()
	var wiring = _get_or_create_wiring()
	wiring._on_flag_changed("met_lex", true)
	_assert(PartyManager.is_recruited("res://data/characters/lex.tres"), "met_lex recruits Lex")
	wiring.queue_free()
	_reset_all()


func _test_met_lex_starts_main_01() -> void:
	_reset_all()
	var wiring = _get_or_create_wiring()
	wiring._on_flag_changed("met_lex", true)
	_assert(QuestManager.is_quest_active("main_01"), "met_lex starts main_01")
	wiring.queue_free()
	_reset_all()


func _test_investigated_distortion_starts_main_03() -> void:
	_reset_all()
	var wiring = _get_or_create_wiring()
	wiring._on_flag_changed("investigated_distortion", true)
	_assert(QuestManager.is_quest_active("main_03"), "investigated_distortion starts main_03")
	wiring.queue_free()
	_reset_all()


func _test_all_companions_met_starts_main_02() -> void:
	_reset_all()
	var wiring = _get_or_create_wiring()
	GlobalFlags.set_flag("met_suri", true)
	GlobalFlags.set_flag("met_rynn", true)
	# Setting met_lex should trigger check for all 3
	GlobalFlags.set_flag("met_lex", true)
	wiring._on_flag_changed("met_lex", true)
	_assert(QuestManager.is_quest_active("main_02"), "all companions met starts main_02")
	wiring.queue_free()
	_reset_all()


func _test_main_02_not_started_without_all_three() -> void:
	_reset_all()
	var wiring = _get_or_create_wiring()
	GlobalFlags.set_flag("met_suri", true)
	wiring._on_flag_changed("met_suri", true)
	_assert(not QuestManager.is_quest_active("main_02"), "main_02 not started with only suri")
	GlobalFlags.set_flag("met_rynn", true)
	wiring._on_flag_changed("met_rynn", true)
	_assert(not QuestManager.is_quest_active("main_02"), "main_02 not started with only suri+rynn")
	wiring.queue_free()
	_reset_all()


func _test_duplicate_recruitment_ignored() -> void:
	_reset_all()
	var wiring = _get_or_create_wiring()
	wiring._on_flag_changed("met_suri", true)
	wiring._on_flag_changed("met_suri", true)
	# Should still only be recruited once
	var count := 0
	for path in PartyManager.all_recruited:
		if path == "res://data/characters/suri.tres":
			count += 1
	_assert(count == 1, "duplicate recruitment ignored")
	wiring.queue_free()
	_reset_all()


func _test_dialogue_completed_signal_exists() -> void:
	_assert(DialogueManager.has_signal("dialogue_completed"), "DialogueManager has dialogue_completed signal")


func _test_dialogue_completed_sets_flag() -> void:
	_reset_all()
	var wiring = _get_or_create_wiring()
	# Simulate dialogue completion for scene_04_ereivyn_threshold
	wiring._on_dialogue_completed("scene_04_ereivyn_threshold")
	_assert(GlobalFlags.get_flag("met_rynn"), "dialogue_completed sets met_rynn flag")
	wiring.queue_free()
	_reset_all()


func _get_or_create_wiring() -> Node:
	# Create a fresh GameWiring instance for isolated testing.
	# We don't call _ready() to avoid PauseMenu instantiation in tests.
	var script = load("res://scripts/systems/GameWiring.gd")
	var wiring = Node.new()
	wiring.set_script(script)
	add_child(wiring)
	# Remove the auto-created pause menu to keep tests clean
	for child in wiring.get_children():
		child.queue_free()
	return wiring


func _report() -> void:
	print("%s Results: %d passed, %d failed" % [TAG, _passed, _failed])
	if _failed == 0:
		print("%s ALL TESTS PASSED" % TAG)
	else:
		printerr("%s SOME TESTS FAILED" % TAG)
	if DisplayServer.get_name() == "headless":
		get_tree().quit()
