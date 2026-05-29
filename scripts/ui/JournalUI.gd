extends CanvasLayer

signal closed

@onready var quest_list: VBoxContainer = $Panel/HSplit/QuestList
@onready var detail_label: RichTextLabel = $Panel/HSplit/DetailPanel
@onready var tab_main: Button = $Panel/Tabs/MainBtn
@onready var tab_side: Button = $Panel/Tabs/SideBtn
@onready var tab_discovery: Button = $Panel/Tabs/DiscoveryBtn
@onready var close_btn: Button = $Panel/CloseBtn

var _current_filter: int = QuestData.QuestType.MAIN


func _ready() -> void:
	tab_main.pressed.connect(func(): _set_filter(QuestData.QuestType.MAIN))
	tab_side.pressed.connect(func(): _set_filter(QuestData.QuestType.SIDE))
	tab_discovery.pressed.connect(func(): _set_filter(QuestData.QuestType.DISCOVERY))
	close_btn.pressed.connect(_close)
	visible = false


func open() -> void:
	visible = true
	get_tree().paused = true
	_set_filter(_current_filter)


func _close() -> void:
	visible = false
	get_tree().paused = false
	closed.emit()


func _set_filter(filter: int) -> void:
	_current_filter = filter
	_refresh()


func _refresh() -> void:
	for child in quest_list.get_children():
		child.queue_free()
	detail_label.text = ""

	var active := QuestManager.get_active_quests()
	for quest in active:
		if quest.quest_type == _current_filter:
			_add_quest_button(quest, false)

	# Show completed quests dimmed
	for quest_id in QuestManager.get_completed_quests():
		var btn = Button.new()
		btn.text = "[Done] %s" % quest_id
		btn.modulate = Color(0.5, 0.5, 0.5)
		quest_list.add_child(btn)


func _add_quest_button(quest: QuestData, is_complete: bool) -> void:
	var btn = Button.new()
	btn.text = quest.title
	btn.pressed.connect(_show_detail.bind(quest))
	quest_list.add_child(btn)


func _show_detail(quest: QuestData) -> void:
	var objectives := QuestManager.check_objectives(quest.quest_id)
	var text := "[b]%s[/b]\n%s\n\n" % [quest.title, quest.description]
	for obj in objectives:
		var check = "[x]" if obj.completed else "[ ]"
		text += "%s %s\n" % [check, obj.text]
	if quest.reward_text != "":
		text += "\n[i]%s[/i]" % quest.reward_text
	detail_label.text = text
