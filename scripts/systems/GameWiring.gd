extends Node

## Autoload that wires game-wide connections: PauseMenu, quest triggers,
## companion recruitment, and dialogue-to-flag bridging.

const PAUSE_MENU_SCENE := "res://scenes/ui/PauseMenu.tscn"

const COMPANION_PATHS := {
	"suri": "res://data/characters/suri.tres",
	"rynn": "res://data/characters/rynn.tres",
	"lex": "res://data/characters/lex.tres",
}

const QUEST_PATHS := {
	"main_01": "res://data/quests/main_01_investigate_ruins.tres",
	"main_02": "res://data/quests/main_02_gather_party.tres",
	"main_03": "res://data/quests/main_03_angel_signs.tres",
}

# Maps dialogue scene IDs to the GlobalFlags they should set on completion.
const DIALOGUE_FLAG_MAP := {
	"scene_04_ereivyn_threshold": "met_rynn",
	"scene_05_suri_arrival": "met_suri",
	"scene_06_rynn_encounter": "met_rynn",
	"scene_07_lex_meeting": "met_lex",
	"scene_10_first_angel_sign": "investigated_distortion",
}

var _pause_menu: CanvasLayer = null


func _ready() -> void:
	_instantiate_pause_menu()
	_connect_flag_signals()
	_connect_dialogue_signals()
	print("[GameWiring] Ready")


# ---------------------------------------------------------------------------
# PauseMenu
# ---------------------------------------------------------------------------

func _instantiate_pause_menu() -> void:
	if not ResourceLoader.exists(PAUSE_MENU_SCENE):
		printerr("[GameWiring] PauseMenu scene not found: %s" % PAUSE_MENU_SCENE)
		return
	var scene := load(PAUSE_MENU_SCENE) as PackedScene
	if scene == null:
		printerr("[GameWiring] Failed to load PauseMenu scene")
		return
	_pause_menu = scene.instantiate()
	add_child(_pause_menu)
	print("[GameWiring] PauseMenu instantiated")


func get_pause_menu() -> CanvasLayer:
	return _pause_menu


# ---------------------------------------------------------------------------
# Flag -> Quest / Recruitment wiring
# ---------------------------------------------------------------------------

func _connect_flag_signals() -> void:
	if GlobalFlags == null:
		printerr("[GameWiring] GlobalFlags autoload not found")
		return
	GlobalFlags.flag_changed.connect(_on_flag_changed)


func _on_flag_changed(flag_name: String, value: bool) -> void:
	if not value:
		return

	# Companion recruitment
	match flag_name:
		"met_suri":
			_recruit_companion("suri")
		"met_rynn":
			_recruit_companion("rynn")
		"met_lex":
			_recruit_companion("lex")

	# Quest triggers
	if flag_name == "met_lex":
		_try_start_quest("main_01")

	if flag_name == "investigated_distortion":
		_try_start_quest("main_03")

	# Check if all 3 companions met -> start main_02
	if flag_name in ["met_suri", "met_rynn", "met_lex"]:
		_check_all_companions_met()


func _recruit_companion(companion_id: String) -> void:
	var path: String = COMPANION_PATHS.get(companion_id, "")
	if path == "" or not ResourceLoader.exists(path):
		printerr("[GameWiring] Companion resource not found: %s" % companion_id)
		return
	if PartyManager.is_recruited(path):
		return
	PartyManager.recruit_character(path)
	print("[GameWiring] Recruited companion: %s" % companion_id)


func _check_all_companions_met() -> void:
	var all_met := (
		GlobalFlags.get_flag("met_suri")
		and GlobalFlags.get_flag("met_rynn")
		and GlobalFlags.get_flag("met_lex")
	)
	if all_met:
		_try_start_quest("main_02")


func _try_start_quest(quest_id: String) -> void:
	if QuestManager.is_quest_active(quest_id) or QuestManager.is_quest_complete(quest_id):
		return
	var path: String = QUEST_PATHS.get(quest_id, "")
	if path == "" or not ResourceLoader.exists(path):
		printerr("[GameWiring] Quest resource not found: %s" % quest_id)
		return
	QuestManager.start_quest(path)
	print("[GameWiring] Started quest: %s" % quest_id)


# ---------------------------------------------------------------------------
# Dialogue -> Flag bridging
# ---------------------------------------------------------------------------

func _connect_dialogue_signals() -> void:
	if DialogueManager == null:
		printerr("[GameWiring] DialogueManager autoload not found")
		return
	if DialogueManager.has_signal("dialogue_completed"):
		DialogueManager.dialogue_completed.connect(_on_dialogue_completed)
	else:
		# Fallback: use dialogue_ended + track the current dialogue id
		DialogueManager.dialogue_started.connect(_on_dialogue_started_track)
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended_fallback)


var _current_dialogue_id: String = ""


func _on_dialogue_started_track(id: String) -> void:
	_current_dialogue_id = id


func _on_dialogue_ended_fallback() -> void:
	if _current_dialogue_id != "":
		_on_dialogue_completed(_current_dialogue_id)
		_current_dialogue_id = ""


func _on_dialogue_completed(scene_id: String) -> void:
	var flag_name: String = DIALOGUE_FLAG_MAP.get(scene_id, "")
	if flag_name != "" and not GlobalFlags.get_flag(flag_name):
		GlobalFlags.set_flag(flag_name, true)
		print("[GameWiring] Dialogue '%s' completed -> set flag '%s'" % [scene_id, flag_name])
