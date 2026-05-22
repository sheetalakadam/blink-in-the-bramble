extends Node

## Manages the transition between overworld and combat scenes.
## Fades to black, loads a placeholder battle scene, and returns on victory.

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
	# Create a minimal placeholder battle scene
	var battle_root = Node2D.new()
	battle_root.name = "PlaceholderBattle"

	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.15, 1.0)
	bg.offset_right = 640
	bg.offset_bottom = 360
	battle_root.add_child(bg)

	var label = Label.new()
	label.text = "COMBAT SCENE"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(220, 140)
	label.add_theme_font_size_override("font_size", 32)
	battle_root.add_child(label)

	var enemy_label = Label.new()
	enemy_label.text = "Enemy: %s (Lv.%d)" % [_enemy_data.get("name", "?"), _enemy_data.get("level", 1)]
	enemy_label.position = Vector2(220, 200)
	enemy_label.add_theme_font_size_override("font_size", 16)
	battle_root.add_child(enemy_label)

	# Auto-win timer for now (placeholder -- real combat UI is PR B)
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.timeout.connect(_on_victory)
	battle_root.add_child(timer)

	# Switch scene
	var tree = get_tree()
	var old_scene = tree.current_scene
	tree.root.remove_child(old_scene)
	old_scene.queue_free()

	tree.root.add_child(battle_root)
	tree.current_scene = battle_root

	# Fade in
	var tween = create_tween()
	tween.tween_property(_overlay, "color:a", 0.0, FADE_DURATION)
	tween.tween_callback(func(): timer.start())

	transition_completed.emit()
	print("[BattleTransition] Entered combat with: ", _enemy_data.get("name", "?"))


func _on_victory() -> void:
	print("[BattleTransition] Victory!")
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
