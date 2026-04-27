extends Node

signal turn_started(entity: Dictionary)
signal combat_started
signal combat_ended

var turn_queue: Array[Dictionary] = []
var active_entity_index: int = 0
var is_in_combat: bool = false

func start_combat(participants: Array[Dictionary]) -> void:
	print("[CombatManager] Starting combat...")
	is_in_combat = true
	turn_queue = participants
	_sort_queue()
	active_entity_index = 0
	combat_started.emit()
	_start_current_turn()

func _sort_queue() -> void:
	# Sort descending by speed
	turn_queue.sort_custom(func(a, b): return a.get("speed", 0) > b.get("speed", 0))

func _start_current_turn() -> void:
	var entity = turn_queue[active_entity_index]
	print("[CombatManager] Turn started for: ", entity.get("name", "Unknown"))
	turn_started.emit(entity)

func advance_turn() -> void:
	active_entity_index = (active_entity_index + 1) % turn_queue.size()
	_start_current_turn()

func end_combat() -> void:
	is_in_combat = false
	turn_queue.clear()
	combat_ended.emit()
	print("[CombatManager] Combat ended.")
