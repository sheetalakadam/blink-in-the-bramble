extends CanvasLayer

@onready var spoken_text: RichTextLabel = $MainBox/SpokenText
@onready var speaker_label: Label = $MainBox/SpeakerLabel
@onready var inner_monologue: RichTextLabel = $InnerMonologue

func _ready() -> void:
	print("[DialogueUI] ready, connecting signals")
	visible = false
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	DialogueManager.line_presented.connect(_on_line_presented)

func _on_dialogue_started(id: String) -> void:
	print("[DialogueUI] dialogue_started signal received: ", id)
	visible = true

func _on_dialogue_ended() -> void:
	print("[DialogueUI] dialogue_ended signal received")
	visible = false

func _on_line_presented(line_data: Dictionary) -> void:
	print("[DialogueUI] line_presented signal received for speaker: ", line_data.get("speaker"))
	speaker_label.text = line_data.get("speaker", "???")
	spoken_text.text = line_data.get("text", "")
	
	var mono = line_data.get("monologue", "")
	if mono != "":
		inner_monologue.text = "[i]%s[/i]" % mono
		inner_monologue.visible = true
	else:
		inner_monologue.visible = false
