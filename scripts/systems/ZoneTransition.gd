extends Area2D

## Reusable zone transition trigger.
## Place at map edges. When the player enters, checks GlobalFlags
## for the required_flag. If set, loads target_scene_path.
## If not set, shows a soft-gate message.

signal zone_changed(from: String, to: String)
signal transition_blocked(message: String)

@export var target_scene_path: String = ""
@export var required_flag: String = ""
@export var blocked_message: String = "The path ahead is unclear..."

var _transitioning: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func can_transition() -> bool:
	if required_flag == "":
		return true
	return GlobalFlags.get_flag(required_flag)


func get_blocked_message() -> String:
	return blocked_message


func _emit_zone_changed(from: String, to: String) -> void:
	zone_changed.emit(from, to)


func _on_body_entered(body: Node2D) -> void:
	if _transitioning:
		return
	if not body.is_in_group("player"):
		return

	if can_transition():
		_transitioning = true
		var current_scene_name = get_tree().current_scene.name if get_tree().current_scene else "Unknown"
		var target_name = target_scene_path.get_file().get_basename()
		_emit_zone_changed(current_scene_name, target_name)
		print("[ZoneTransition] Transitioning from %s to %s" % [current_scene_name, target_name])
		get_tree().change_scene_to_file(target_scene_path)
	else:
		print("[ZoneTransition] Blocked: %s" % blocked_message)
		transition_blocked.emit(blocked_message)
		_show_blocked_label()


func _show_blocked_label() -> void:
	# Show a temporary label with the blocked message
	var label = Label.new()
	label.text = blocked_message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(320 - 150, 20)
	label.size = Vector2(300, 40)
	label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	get_tree().current_scene.add_child(label)

	# Remove after 2 seconds
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(label):
		label.queue_free()
