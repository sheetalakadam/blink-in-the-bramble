extends CanvasLayer

## Post-combat reward screen. Shows XP gained, items found, and affinity changes.
## Emits rewards_acknowledged when the player presses Continue.

signal rewards_acknowledged

@onready var xp_label: Label = $Panel/VBox/XPLabel
@onready var loot_label: Label = $Panel/VBox/LootLabel
@onready var affinity_label: Label = $Panel/VBox/AffinityLabel
@onready var level_up_label: Label = $Panel/VBox/LevelUpLabel
@onready var continue_button: Button = $Panel/VBox/ContinueButton


func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	visible = false


func show_rewards(rewards: Dictionary, leveled_up: bool = false) -> void:
	# XP
	var xp: int = rewards.get("milestone_xp", 0)
	xp_label.text = "XP Gained: %d" % xp

	# Loot
	var loot: Array = rewards.get("loot", [])
	if loot.is_empty():
		loot_label.text = "Items: None"
	else:
		var item_names: Array[String] = []
		for path in loot:
			# Extract a readable name from the resource path
			var file_name: String = path.get_file().get_basename()
			item_names.append(file_name.capitalize())
		loot_label.text = "Items: %s" % ", ".join(item_names)

	# Affinity
	var affinity_gains: Dictionary = rewards.get("affinity_gains", {})
	if affinity_gains.is_empty():
		affinity_label.text = "Bonds: No changes"
	else:
		var lines: Array[String] = []
		for character in affinity_gains:
			var gain: int = affinity_gains[character]
			if gain > 0:
				lines.append("%s +%d" % [character, gain])
		if lines.is_empty():
			affinity_label.text = "Bonds: No changes"
		else:
			affinity_label.text = "Bonds: %s" % ", ".join(lines)

	# Level up
	if leveled_up:
		level_up_label.text = "Level Up!"
		level_up_label.visible = true
	else:
		level_up_label.visible = false

	visible = true
	continue_button.grab_focus()


func _on_continue_pressed() -> void:
	visible = false
	rewards_acknowledged.emit()
