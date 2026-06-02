extends Node

# Tests for DialogueManager choice handling

var _passed := 0
var _failed := 0
var _test_name := ""

func _ready() -> void:
	print("=== DialogueManager Choice Tests ===")

	test_choices_presented_signal()
	test_select_choice_navigates()
	test_advance_blocked_during_choice()
	test_select_invalid_index()
	test_end_dialogue_clears_choice_state()
	test_choice_with_empty_target_ends()

	print("\n%d passed, %d failed" % [_passed, _failed])
	if _failed > 0:
		print("SOME TESTS FAILED")
	else:
		print("ALL TESTS PASSED")

func _begin(name: String) -> void:
	_test_name = name

func _assert(condition: bool, msg: String = "") -> void:
	if condition:
		_passed += 1
		print("  PASS: %s %s" % [_test_name, msg])
	else:
		_failed += 1
		print("  FAIL: %s %s" % [_test_name, msg])

func _make_dialogue_with_choices() -> Dictionary:
	return {
		"id": "test_choices",
		"start_node": "intro",
		"nodes": {
			"intro": {
				"lines": [
					{"speaker": "Zi", "text": "What should we do?"}
				],
				"next_node": "",
				"choices": [
					{"text": "Go left", "next_node": "left_path"},
					{"text": "Go right", "next_node": "right_path"}
				]
			},
			"left_path": {
				"lines": [
					{"speaker": "Zi", "text": "We went left."}
				],
				"next_node": ""
			},
			"right_path": {
				"lines": [
					{"speaker": "Zi", "text": "We went right."}
				],
				"next_node": ""
			}
		}
	}

func _setup_dialogue(data: Dictionary) -> void:
	DialogueManager.current_dialogue = data
	DialogueManager.current_dialogue_id = data.get("id", "test")
	DialogueManager.current_node_id = data.get("start_node", "")
	DialogueManager.current_line_index = 0
	DialogueManager.is_active = true
	DialogueManager.awaiting_choice = false

func test_choices_presented_signal() -> void:
	_begin("choices_presented_signal")
	var data = _make_dialogue_with_choices()
	_setup_dialogue(data)

	var signal_received := false
	var received_choices := []
	var callback = func(choices: Array):
		signal_received = true
		received_choices = choices

	DialogueManager.choices_presented.connect(callback)

	# Advance past the single line in intro -> should trigger choices
	DialogueManager.advance_dialogue()

	_assert(signal_received, "- signal emitted")
	_assert(received_choices.size() == 2, "- 2 choices received")
	_assert(DialogueManager.awaiting_choice, "- awaiting_choice is true")

	DialogueManager.choices_presented.disconnect(callback)
	DialogueManager.awaiting_choice = false
	DialogueManager.is_active = false

func test_select_choice_navigates() -> void:
	_begin("select_choice_navigates")
	var data = _make_dialogue_with_choices()
	_setup_dialogue(data)

	# Advance to trigger choices
	DialogueManager.advance_dialogue()

	# Select "Go right" (index 1)
	DialogueManager.select_choice(1)

	_assert(DialogueManager.current_node_id == "right_path", "- navigated to right_path")
	_assert(not DialogueManager.awaiting_choice, "- no longer awaiting choice")
	_assert(DialogueManager.current_line_index == 0, "- line index reset to 0")

	DialogueManager.is_active = false

func test_advance_blocked_during_choice() -> void:
	_begin("advance_blocked_during_choice")
	var data = _make_dialogue_with_choices()
	_setup_dialogue(data)

	# Advance to trigger choices
	DialogueManager.advance_dialogue()
	_assert(DialogueManager.awaiting_choice, "- awaiting choice")

	# Try advancing again — should be blocked
	var node_before = DialogueManager.current_node_id
	DialogueManager.advance_dialogue()
	_assert(DialogueManager.current_node_id == node_before, "- node unchanged")
	_assert(DialogueManager.awaiting_choice, "- still awaiting choice")

	DialogueManager.awaiting_choice = false
	DialogueManager.is_active = false

func test_select_invalid_index() -> void:
	_begin("select_invalid_index")
	var data = _make_dialogue_with_choices()
	_setup_dialogue(data)

	DialogueManager.advance_dialogue()

	# Try invalid indices
	DialogueManager.select_choice(-1)
	_assert(DialogueManager.awaiting_choice, "- still awaiting after -1")

	DialogueManager.select_choice(99)
	_assert(DialogueManager.awaiting_choice, "- still awaiting after 99")

	DialogueManager.awaiting_choice = false
	DialogueManager.is_active = false

func test_end_dialogue_clears_choice_state() -> void:
	_begin("end_dialogue_clears_choice")
	var data = _make_dialogue_with_choices()
	_setup_dialogue(data)

	DialogueManager.advance_dialogue()
	_assert(DialogueManager.awaiting_choice, "- awaiting choice set")

	# Select choice 0 -> left_path, then advance past its single line -> should end
	DialogueManager.select_choice(0)
	DialogueManager.advance_dialogue()

	_assert(not DialogueManager.is_active, "- dialogue ended")
	_assert(not DialogueManager.awaiting_choice, "- choice state cleared")

func test_choice_with_empty_target_ends() -> void:
	_begin("choice_empty_target_ends")
	var data = {
		"id": "test_empty",
		"start_node": "ask",
		"nodes": {
			"ask": {
				"lines": [{"speaker": "Zi", "text": "?"}],
				"next_node": "",
				"choices": [
					{"text": "End it", "next_node": ""}
				]
			}
		}
	}
	_setup_dialogue(data)

	DialogueManager.advance_dialogue()
	DialogueManager.select_choice(0)

	_assert(not DialogueManager.is_active, "- dialogue ended with empty target")
