extends Node

var current_camera: Camera2D
var _vfx_container: CanvasLayer = null

func _ready() -> void:
	_vfx_container = CanvasLayer.new()
	_vfx_container.name = "VFXLayer"
	_vfx_container.layer = 90
	add_child(_vfx_container)

func register_camera(camera: Camera2D) -> void:
	current_camera = camera

func trigger_hit_stop(duration: float = 0.1) -> void:
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


## Shows a floating damage number that rises and fades out.
func show_damage_number(amount: int, screen_pos: Vector2, is_heal: bool = false) -> void:
	var label := Label.new()
	label.text = str(amount) if not is_heal else "+%d" % amount
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.PALE_GREEN if is_heal else Color.INDIAN_RED)
	label.position = screen_pos - Vector2(16, 0)
	label.z_index = 100
	_vfx_container.add_child(label)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", screen_pos.y - 40.0, 0.6).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.2)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)


## Flashes a color overlay on the screen briefly (e.g. red on hit, white on crit).
func flash_screen(color: Color = Color(1, 0.2, 0.2, 0.3), duration: float = 0.1) -> void:
	var rect := ColorRect.new()
	rect.color = color
	rect.anchors_preset = Control.PRESET_FULL_RECT
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vfx_container.add_child(rect)

	var tween := create_tween()
	tween.tween_property(rect, "color:a", 0.0, duration)
	tween.tween_callback(rect.queue_free)
