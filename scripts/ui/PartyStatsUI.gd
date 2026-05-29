extends CanvasLayer

@onready var card_list: VBoxContainer = $Panel/Scroll/CardList
@onready var close_btn: Button = $Panel/CloseBtn

const CHAR_PATHS: Array[String] = [
	"res://data/characters/zi.tres",
	"res://data/characters/caelan.tres",
	"res://data/characters/suri.tres",
	"res://data/characters/rynn.tres",
	"res://data/characters/lex.tres",
	"res://data/characters/vyn.tres",
]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	close_btn.pressed.connect(_close)
	_build_cards()


func _build_cards() -> void:
	for path in CHAR_PATHS:
		var data = load(path) as CharacterData
		if data == null:
			continue

		var card = VBoxContainer.new()
		var name_lbl = Label.new()
		name_lbl.text = "[%s]" % data.name
		card.add_child(name_lbl)

		var stats_lbl = Label.new()
		stats_lbl.text = "HP: %d  ATK: %d  DEF: %d  SPD: %d" % [
			data.max_hp, data.attack, data.defense, data.speed
		]
		card.add_child(stats_lbl)

		if data.stances.size() > 0:
			var stance_lbl = Label.new()
			stance_lbl.text = "Stances: %s" % ", ".join(data.stances)
			card.add_child(stance_lbl)

		if data.skills.size() > 0:
			var skill_names: PackedStringArray = []
			for skill in data.skills:
				if skill is SkillData:
					skill_names.append(skill.name)
			if skill_names.size() > 0:
				var skill_lbl = Label.new()
				skill_lbl.text = "Skills: %s" % ", ".join(skill_names)
				card.add_child(skill_lbl)

		var sep = HSeparator.new()
		card.add_child(sep)
		card_list.add_child(card)


func _close() -> void:
	get_tree().paused = false
	queue_free()
