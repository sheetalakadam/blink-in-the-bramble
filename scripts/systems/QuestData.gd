extends Resource
class_name QuestData

enum QuestType { MAIN, SIDE, DISCOVERY }

@export var quest_id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var quest_type: QuestType = QuestType.MAIN

## Each entry: {id: String, text: String, flag: String}
@export var objectives: Array[Dictionary] = []

@export var reward_text: String = ""
