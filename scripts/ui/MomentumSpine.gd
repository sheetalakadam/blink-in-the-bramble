extends Control

@onready var gauge_bar: ProgressBar = %GaugeBar
@onready var state_label: Label = %StateLabel

func _ready() -> void:
	MomentumSystem.momentum_changed.connect(_on_momentum_changed)
	MomentumSystem.state_changed.connect(_on_state_changed)
	
	# Initial sync
	_on_momentum_changed(MomentumSystem.current_momentum)
	_on_state_changed(MomentumSystem.current_state)

func _on_momentum_changed(new_value: float) -> void:
	gauge_bar.value = new_value
	
	# Visual feedback: Change bar color based on state
	if new_value >= 50.0:
		gauge_bar.modulate = Color(0, 0.9, 1.0) # Divine Teal
	elif new_value <= -50.0:
		gauge_bar.modulate = Color(0.5, 0.5, 0.5) # Grounded Gray
	else:
		gauge_bar.modulate = Color(1, 1, 1) # Balanced White

func _on_state_changed(new_state: int) -> void:
	state_label.text = MomentumSystem.MomentumState.keys()[new_state]
