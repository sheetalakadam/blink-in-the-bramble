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
var _surge_protection: bool = false

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

func set_surge_protection(active: bool) -> void:
	_surge_protection = active

func get_damage_taken_multiplier() -> float:
	if current_state == MomentumState.SURGE and _surge_protection:
		return 1.1  # 30% extra reduced by 20% = 10% extra
	match current_state:
		MomentumState.SURGE: return 1.3
		MomentumState.GROUNDED: return 1.0
		_: return 1.0

func reset() -> void:
	current_momentum = 0.0
	current_state = MomentumState.BALANCED
	_surge_protection = false
