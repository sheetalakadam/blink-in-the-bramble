extends Node

var current_camera: Camera2D

func register_camera(camera: Camera2D) -> void:
	current_camera = camera

func trigger_hit_stop(duration: float = 0.1) -> void:
	# In Godot 4, we use Engine.time_scale for hit-stops
	Engine.time_scale = 0.0
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

func trigger_screen_shake(intensity: float = 5.0, duration: float = 0.2) -> void:
	if not current_camera:
		return
		
	var original_offset = current_camera.offset
	var elapsed = 0.0
	
	while elapsed < duration:
		current_camera.offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		elapsed += get_process_delta_time()
		await get_tree().process_frame
		
	current_camera.offset = original_offset
