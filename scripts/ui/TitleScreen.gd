extends Control

## Title screen — dark, quiet, atmospheric.
## Shows game title and minimal menu options.

const FIRST_SCENE_PATH: String = "res://scenes/world/NaevoriaRuins.tscn"
const FIRST_QUEST_PATH: String = "res://data/quests/main_01.tres"

@onready var continue_button: Button = %ContinueButton


func _ready() -> void:
	_update_continue_visibility()
	%NewGameButton.grab_focus()


func _update_continue_visibility() -> void:
	var save_exists := _save_exists()
	continue_button.visible = save_exists
	if save_exists:
		continue_button.grab_focus()


static func _save_exists() -> bool:
	return FileAccess.file_exists("user://save_slot_0.res")


func _on_new_game_pressed() -> void:
	# Reset all game state for a fresh start
	GlobalFlags.reset()
	PartyManager.reset()
	QuestManager.reset()
	InventoryManager.clear()

	# Start the opening quest
	if ResourceLoader.exists(FIRST_QUEST_PATH):
		QuestManager.start_quest(FIRST_QUEST_PATH)

	get_tree().change_scene_to_file(FIRST_SCENE_PATH)


func _on_continue_pressed() -> void:
	var data = SaveManager.load_game(0)
	if data:
		# SaveManager restores singletons; load the appropriate scene
		var scene_path: String = data.get("current_scene") if data.has_method("get") else FIRST_SCENE_PATH
		if scene_path == "":
			scene_path = FIRST_SCENE_PATH
		get_tree().change_scene_to_file(scene_path)
	else:
		printerr("[TitleScreen] Failed to load save — starting new game instead")
		_on_new_game_pressed()


func _on_quit_pressed() -> void:
	get_tree().quit()
