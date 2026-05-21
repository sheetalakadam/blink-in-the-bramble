extends Node2D

func _ready() -> void:
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	# Small delay to ensure DialogueUI is ready
	await get_tree().create_timer(0.1).timeout
	DialogueManager.start_dialogue("scene_01_the_fall")

func _on_dialogue_ended() -> void:
	print("[OpeningScene] Dialogue complete.")
	# Transition to gameplay or next scene would go here
