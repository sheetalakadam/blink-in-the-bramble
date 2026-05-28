extends Node

## Manages the transition between overworld and combat scenes.
## Fades to black, loads the real CombatScene, and returns on victory.

signal transition_started
signal transition_completed
signal battle_finished

var _enemy_data: Dictionary = {}
var _enemy_ref: WeakRef = WeakRef.new()
var _overworld_scene_path: String = ""
var _player_position: Vector2 = Vector2.ZERO
var _overlay: ColorRect = null
var _is_transitioning: bool = false

const FADE_DURATION: float = 0.5
const COMBAT_SCENE_PATH: String = "res://scenes/combat/CombatScene.tscn"

# Party character resource paths for MVP
const PARTY_RESOURCES: Array[String] = [
	"res://data/characters/zi.tres",
	"res://data/characters/caelan.tres",
	"res://data/characters/vyn.tres",
]


func _ready() -> void:
	_create_overlay()


func _create_overlay() -> void:
	_overlay = ColorRect.new()
	_overlay.name = "BattleTransitionOverlay"
	_overlay.color = Color(0, 0, 0, 0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.anchors_preset = Control.PRESET_FULL_RECT
	_overlay.z_index = 100
	add_child(_overlay)


func start_transition(enemy_node: CharacterBody2D) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true

	# Store enemy data and overworld state
	if enemy_node.has_method("get_enemy_data"):
		_enemy_data = enemy_node.get_enemy_data()
	else:
		_enemy_data = {"name": "Unknown", "speed": 5, "hp": 20, "attack": 5}

	_enemy_ref = weakref(enemy_node)
	_overworld_scene_path = get_tree().current_scene.scene_file_path
	var player = _find_player()
	if player:
		_player_position = player.global_position

	transition_started.emit()
	_fade_to_black()


func _fade_to_black() -> void:
	var tween = create_tween()
	tween.tween_property(_overlay, "color:a", 1.0, FADE_DURATION)
	tween.tween_callback(_load_battle_scene)


func _load_battle_scene() -> void:
	var party_data = _build_party_data()
	var enemy_combat_data = _build_enemy_combat_data()

	# Load and instance the real combat scene
	var combat_scene = load(COMBAT_SCENE_PATH).instantiate()

	# Switch scene
	var tree = get_tree()
	var old_scene = tree.current_scene
	tree.root.remove_child(old_scene)
	old_scene.queue_free()

	tree.root.add_child(combat_scene)
	tree.current_scene = combat_scene

	# Connect victory/defeat signals
	combat_scene.combat_won.connect(_on_victory)
	combat_scene.combat_lost.connect(_on_defeat)

	# Reset momentum for fresh battle
	MomentumSystem.reset()

	# Start combat
	var enemy_list: Array[Dictionary] = [enemy_combat_data]
	combat_scene.start(party_data, enemy_list)

	# Apply god boon if active
	if ShrineManager.has_boon():
		var effect = ShrineManager.get_boon_effect()
		combat_scene.apply_boon(effect)
		ShrineManager.consume_boon()

	# Fade in
	var tween = create_tween()
	tween.tween_property(_overlay, "color:a", 0.0, FADE_DURATION)

	transition_completed.emit()
	print("[BattleTransition] Entered combat with: ", _enemy_data.get("name", "?"))


func _build_party_data() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for path in PARTY_RESOURCES:
		var char_data = load(path) as CharacterData
		if char_data:
			result.append(_char_to_dict(char_data))
	return result


func _build_enemy_combat_data() -> Dictionary:
	return {
		"name": _enemy_data.get("name", "Slime"),
		"hp": _enemy_data.get("hp", 20),
		"max_hp": _enemy_data.get("hp", 20),
		"attack": _enemy_data.get("attack", 5),
		"defense": 0,
		"speed": _enemy_data.get("speed", 5),
		"armor_type": _enemy_data.get("armor_type", "Agile"),
		"is_enemy": true,
	}


static func _char_to_dict(char_data: CharacterData) -> Dictionary:
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


func _on_victory() -> void:
	print("[BattleTransition] Victory!")
	_fade_to_overworld()


func _on_defeat() -> void:
	print("[BattleTransition] Defeat...")
	_fade_to_overworld()


func _fade_to_overworld() -> void:
	var tween = create_tween()
	tween.tween_property(_overlay, "color:a", 1.0, FADE_DURATION)
	tween.tween_callback(_load_overworld)


func _load_overworld() -> void:
	if _overworld_scene_path == "":
		_overworld_scene_path = "res://scenes/world/NaevoriaRuins.tscn"

	var tree = get_tree()
	var old_scene = tree.current_scene
	tree.root.remove_child(old_scene)
	old_scene.queue_free()

	var overworld = load(_overworld_scene_path).instantiate()
	tree.root.add_child(overworld)
	tree.current_scene = overworld

	# Restore player position
	var player = _find_player()
	if player:
		player.global_position = _player_position

	# Remove the defeated enemy
	_remove_defeated_enemy(overworld)

	# Fade in
	var tween = create_tween()
	tween.tween_property(_overlay, "color:a", 0.0, FADE_DURATION)

	_is_transitioning = false
	battle_finished.emit()
	print("[BattleTransition] Returned to overworld")


func _remove_defeated_enemy(scene_root: Node) -> void:
	# Find and remove enemies with matching data in the new scene instance
	var enemies = scene_root.get_tree().get_nodes_in_group("overworld_enemies")
	for enemy in enemies:
		if enemy.has_method("get_enemy_data"):
			var data = enemy.get_enemy_data()
			if data.get("name") == _enemy_data.get("name"):
				if enemy.global_position.distance_to(_player_position) < 100.0:
					enemy.mark_defeated()
					break


func _find_player() -> CharacterBody2D:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0] as CharacterBody2D
	return null
