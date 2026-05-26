extends Node

const TEST_PREFIX = "[TEST_DIALOGUE_UI]"
const DIALOGUE_PATH = "res://data/dialogue/scene_01_the_fall.json"

var failed := false
var dialogue_ui: Node = null

func _ready() -> void:
	# Allow one frame for scene tree to settle
	await get_tree().process_frame
	dialogue_ui = get_node_or_null("DialogueBox")
	if dialogue_ui == null:
		_fail("DialogueBox child node not found in test scene")
		_finish()
		return
	_run_tests()

func _run_tests() -> void:
	_test_speaker_label_updates()
	_test_typewriter_sets_visible_ratio_zero_then_tweens()
	_test_monologue_shows_when_present()
	_test_monologue_hides_when_absent()
	_test_lens_shows_when_present()
	_test_lens_hides_when_absent()
	_test_advance_skips_typewriter_mid_animation()
	await _test_integration_scene_01()
	_finish()

# --- Test: Speaker label updates from line_data ---
func _test_speaker_label_updates() -> void:
	var line_data := {"speaker": "Zi", "text": "Hello."}
	dialogue_ui._on_line_presented(line_data)
	var speaker_label: Label = dialogue_ui.get_node("MainBox/SpeakerLabel")
	if speaker_label.text == "Zi":
		_pass("Speaker label updates to 'Zi'")
	else:
		_fail("Speaker label expected 'Zi', got '%s'" % speaker_label.text)

# --- Test: Typewriter sets visible_ratio to 0 then tweens to 1 ---
func _test_typewriter_sets_visible_ratio_zero_then_tweens() -> void:
	var line_data := {"speaker": "Zi", "text": "A longer sentence for typewriter testing."}
	dialogue_ui._on_line_presented(line_data)
	var spoken_text: RichTextLabel = dialogue_ui.get_node("MainBox/SpokenText")

	# Right after presenting, visible_ratio should be 0 (typewriter hasn't completed)
	if spoken_text.visible_ratio == 0.0:
		_pass("Typewriter starts with visible_ratio = 0")
	else:
		_fail("Typewriter visible_ratio expected 0.0 after present, got %f" % spoken_text.visible_ratio)

	# Check that is_typewriting flag is true
	if dialogue_ui.is_typewriting:
		_pass("is_typewriting flag is true during animation")
	else:
		_fail("is_typewriting should be true during typewriter animation")

# --- Test: Monologue shows when line_data has monologue ---
func _test_monologue_shows_when_present() -> void:
	var line_data := {"speaker": "Zi", "text": "...", "monologue": "Internal thought."}
	dialogue_ui._on_line_presented(line_data)
	var inner_mono: RichTextLabel = dialogue_ui.get_node("InnerMonologue")
	if inner_mono.visible:
		_pass("Monologue visible when line_data has monologue")
	else:
		_fail("Monologue should be visible when monologue field is present")

	if "[i]" in inner_mono.text and "Internal thought." in inner_mono.text:
		_pass("Monologue text is italic-wrapped")
	else:
		_fail("Monologue text expected italic bbcode, got: %s" % inner_mono.text)

# --- Test: Monologue hides when line_data has no monologue ---
func _test_monologue_hides_when_absent() -> void:
	var line_data := {"speaker": "Caelan", "text": "I don't remember."}
	dialogue_ui._on_line_presented(line_data)
	var inner_mono: RichTextLabel = dialogue_ui.get_node("InnerMonologue")
	if not inner_mono.visible:
		_pass("Monologue hidden when line_data has no monologue")
	else:
		_fail("Monologue should be hidden when monologue field is absent")

# --- Test: Lens label shows when line_data has lens ---
func _test_lens_shows_when_present() -> void:
	var line_data := {"speaker": "Zi", "text": "...", "monologue": "Observation.", "lens": "tactical"}
	dialogue_ui._on_line_presented(line_data)
	var lens_label: Label = dialogue_ui.get_node("LensLabel")
	if lens_label == null:
		_fail("LensLabel node not found in DialogueBox scene")
		return
	if lens_label.visible:
		_pass("Lens label visible when line_data has lens")
	else:
		_fail("Lens label should be visible when lens field is present")
	if "tactical" in lens_label.text.to_lower():
		_pass("Lens label text contains 'tactical'")
	else:
		_fail("Lens label text expected 'tactical', got: %s" % lens_label.text)

