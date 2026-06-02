extends Area2D

## Interactive shrine node placed in the world.
## When the player enters, plays the shrine dialogue if available,
## then offers the boon via ShrineManager.

signal shrine_entered(shrine_data: ShrineData)

@export var god_name: String = ""
@export var shrine_data: ShrineData

var _activated := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _activated:
		return
	if not body.is_in_group("player"):
		return
	_activated = true
	print("[ShrineNode] Player entered shrine of %s" % god_name)

	# Play shrine dialogue if it exists
	var dialogue_id := "shrine_%s" % god_name.to_lower()
	var dialogue_path := "res://data/dialogue/%s.json" % dialogue_id
	if FileAccess.file_exists(dialogue_path):
		DialogueManager.start_dialogue(dialogue_id)
		await DialogueManager.dialogue_ended

	# Activate the boon
	if shrine_data and ShrineManager:
		var success := ShrineManager.activate_boon(shrine_data)
		if success:
			print("[ShrineNode] Boon granted: %s" % shrine_data.boon_name)
		else:
			print("[ShrineNode] Cannot afford boon: %s" % shrine_data.boon_name)

	shrine_entered.emit(shrine_data)
	# Allow re-interaction after a delay
	await get_tree().create_timer(3.0).timeout
	_activated = false
