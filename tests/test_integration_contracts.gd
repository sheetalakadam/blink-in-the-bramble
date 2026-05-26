extends Node2D

## Integration contract tests — verify that data produced by one system
## is accepted by the system that consumes it. These tests catch type
## mismatches (like untyped Array vs Array[Dictionary]) that unit tests miss.
##
## Run with: godot --headless --path . tests/test_integration_contracts.tscn

const TAG = "[TEST_CONTRACTS]"

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	print("%s Starting integration contract tests..." % TAG)
	_test_battle_transition_party_data_type()
	_test_battle_transition_enemy_data_type()
	_test_combat_controller_accepts_transition_data()
	_test_enemy_data_has_all_combat_fields()
	_test_char_data_has_all_combat_fields()
	_test_combat_scene_loads_and_has_signals()
	_report()


func _assert(condition: bool, name: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		printerr("%s FAIL: %s" % [TAG, name])


# --- Test 1: _build_party_data returns Array[Dictionary] ---
func _test_battle_transition_party_data_type() -> void:
	var bt = get_node_or_null("/root/BattleTransition")
	_assert(bt != null, "BattleTransition autoload exists")
	if bt == null:
		return

	var party_data = bt._build_party_data()
	_assert(party_data is Array, "Party data is Array")
	_assert(party_data.size() > 0, "Party data is not empty")

	# Verify it's typed — try assigning to Array[Dictionary]
	var typed: Array[Dictionary] = []
	for entry in party_data:
		_assert(entry is Dictionary, "Party entry is Dictionary")
		typed.append(entry)
	_assert(typed.size() == party_data.size(), "All party entries are valid Dictionaries")


# --- Test 2: _build_enemy_combat_data returns Dictionary with required keys ---
func _test_battle_transition_enemy_data_type() -> void:
	var bt = get_node_or_null("/root/BattleTransition")
	if bt == null:
		return

	# Set up enemy data as if we contacted an enemy
	bt._enemy_data = {"name": "Test Slime", "hp": 25, "attack": 7, "speed": 5, "armor_type": "Agile"}
	var enemy_data = bt._build_enemy_combat_data()

	_assert(enemy_data is Dictionary, "Enemy combat data is Dictionary")
	_assert(enemy_data.has("name"), "Enemy data has name")
	_assert(enemy_data.has("hp"), "Enemy data has hp")
	_assert(enemy_data.has("max_hp"), "Enemy data has max_hp")
	_assert(enemy_data.has("attack"), "Enemy data has attack")
	_assert(enemy_data.has("defense"), "Enemy data has defense")
	_assert(enemy_data.has("speed"), "Enemy data has speed")
	_assert(enemy_data.has("armor_type"), "Enemy data has armor_type")
	_assert(enemy_data.has("is_enemy"), "Enemy data has is_enemy")
	_assert(enemy_data.get("is_enemy") == true, "Enemy is_enemy is true")

	# Verify it can go into a typed array (the bug that bit us)
	var typed_list: Array[Dictionary] = [enemy_data]
	_assert(typed_list.size() == 1, "Enemy data fits in Array[Dictionary]")


# --- Test 3: CombatController.start() accepts data from BattleTransition ---
func _test_combat_controller_accepts_transition_data() -> void:
	var bt = get_node_or_null("/root/BattleTransition")
	if bt == null:
		return

	bt._enemy_data = {"name": "Test Slime", "hp": 25, "attack": 7, "speed": 5, "armor_type": "Agile"}
	var party_data: Array[Dictionary] = []
	for entry in bt._build_party_data():
		party_data.append(entry)

	var enemy_combat_data = bt._build_enemy_combat_data()
	var enemy_list: Array[Dictionary] = [enemy_combat_data]

	# Load the real CombatScene and call start() — this is the exact call
	# that failed at runtime with "array does not have the same element type"
	var combat_scene_res = load("res://scenes/combat/CombatScene.tscn")
	_assert(combat_scene_res != null, "CombatScene.tscn loads")
	if combat_scene_res == null:
		return

	var combat_scene = combat_scene_res.instantiate()
	add_child(combat_scene)

	# This is the actual contract test — if types don't match, this crashes
	combat_scene.start(party_data, enemy_list)
	_assert(true, "CombatController.start() accepts BattleTransition data without type error")

	# Verify combat actually started
	_assert(CombatManager.is_in_combat, "Combat started after start() call")

	CombatManager.end_combat()
	combat_scene.queue_free()


# --- Test 4: OverworldEnemy.get_enemy_data() has all fields combat needs ---
func _test_enemy_data_has_all_combat_fields() -> void:
	var enemy_scene = load("res://scenes/characters/OverworldEnemy.tscn")
	if enemy_scene == null:
		_assert(false, "OverworldEnemy scene loads")
		return

	var enemy = enemy_scene.instantiate()
	add_child(enemy)
	var data = enemy.get_enemy_data()

	# These are the fields BattleTransition._build_enemy_combat_data() reads
	var required_keys = ["name", "hp", "attack", "speed", "armor_type"]
	for key in required_keys:
		_assert(data.has(key), "OverworldEnemy data has '%s'" % key)

	enemy.queue_free()


# --- Test 5: CharacterData resource has all fields combat needs ---
func _test_char_data_has_all_combat_fields() -> void:
	var zi = load("res://data/characters/zi.tres") as CharacterData
	_assert(zi != null, "Zi CharacterData loads")
	if zi == null:
		return

	var dict = BattleTransition._char_to_dict(zi)

	# These are the fields CombatController uses
	var required_keys = ["name", "hp", "max_hp", "attack", "defense", "speed",
		"stances", "skills", "active_stance", "is_enemy"]
	for key in required_keys:
		_assert(dict.has(key), "CharacterData dict has '%s'" % key)

	_assert(dict.get("is_enemy") == false, "Party member is_enemy is false")
	_assert(dict.hp > 0, "Party member has positive HP")
	_assert(dict.stances is Array, "Stances is Array")
	_assert(dict.skills is Array, "Skills is Array")


# --- Test 6: CombatScene has the signals BattleTransition connects to ---
func _test_combat_scene_loads_and_has_signals() -> void:
	var combat_scene_res = load("res://scenes/combat/CombatScene.tscn")
	_assert(combat_scene_res != null, "CombatScene.tscn loads")
	if combat_scene_res == null:
		return

	var combat_scene = combat_scene_res.instantiate()
	_assert(combat_scene.has_signal("combat_won"), "CombatScene has combat_won signal")
	_assert(combat_scene.has_signal("combat_lost"), "CombatScene has combat_lost signal")
	_assert(combat_scene.has_method("start"), "CombatScene has start() method")
	combat_scene.queue_free()


func _report() -> void:
	print("%s Results: %d passed, %d failed" % [TAG, _passed, _failed])
	if _failed == 0:
		print("%s SUCCESS" % TAG)
	else:
		printerr("%s FAILED" % TAG)
	if DisplayServer.get_name() == "headless":
		get_tree().quit()
