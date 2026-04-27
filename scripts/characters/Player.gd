extends CharacterBody2D

@export var speed: float = 150.0

func _physics_process(_delta: float) -> void:
	var input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_direction * speed
	
	move_and_slide()
	
	if Engine.has_singleton("WorldManager") or get_tree().root.has_node("WorldManager"):
		WorldManager.update_player_position(global_position)

	if velocity.length() > 0:
		_handle_movement_animation(input_direction)

func _handle_movement_animation(direction: Vector2) -> void:
	# Placeholder for animation logic
	pass