# --- Test: Lens label hides when line_data has no lens ---
func _test_lens_hides_when_absent() -> void:
	var line_data := {"speaker": "Zi", "text": "Hello.", "monologue": "Thinking."}
	dialogue_ui._on_line_presented(line_data)
	var lens_label: Label = dialogue_ui.get_node("LensLabel")
	if lens_label == null:
		_fail("LensLabel node not found in DialogueBox scene")
		return
	if not lens_label.visible:
		_pass("Lens label hidden when line_data has no lens")
	else:
		_fail("Lens label should be hidden when lens field is absent")

# --- Test: Advancing mid-typewriter completes instantly ---
func _test_advance_skips_typewriter_mid_animation() -> void:
	var line_data := {"speaker": "Zi", "text": "A sentence that should be skippable."}
	dialogue_ui._on_line_presented(line_data)
	var spoken_text: RichTextLabel = dialogue_ui.get_node("MainBox/SpokenText")

	# Should be mid-typewriter
	if not dialogue_ui.is_typewriting:
		_fail("Expected is_typewriting to be true before skip test")
		return

	# Call skip
	dialogue_ui.skip_typewriter()

	if spoken_text.visible_ratio == 1.0:
		_pass("skip_typewriter sets visible_ratio to 1.0")
	else:
		_fail("After skip, visible_ratio expected 1.0, got %f" % spoken_text.visible_ratio)

	if not dialogue_ui.is_typewriting:
		_pass("is_typewriting is false after skip")
	else:
		_fail("is_typewriting should be false after skip")

# --- Integration Test: Load scene_01_the_fall.json, verify first line ---
func _test_integration_scene_01() -> void:
	if not FileAccess.file_exists(DIALOGUE_PATH):
		_fail("Integration: Dialogue file not found: %s" % DIALOGUE_PATH)
		return

	var file = FileAccess.open(DIALOGUE_PATH, FileAccess.READ)
	var content = file.get_as_text()
	var data = JSON.parse_string(content)

	if data == null:
		_fail("Integration: JSON parse returned null")
		return

	var start_node = data["start_node"]
	var first_line = data["nodes"][start_node]["lines"][0]

	# Present the first line through DialogueUI
	dialogue_ui._on_line_presented(first_line)

	var speaker_label: Label = dialogue_ui.get_node("MainBox/SpeakerLabel")
	var spoken_text: RichTextLabel = dialogue_ui.get_node("MainBox/SpokenText")
	var inner_mono: RichTextLabel = dialogue_ui.get_node("InnerMonologue")

	# Verify speaker
	if speaker_label.text == first_line["speaker"]:
		_pass("Integration: Speaker is '%s'" % first_line["speaker"])
	else:
		_fail("Integration: Speaker expected '%s', got '%s'" % [first_line["speaker"], speaker_label.text])

	# Verify text is set (even if typewriter hasn't revealed it yet)
	if spoken_text.text == first_line["text"]:
		_pass("Integration: SpokenText content matches")
	else:
		_fail("Integration: SpokenText expected '%s', got '%s'" % [first_line["text"], spoken_text.text])

	# Verify monologue populated (first line has monologue)
	if first_line.has("monologue") and first_line["monologue"] != "":
		if inner_mono.visible and first_line["monologue"] in inner_mono.text:
			_pass("Integration: Monologue text populated correctly")
		else:
			_fail("Integration: Monologue expected visible with text '%s'" % first_line["monologue"])

	# Verify lens (first line has lens = "tactical")
	if first_line.has("lens"):
		var lens_label: Label = dialogue_ui.get_node("LensLabel")
		if lens_label != null and lens_label.visible:
			_pass("Integration: Lens label visible for tactical line")
		else:
			_fail("Integration: Lens label should be visible for line with lens field")

	# Skip typewriter and verify full text visible
	dialogue_ui.skip_typewriter()
	# Wait a frame for tween kill to take effect
	await get_tree().process_frame
	if spoken_text.visible_ratio == 1.0:
		_pass("Integration: After skip, full text visible")
	else:
		_fail("Integration: After skip, visible_ratio expected 1.0, got %f" % spoken_text.visible_ratio)

func _pass(msg: String) -> void:
	print("%s PASS: %s" % [TEST_PREFIX, msg])

func _fail(msg: String) -> void:
	failed = true
	print("%s FAIL: %s" % [TEST_PREFIX, msg])

func _finish() -> void:
	if failed:
		print("%s FAILED" % TEST_PREFIX)
	else:
		print("%s SUCCESS" % TEST_PREFIX)
