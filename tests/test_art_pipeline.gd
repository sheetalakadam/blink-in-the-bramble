extends Node

var _tests_passed: int = 0
var _tests_failed: int = 0


func _ready() -> void:
	print("[TEST_ART_PIPELINE] Starting art pipeline tests...")

	_test_sprite_loader_missing_sprite()
	_test_sprite_loader_missing_portrait()
	_test_sprite_loader_missing_tileset()
	_test_directory_structure()
	_test_pixel_perfect_settings()
	_test_dialogue_ui_missing_portrait()

	print("[TEST_ART_PIPELINE] Results: %d passed, %d failed" % [_tests_passed, _tests_failed])
	if _tests_failed == 0:
		print("[TEST_ART_PIPELINE] SUCCESS")
	else:
		printerr("[TEST_ART_PIPELINE] FAILED")

	if DisplayServer.get_name() == "headless":
		get_tree().quit()


func _assert(condition: bool, test_name: String) -> void:
	if condition:
		_tests_passed += 1
		print("[TEST_ART_PIPELINE] PASS: ", test_name)
	else:
		_tests_failed += 1
		printerr("[TEST_ART_PIPELINE] FAIL: ", test_name)


# --- SpriteLoader unit tests ---

func _test_sprite_loader_missing_sprite() -> void:
	var tex := SpriteLoader.get_character_sprite("nonexistent_character")
	_assert(tex == null, "get_character_sprite returns null for missing file")


func _test_sprite_loader_missing_portrait() -> void:
	var tex := SpriteLoader.get_portrait("nonexistent_character", "neutral")
	_assert(tex == null, "get_portrait returns null for missing file")


func _test_sprite_loader_missing_tileset() -> void:
	var ts := SpriteLoader.get_tileset("nonexistent_tileset")
	_assert(ts == null, "get_tileset returns null for missing file")


# --- Directory structure ---

func _test_directory_structure() -> void:
	var dirs := [
		"res://assets/sprites/characters",
		"res://assets/sprites/enemies",
		"res://assets/portraits",
		"res://assets/tilesets",
		"res://assets/audio/bgm",
		"res://assets/audio/sfx",
	]
	for dir_path in dirs:
		var exists := DirAccess.dir_exists_absolute(dir_path)
		_assert(exists, "Directory exists: " + dir_path)


# --- Pixel-perfect rendering settings ---

func _test_pixel_perfect_settings() -> void:
	var filter := ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter")
	_assert(filter == 0, "Texture filter is nearest-neighbor (0)")

	var stretch_mode := ProjectSettings.get_setting("display/window/stretch/mode")
	_assert(stretch_mode == "viewport", "Stretch mode is 'viewport' for pixel-perfect rendering")


# --- DialogueUI portrait graceful fallback ---

func _test_dialogue_ui_missing_portrait() -> void:
	# Get the DialogueUI instance from the scene tree
	var dialogue_ui = get_node_or_null("DialogueBox")
	if dialogue_ui == null:
		_assert(false, "DialogueUI node not found in test scene")
		return

	# Get portrait rect
	var portrait_rect = dialogue_ui.get_node_or_null("MainBox/PortraitRect")
	if portrait_rect == null:
		_assert(false, "PortraitRect node not found in DialogueUI")
		return

	# Simulate presenting a line with a portrait_state but no actual portrait file
	var line_data := {
		"speaker": "TestSpeaker",
		"text": "Hello, world!",
		"portrait_state": "neutral",
	}

	# Call _on_line_presented directly (it's connected to the signal normally)
	dialogue_ui._on_line_presented(line_data)

	# Portrait should be hidden since the file doesn't exist
	_assert(not portrait_rect.visible, "PortraitRect hidden when portrait file is missing")

	# Now test with no portrait_state at all
	var line_data_no_portrait := {
		"speaker": "TestSpeaker",
		"text": "No portrait line.",
	}
	dialogue_ui._on_line_presented(line_data_no_portrait)
	_assert(not portrait_rect.visible, "PortraitRect hidden when no portrait_state in line_data")

	# Verify no crash occurred
	_assert(true, "DialogueUI handles missing portrait without crash")
