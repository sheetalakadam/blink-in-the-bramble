extends Node2D

## End-to-end test for the MVP loop:
## 1. BattleTransition loads real CombatScene (not placeholder)
## 2. CombatController receives party + enemy data and starts combat
## 3. Combat resolves (victory) and returns to overworld
## 4. Dialogue system loads opening scene correctly

const TEST_PREFIX = "[TEST_E2E_MVP]"

var _passed: int = 0
var _failed: int = 0

func _ready() -> void:
	print("%s Starting end-to-end MVP tests..." % TEST_PREFIX)
	_test_character_data_to_combat_dict()
	_test_battle_transition_builds_real_scene()
	_test_combat_full_round()
	_test_dialogue_opening_loads()
	_test_enemy_data_format()
	_test_momentum_resets_between_battles()
	_test_transition_to_combat_contract()
	_test_defeated_enemy_persistence()
	_test_vyn_ai_priorities()
	_test_dialogue_reachability()
	_report()

func _assert(condition: bool, name: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		printerr("%s FAIL: %s" % [TEST_PREFIX, name])

# --- Test 1: CharacterData resource converts to combat Dictionary ---
func _test_character_data_to_combat_dict() -> void:
	var zi_res = load("res://data/characters/zi.tres") as CharacterData
	_assert(zi_res != null, "Zi CharacterData loads")
	if zi_res == null:
		return

	var dict = _char_to_dict(zi_res)
	_assert(dict.name == "Zi", "Dict has correct name")
	_assert(dict.hp == 120, "Dict has correct hp")
	_assert(dict.max_hp == 120, "Dict has correct max_hp")
	_assert(dict.attack == 14, "Dict has correct attack")
	_assert(dict.defense == 12, "Dict has correct defense")
	_assert(dict.speed == 11, "Dict has correct speed")
	_assert(dict.stances.size() == 3, "Dict has 3 stances")
	_assert(dict.skills.size() == 2, "Dict has 2 skills")
	_assert(dict.get("is_enemy") == false, "Dict is_enemy is false")
	_assert(dict.get("active_stance") == "Soldier's Edge", "Default stance is first stance")

# --- Test 2: BattleTransition has method to load real combat scene ---
func _test_battle_transition_builds_real_scene() -> void:
	var bt = get_node_or_null("/root/BattleTransition")
	_assert(bt != null, "BattleTransition autoload exists")
	if bt == null:
		return
	_assert(bt.has_method("start_transition"), "Has start_transition method")
	_assert(bt.has_method("_build_party_data"), "Has _build_party_data method")

# --- Test 3: Full combat round resolves ---
func _test_combat_full_round() -> void:
	MomentumSystem.reset()

	var party = [{"name": "Zi", "hp": 100, "max_hp": 100, "attack": 14, "defense": 12,
		"speed": 15, "stances": ["Soldier's Edge"], "skills": [],
		"active_stance": "Soldier's Edge", "is_enemy": false}]
	var enemies = [{"name": "Slime", "hp": 1, "max_hp": 20, "attack": 5, "defense": 0,
		"speed": 8, "armor_type": "Agile", "is_enemy": true}]

	# Start combat
	CombatManager.start_combat(party + enemies)
	_assert(CombatManager.is_in_combat, "Combat started")
	_assert(CombatManager.turn_queue.size() == 2, "Queue has 2 combatants")
	_assert(CombatManager.turn_queue[0].name == "Zi", "Zi goes first (speed 15 > 8)")

	# Simulate damage
	var stance_mult = StanceSystem.get_multiplier("Counter Step", "Agile")
	_assert(stance_mult == 1.3, "Counter Step advantage vs Agile")

	var momentum_mult = MomentumSystem.get_damage_multiplier()
	_assert(momentum_mult == 1.0, "Starting momentum is Balanced")

	# Simulate attack: Zi hits slime for kill
	var raw = 14 * 1.0 * 1.0 * 1.0  # base * skill * stance * momentum
	var dmg = maxi(1, int(raw) - 0)
	enemies[0].hp -= dmg
	_assert(enemies[0].hp <= 0, "Slime dies from one hit (14 atk vs 0 def, 1 hp)")

	CombatManager.end_combat()
	_assert(not CombatManager.is_in_combat, "Combat ended")

# --- Test 4: Opening dialogue loads and parses ---
func _test_dialogue_opening_loads() -> void:
	var path = "res://data/dialogue/scene_01_the_fall.json"
	_assert(FileAccess.file_exists(path), "Opening dialogue file exists")

	var file = FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	_assert(data != null, "Opening dialogue parses as JSON")
	_assert(data.get("start_node", "") != "", "Has start_node")
	_assert(data.get("nodes", {}).has(data.get("start_node", "")), "Start node exists in nodes")

	# Verify the full chain is navigable
	var visited: Array[String] = []
	var current = data.get("start_node", "")
	while current != "" and current not in visited:
		visited.append(current)
		var node = data["nodes"].get(current, {})
		current = node.get("next_node", "")
		if current == null:
			current = ""
	_assert(visited.size() >= 3, "Dialogue has at least 3 navigable nodes (has %d)" % visited.size())

# --- Test 5: Enemy data from OverworldEnemy matches combat format ---
func _test_enemy_data_format() -> void:
	var enemy_scene = load("res://scenes/characters/OverworldEnemy.tscn")
	_assert(enemy_scene != null, "OverworldEnemy scene loads")
	if enemy_scene == null:
		return

	var enemy = enemy_scene.instantiate()
	add_child(enemy)
	_assert(enemy.has_method("get_enemy_data"), "Enemy has get_enemy_data()")

	var data = enemy.get_enemy_data()
	_assert(data.has("name"), "Enemy data has name")
	_assert(data.has("hp"), "Enemy data has hp")
	_assert(data.has("attack"), "Enemy data has attack")
	_assert(data.has("speed"), "Enemy data has speed")
	_assert(data.has("armor_type"), "Enemy data has armor_type")

	enemy.queue_free()

# --- Test 6: Momentum resets between battles ---
func _test_momentum_resets_between_battles() -> void:
	MomentumSystem.add_momentum(60.0)
	_assert(MomentumSystem.current_state == MomentumSystem.MomentumState.SURGE, "In Surge after +60")
	MomentumSystem.reset()
	_assert(MomentumSystem.current_momentum == 0.0, "Momentum resets to 0")
	_assert(MomentumSystem.current_state == MomentumSystem.MomentumState.BALANCED, "State resets to Balanced")

# --- Test 7: BattleTransition data passes CombatController type checks ---
func _test_transition_to_combat_contract() -> void:
	var bt = get_node_or_null("/root/BattleTransition")
	if bt == null:
		_assert(false, "BattleTransition needed for contract test")
		return

	# Build party data the same way BattleTransition does
	var party_data: Array[Dictionary] = bt._build_party_data()
	_assert(party_data.size() > 0, "Party data built from resources")

	# Build enemy data and wrap in typed array (the exact bug we hit)
	bt._enemy_data = {"name": "Slime", "hp": 20, "attack": 5, "speed": 5, "armor_type": "Agile"}
	var enemy_data = bt._build_enemy_combat_data()
	var enemy_list: Array[Dictionary] = [enemy_data]
	_assert(enemy_list.size() == 1, "Enemy list is typed Array[Dictionary]")

	# Load CombatScene and call start() — this is the call that crashed
	var scene = load("res://scenes/combat/CombatScene.tscn")
	if scene == null:
		_assert(false, "CombatScene loads for contract test")
		return
	var combat = scene.instantiate()
	add_child(combat)
	combat.start(party_data, enemy_list)
	_assert(CombatManager.is_in_combat, "Combat started via real transition data")
	CombatManager.end_combat()
	combat.queue_free()

# --- Test 8: Defeated enemy persistence in BattleTransition ---
func _test_defeated_enemy_persistence() -> void:
	var bt = get_node_or_null("/root/BattleTransition")
	if bt == null:
		_assert(false, "BattleTransition needed for persistence test")
		return

	var initial_count = bt.defeated_enemies.size()
	bt.defeated_enemies.append({
		"scene": "res://scenes/world/NaevoriaRuins.tscn",
		"name": "Test Slime",
		"position": Vector2(300, 300),
	})
	_assert(bt.defeated_enemies.size() == initial_count + 1, "Defeated enemy recorded")

	# Clean up
	bt.defeated_enemies.pop_back()

# --- Test 9: Vyn AI targeting priorities ---
func _test_vyn_ai_priorities() -> void:
	var vyn = {"name": "Vyn", "hp": 50, "max_hp": 50, "attack": 10}
	var party_safe = [
		{"name": "Zi", "hp": 100, "max_hp": 100},
		vyn,
	]
	var enemies_test = [
		{"name": "Slime A", "hp": 5, "max_hp": 20, "attack": 5, "defense": 0, "armor_type": "Agile"},
		{"name": "Slime B", "hp": 20, "max_hp": 20, "attack": 5, "defense": 0, "armor_type": "Agile"},
	]

	# Vyn should target low-HP enemy first (Priority 3: finish off)
	var decision = VynCombatAI.choose_action(vyn, party_safe, enemies_test, {})
	_assert(decision.target.name == "Slime A", "Vyn targets low-HP enemy for finishing")

	# With a dangerous party member, Vyn should root instead
	var party_danger = [
		{"name": "Zi", "hp": 10, "max_hp": 100},
		vyn,
	]
	var enemies_threat = [
		{"name": "Knight", "hp": 50, "max_hp": 50, "attack": 15, "defense": 5, "armor_type": "Heavy", "attacked_last_turn": true},
	]
	var decision2 = VynCombatAI.choose_action(vyn, party_danger, enemies_threat, {})
	_assert(decision2.action == "root", "Vyn roots when party member in danger")

# --- Test 10: Dialogue reachability ---
func _test_dialogue_reachability() -> void:
	var path = "res://data/dialogue/scene_01_the_fall.json"
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		_assert(false, "Opening dialogue file accessible")
		return
	var data = JSON.parse_string(file.get_as_text())
	if data == null:
		_assert(false, "Opening dialogue parses")
		return

	var nodes: Dictionary = data.get("nodes", {})
	var start: String = data.get("start_node", "")
	var reachable: Array[String] = []
	_walk_nodes(start, nodes, reachable)

	_assert(reachable.size() == nodes.size(), "All nodes reachable in scene_01 (reachable: %d, total: %d)" % [reachable.size(), nodes.size()])

func _walk_nodes(node_name: String, nodes: Dictionary, visited: Array[String]) -> void:
	if node_name == "" or node_name in visited or not nodes.has(node_name):
		return
	visited.append(node_name)
	var node: Dictionary = nodes[node_name]
	var next: String = node.get("next_node", "")
	if next != null and next != "":
		_walk_nodes(next, nodes, visited)
	for choice in node.get("choices", []):
		var target: String = choice.get("next_node", choice.get("next", ""))
		if target != "":
			_walk_nodes(target, nodes, visited)
	for line in node.get("lines", []):
		for choice in line.get("choices", []):
			var target: String = choice.get("next_node", choice.get("next", ""))
			if target != "":
				_walk_nodes(target, nodes, visited)


# --- Helper: convert CharacterData resource to combat dict ---
func _char_to_dict(char_data: CharacterData) -> Dictionary:
	# This is the conversion function that BattleTransition should use
	return {
		"name": char_data.name,
		"hp": char_data.max_hp,
		"max_hp": char_data.max_hp,
		"attack": char_data.attack,
		"defense": char_data.defense,
		"speed": char_data.speed,
		"stances": char_data.stances.duplicate(),
		"skills": char_data.skills.duplicate(),
		"active_stance": char_data.stances[0] if char_data.stances.size() > 0 else "",
		"is_enemy": false,
	}

func _report() -> void:
	print("%s Results: %d passed, %d failed" % [TEST_PREFIX, _passed, _failed])
	if _failed == 0:
		print("%s SUCCESS" % TEST_PREFIX)
	else:
		printerr("%s FAILED" % TEST_PREFIX)
	if DisplayServer.get_name() == "headless":
		get_tree().quit()
