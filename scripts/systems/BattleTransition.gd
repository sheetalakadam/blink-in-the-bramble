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
const PARTY_SELECT_SCENE: String = "res://scenes/ui/PartySelectUI.tscn"
const VYN_PATH: String = "res://data/characters/vyn.tres"
const MAX_PARTY_SIZE: int = 4  # Vyn + 3 companions

# Party character resource paths for MVP (fallback when no recruitment data)
const PARTY_RESOURCES: Array[String] = [
	"res://data/characters/zi.tres",
	"res://data/characters/caelan.tres",
	"res://data/characters/vyn.tres",
]

var _party_select_ui: Node = null
var _selected_party_paths: Array[String] = []


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

	# Store current region BGM and switch to combat music
	if Engine.has_singleton("AudioManager") or get_node_or_null("/root/AudioManager"):
		AudioManager.store_region_bgm()
		AudioManager.play_bgm("combat")

	_fade_to_black()


func _fade_to_black() -> void:
	var tween = create_tween()
	tween.tween_property(_overlay, "color:a", 1.0, FADE_DURATION)
	tween.tween_callback(_check_party_selection)


func _check_party_selection() -> void:
	var recruitable = PartyManager.get_recruitable_paths()
	if recruitable.size() > MAX_PARTY_SIZE - 1:
		# More than 3 recruitables available — show selection UI
		_show_party_select(recruitable)
	else:
		# Use default/recruited party directly
		_selected_party_paths.clear()
		_load_battle_scene()


func _show_party_select(recruitable: Array[String]) -> void:
	_party_select_ui = load(PARTY_SELECT_SCENE).instantiate()
	get_tree().root.add_child(_party_select_ui)
	_party_select_ui.party_selected.connect(_on_party_selected)
	_party_select_ui.cancelled.connect(_on_party_cancelled)
	# Fade in so player can see the UI
	_overlay.color.a = 0.0
	_party_select_ui.show_selection(recruitable)


func _on_party_selected(selected: Array[String]) -> void:
	_selected_party_paths = selected.duplicate()
	_cleanup_party_select()
	# Re-fade and load battle
	_overlay.color.a = 1.0
	_load_battle_scene()


func _on_party_cancelled() -> void:
	_cleanup_party_select()
	_overlay.color.a = 0.0
	_is_transitioning = false


func _cleanup_party_select() -> void:
	if _party_select_ui:
		_party_select_ui.queue_free()
		_party_select_ui = null


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

	# Connect victory/defeat signals — wait for rewards before returning
	combat_scene.rewards_acknowledged.connect(_on_victory)
	combat_scene.combat_won.connect(func(): print("[BattleTransition] Combat won — waiting for rewards..."))
	combat_scene.combat_lost.connect(_on_defeat)

	# Reset momentum for fresh battle
	MomentumSystem.reset()

	# Build enemy formation from encounter table or fallback
	var region: String = _enemy_data.get("region", "")
	var enemy_list: Array[Dictionary] = []
	if region != "":
		enemy_list = EncounterTable.get_encounter(region)
	else:
		enemy_list = [enemy_combat_data]
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
	var paths_to_load: Array[String] = []

	if _selected_party_paths.size() > 0:
		# Party selection was used — load selected + Vyn
		paths_to_load.append(VYN_PATH)
		for p in _selected_party_paths:
			paths_to_load.append(p)
	elif PartyManager.get_recruited_count() > 0:
		# Use recruited characters (up to 3 + Vyn)
		paths_to_load.append(VYN_PATH)
		var recruitable = PartyManager.get_recruitable_paths()
		for i in range(mini(recruitable.size(), MAX_PARTY_SIZE - 1)):
			paths_to_load.append(recruitable[i])
	else:
		# Fallback to MVP defaults
		paths_to_load = Array(PARTY_RESOURCES, TYPE_STRING, &"", null)

	for path in paths_to_load:
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

	# Restore region BGM after combat
	if Engine.has_singleton("AudioManager") or get_node_or_null("/root/AudioManager"):
		AudioManager.restore_region_bgm()

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
