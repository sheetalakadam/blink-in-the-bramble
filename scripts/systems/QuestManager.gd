extends Node

signal quest_started(quest_id: String)
signal quest_completed(quest_id: String)
signal objective_completed(quest_id: String, objective_id: String)

var _active: Dictionary = {}   # quest_id -> QuestData
var _completed: Array[String] = []
var _completed_objectives: Dictionary = {}  # quest_id -> Array[String]


func start_quest(quest_path: String) -> void:
	var data = load(quest_path) as QuestData
	if data == null or data.quest_id == "":
		return
	if _active.has(data.quest_id) or data.quest_id in _completed:
		return
	_active[data.quest_id] = data
	_completed_objectives[data.quest_id] = []
	quest_started.emit(data.quest_id)
	print("[QuestManager] Started: %s" % data.title)


func complete_quest(quest_id: String) -> void:
	if not _active.has(quest_id):
		return
	_active.erase(quest_id)
	_completed.append(quest_id)
	quest_completed.emit(quest_id)
	print("[QuestManager] Completed: %s" % quest_id)


func is_quest_active(quest_id: String) -> bool:
	return _active.has(quest_id)


func is_quest_complete(quest_id: String) -> bool:
	return quest_id in _completed


func get_active_quests() -> Array[QuestData]:
	var result: Array[QuestData] = []
	for data in _active.values():
		result.append(data)
	return result


func check_objectives(quest_id: String) -> Array[Dictionary]:
	if not _active.has(quest_id):
		return []
	var data: QuestData = _active[quest_id]
	var result: Array[Dictionary] = []
	var done_list: Array = _completed_objectives.get(quest_id, [])

	for obj in data.objectives:
		var flag_name: String = obj.get("flag", "")
		var is_done: bool = flag_name != "" and GlobalFlags.get_flag(flag_name)
		if is_done and obj.get("id", "") not in done_list:
			done_list.append(obj.get("id", ""))
			_completed_objectives[quest_id] = done_list
			objective_completed.emit(quest_id, obj.get("id", ""))
		result.append({
			"id": obj.get("id", ""),
			"text": obj.get("text", ""),
			"completed": is_done,
		})

	# Auto-complete quest if all objectives done
	var all_done := true
	for r in result:
		if not r.completed:
			all_done = false
			break
	if all_done and result.size() > 0:
		complete_quest(quest_id)

	return result


func get_completed_quests() -> Array[String]:
	return _completed.duplicate()


func reset() -> void:
	_active.clear()
	_completed.clear()
	_completed_objectives.clear()
