extends Control

## Shown on defeat — quiet, not dramatic.
## "The path ends here."

const TITLE_SCENE_PATH: String = "res://scenes/ui/TitleScreen.tscn"


func _ready() -> void:
	%RetryButton.grab_focus()


func _on_retry_pressed() -> void:
	var data = SaveManager.load_game(0)
	if data:
		var scene_path: String = data.get("current_scene") if data.has_method("get") else "res://scenes/world/NaevoriaRuins.tscn"
		if scene_path == "":
			scene_path = "res://scenes/world/NaevoriaRuins.tscn"
		get_tree().change_scene_to_file(scene_path)
	else:
		# No save — return to title
		get_tree().change_scene_to_file(TITLE_SCENE_PATH)


func _on_return_to_title_pressed() -> void:
	get_tree().change_scene_to_file(TITLE_SCENE_PATH)
