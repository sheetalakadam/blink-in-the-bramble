extends Node

signal momentum_changed(new_value: float)
signal state_changed(new_state: MomentumState)

enum MomentumState { GROUNDED, BALANCED, SURGE }

var current_momentum: float = 0.0:
	set(val):
		current_momentum = clamp(val, -100.0, 100.0)
		momentum_changed.emit(current_momentum)
		_check_state_transition()

var current_state: MomentumState = MomentumState.BALANCED

func _check_state_transition() -> void:
	var next_state = current_state
	
	if current_momentum <= -50.0:
		next_state = MomentumState.GROUNDED
	elif current_momentum >= 50.0:
		next_state = MomentumState.SURGE
	else:
		next_state = MomentumState.BALANCED
		
	if next_state != current_state:
		current_state = next_state
		state_changed.emit(current_state)
		print("[MomentumSystem] State changed to: ", MomentumState.keys()[current_state])

func add_momentum(amount: float) -> void:
	current_momentum += amount

func get_damage_multiplier() -> float:
	match current_state:
		MomentumState.GROUNDED: return 0.8
		MomentumState.SURGE: return 1.4
		_: return 1.0

func reset() -> void:
	current_momentum = 0.0
	current_state = MomentumState.BALANCED
