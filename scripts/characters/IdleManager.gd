extends Node

signal flavor_idle_triggered(anim_name: String)

@export var idle_threshold: float = 10.0
var idle_time: float = 0.0
var is_active: bool = true

func _process(delta: float) -> void:
	if not is_active:
		return
		
	var parent = get_parent()
	if parent is CharacterBody2D:
		if parent.velocity.length() < 0.1:
			idle_time += delta
			if idle_time >= idle_threshold:
				_trigger_flavor_idle()
		else:
			idle_time = 0.0

func _trigger_flavor_idle() -> void:
	idle_time = 0.0
	# Character-specific flavor anims
	var parent = get_parent()
	var anim_name = "flavor_idle"
	
	if parent.name == "Zi":
		anim_name = "zi_tactical_idle"
	
	print("[IdleManager] Triggering flavor idle: ", anim_name)
	flavor_idle_triggered.emit(anim_name)
