extends CanvasLayer

const TYPEWRITER_SPEED := 0.03  # seconds per character

@onready var spoken_text: RichTextLabel = $MainBox/SpokenText
@onready var speaker_label: Label = $MainBox/SpeakerLabel
@onready var portrait_rect: TextureRect = $MainBox/PortraitRect
@onready var inner_monologue: RichTextLabel = $InnerMonologue
@onready var lens_label: Label = $LensLabel
@onready var choice_container: VBoxContainer = $ChoiceContainer

var is_typewriting := false
var _typewriter_tween: Tween = null
var _monologue_tween: Tween = null

func _ready() -> void:
	print("[DialogueUI] ready, connecting signals")
	add_to_group("dialogue_ui")
	visible = false
	inner_monologue.modulate.a = 0.0
	inner_monologue.visible = false
	lens_label.visible = false
	portrait_rect.visible = false
	choice_container.visible = false
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	DialogueManager.line_presented.connect(_on_line_presented)
	DialogueManager.choices_presented.connect(_on_choices_presented)

func _on_dialogue_started(id: String) -> void:
	print("[DialogueUI] dialogue_started signal received: ", id)
	visible = true

func _on_dialogue_ended() -> void:
	print("[DialogueUI] dialogue_ended signal received")
	visible = false

func _on_line_presented(line_data: Dictionary) -> void:
	_clear_choices()
	print("[DialogueUI] line_presented signal received for speaker: ", line_data.get("speaker"))

	# Speaker name
	speaker_label.text = line_data.get("speaker", "???")

	# Portrait display
	var portrait_state: String = line_data.get("portrait_state", "")
	if portrait_state != "":
		var speaker: String = line_data.get("speaker", "").to_lower().replace(" ", "_")
		var portrait_tex := SpriteLoader.get_portrait(speaker, portrait_state)
		if portrait_tex:
			portrait_rect.texture = portrait_tex
			portrait_rect.visible = true
		else:
			portrait_rect.visible = false
	else:
		portrait_rect.visible = false

	# Spoken text with typewriter effect
	spoken_text.text = line_data.get("text", "")
	_start_typewriter()

	# Monologue display
	var mono = line_data.get("monologue", "")
	if mono != "":
		inner_monologue.text = "[i]%s[/i]" % mono
		_fade_monologue_in()
	else:
		_fade_monologue_out()

	# Lens display
	var lens = line_data.get("lens", "")
	if lens != "":
		lens_label.text = "[%s]" % lens.capitalize()
		lens_label.visible = true
	else:
		lens_label.visible = false

func _start_typewriter() -> void:
	# Kill any existing typewriter tween
	if _typewriter_tween and _typewriter_tween.is_valid():
		_typewriter_tween.kill()

	spoken_text.visible_ratio = 0.0
	is_typewriting = true

	var char_count = spoken_text.get_parsed_text().length()
	var duration = char_count * TYPEWRITER_SPEED
	if duration <= 0.0:
		# Empty text, complete immediately
		spoken_text.visible_ratio = 1.0
		is_typewriting = false
		return

	_typewriter_tween = create_tween()
	_typewriter_tween.tween_property(spoken_text, "visible_ratio", 1.0, duration)
	_typewriter_tween.finished.connect(_on_typewriter_finished)

func _on_typewriter_finished() -> void:
	is_typewriting = false

func skip_typewriter() -> void:
	if _typewriter_tween and _typewriter_tween.is_valid():
		_typewriter_tween.kill()
	spoken_text.visible_ratio = 1.0
	is_typewriting = false

func _fade_monologue_in() -> void:
	if _monologue_tween and _monologue_tween.is_valid():
		_monologue_tween.kill()
	inner_monologue.visible = true
	_monologue_tween = create_tween()
	_monologue_tween.tween_property(inner_monologue, "modulate:a", 1.0, 0.3)

func _fade_monologue_out() -> void:
	if _monologue_tween and _monologue_tween.is_valid():
		_monologue_tween.kill()
	inner_monologue.visible = false
	inner_monologue.modulate.a = 0.0

func _on_choices_presented(choices: Array) -> void:
	_clear_choices()
	choice_container.visible = true
	for i in choices.size():
		var choice = choices[i]
		var btn := Button.new()
		btn.text = choice.get("text", choice.get("label", "..."))
		btn.pressed.connect(_on_choice_selected.bind(i))
		choice_container.add_child(btn)
	# Focus first button for keyboard nav
	if choice_container.get_child_count() > 0:
		choice_container.get_child(0).grab_focus()

func _on_choice_selected(index: int) -> void:
	_clear_choices()
	DialogueManager.select_choice(index)

func _clear_choices() -> void:
	choice_container.visible = false
	for child in choice_container.get_children():
		child.queue_free()
