extends Node2D

const TAG = "[TEST_QUEST]"
var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	print("%s Starting quest system tests..." % TAG)
	_test_quest_data_loads()
	_test_start_quest()
	_test_duplicate_start_ignored()
	_test_check_objectives()
	_test_auto_complete()
	_test_complete_quest()
	_test_is_active_and_complete()
	_test_reset()
	_test_all_quest_files_load()
	_report()


func _assert(condition: bool, name: String) -> void:
	if condition:
		_passed += 1
		print("%s PASS: %s" % [TAG, name])
	else:
		_failed += 1
		printerr("%s FAIL: %s" % [TAG, name])


func _test_quest_data_loads() -> void:
	var quest = load("res://data/quests/main_01_investigate_ruins.tres") as QuestData
	_assert(quest != null, "quest data loads")
	_assert(quest.quest_id == "main_01", "quest_id correct")
	_assert(quest.title != "", "title not empty")
	_assert(quest.objectives.size() > 0, "has objectives")
	_assert(quest.objectives[0].has("flag"), "objective has flag field")


func _test_start_quest() -> void:
	QuestManager.reset()
	QuestManager.start_quest("res://data/quests/main_01_investigate_ruins.tres")
	_assert(QuestManager.is_quest_active("main_01"), "quest is active after start")
	_assert(not QuestManager.is_quest_complete("main_01"), "quest not complete after start")
	QuestManager.reset()


func _test_duplicate_start_ignored() -> void:
	QuestManager.reset()
	QuestManager.start_quest("res://data/quests/main_01_investigate_ruins.tres")
	QuestManager.start_quest("res://data/quests/main_01_investigate_ruins.tres")
	_assert(QuestManager.get_active_quests().size() == 1, "duplicate start ignored")
	QuestManager.reset()


func _test_check_objectives() -> void:
	QuestManager.reset()
	GlobalFlags.reset()
	QuestManager.start_quest("res://data/quests/main_01_investigate_ruins.tres")
	var objs = QuestManager.check_objectives("main_01")
	_assert(objs.size() == 3, "main_01 has 3 objectives")
	_assert(not objs[0].completed, "objective not complete without flag")

	GlobalFlags.set_flag("reached_naevoria", true)
	objs = QuestManager.check_objectives("main_01")
	_assert(objs[0].completed, "objective complete with flag set")
	_assert(not objs[1].completed, "second objective still incomplete")
	QuestManager.reset()
	GlobalFlags.reset()


func _test_auto_complete() -> void:
	QuestManager.reset()
	GlobalFlags.reset()
	QuestManager.start_quest("res://data/quests/discovery_01_shrine_auryn.tres")
	GlobalFlags.set_flag("found_shrine_auryn", true)
	GlobalFlags.set_flag("offered_shrine_auryn", true)
	QuestManager.check_objectives("discovery_01")
	_assert(QuestManager.is_quest_complete("discovery_01"), "quest auto-completes when all objectives done")
	QuestManager.reset()
	GlobalFlags.reset()


func _test_complete_quest() -> void:
	QuestManager.reset()
	QuestManager.start_quest("res://data/quests/main_01_investigate_ruins.tres")
	QuestManager.complete_quest("main_01")
	_assert(not QuestManager.is_quest_active("main_01"), "quest not active after complete")
	_assert(QuestManager.is_quest_complete("main_01"), "quest is complete")
	QuestManager.reset()


func _test_is_active_and_complete() -> void:
	QuestManager.reset()
	_assert(not QuestManager.is_quest_active("nonexistent"), "nonexistent quest not active")
	_assert(not QuestManager.is_quest_complete("nonexistent"), "nonexistent quest not complete")
	QuestManager.reset()


func _test_reset() -> void:
	QuestManager.reset()
	QuestManager.start_quest("res://data/quests/main_01_investigate_ruins.tres")
	QuestManager.reset()
	_assert(not QuestManager.is_quest_active("main_01"), "reset clears active")
	_assert(QuestManager.get_active_quests().size() == 0, "reset clears list")


func _test_all_quest_files_load() -> void:
	var paths := [
		"res://data/quests/main_01_investigate_ruins.tres",
		"res://data/quests/main_02_gather_party.tres",
		"res://data/quests/main_03_angel_signs.tres",
		"res://data/quests/side_01_rynn_supplies.tres",
		"res://data/quests/side_02_lex_catalogues.tres",
		"res://data/quests/discovery_01_shrine_auryn.tres",
	]
	for path in paths:
		var q = load(path) as QuestData
		_assert(q != null, "loads: %s" % path.get_file())
		if q:
			_assert(q.quest_id != "", "has quest_id: %s" % path.get_file())
			_assert(q.objectives.size() > 0, "has objectives: %s" % path.get_file())


func _report() -> void:
	print("%s Results: %d passed, %d failed" % [TAG, _passed, _failed])
	if _failed == 0:
		print("%s ALL TESTS PASSED" % TAG)
	else:
		printerr("%s SOME TESTS FAILED" % TAG)
	if DisplayServer.get_name() == "headless":
		get_tree().quit()
