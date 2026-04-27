extends Area2D

@export var vision_lore_id: String = ""

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Logic to check Vyn can go here later

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("[EreivynVision] Player entered vision zone: ", vision_lore_id)
		_trigger_vision()

func _trigger_vision() -> void:
	# Visual feedback: 5-second color shift
	var tween = get_tree().create_tween()
	var canvas_mod = get_tree().root.get_node_or_null("World/CanvasModulate")
	
	if canvas_mod:
		print("[EreivynVision] Shifting colors for vision...")
		tween.tween_property(canvas_mod, "color", Color(0.3, 0.8, 0.9, 0.5), 1.0)
		tween.tween_interval(3.0)
		tween.tween_property(canvas_mod, "color", Color(1, 1, 1, 1), 1.0)
