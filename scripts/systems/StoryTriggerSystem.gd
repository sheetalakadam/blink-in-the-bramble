class_name StoryTriggerSystem
extends RefCounted

## Maps region names to story dialogue triggers.
## Each trigger has a required flag (must be set) and a done flag (must NOT be set).
## When a world scene loads, it calls check_triggers(region) to fire the next story beat.

# Each entry: { "dialogue": String, "requires": String, "done_flag": String }
# requires = "" means always eligible (just checks done_flag)

static func check_triggers(region: String) -> String:
	var triggers: Array = REGION_TRIGGERS.get(region, [])
	for t in triggers:
		var req: String = t.get("requires", "")
		var done: String = t.get("done_flag", "")
		if done != "" and GlobalFlags.get_flag(done):
			continue
		if req != "" and not GlobalFlags.get_flag(req):
			continue
		return t.dialogue
	return ""


static func mark_done(dialogue_id: String) -> void:
	var done_flag := dialogue_id + "_done"
	GlobalFlags.set_flag(done_flag, true)


static var REGION_TRIGGERS: Dictionary = {
	"naevoria": [
		{"dialogue": "scene_02_first_steps", "requires": "opening_dialogue_done", "done_flag": "scene_02_first_steps_done"},
		{"dialogue": "scene_10_first_angel_sign", "requires": "met_suri", "done_flag": "scene_10_first_angel_sign_done"},
		{"dialogue": "scene_16_return_to_ruins", "requires": "scene_15_party_reckoning_done", "done_flag": "scene_16_return_to_ruins_done"},
		{"dialogue": "scene_17_caelan_threshold", "requires": "scene_16_return_to_ruins_done", "done_flag": "scene_17_caelan_threshold_done"},
		{"dialogue": "scene_18_angel_direct", "requires": "scene_17_caelan_threshold_done", "done_flag": "scene_18_angel_direct_done"},
		{"dialogue": "scene_19_resolution", "requires": "scene_18_angel_direct_done", "done_flag": "scene_19_resolution_done"},
	],
	"valdrihn": [
		{"dialogue": "scene_05_suri_arrival", "requires": "valdrihn_gate_dialogue_done", "done_flag": "scene_05_suri_arrival_done"},
		{"dialogue": "scene_14_angel_encounter", "requires": "scene_13_velundrath_archive_done", "done_flag": "scene_14_angel_encounter_done"},
		{"dialogue": "scene_15_party_reckoning", "requires": "scene_14_angel_encounter_done", "done_flag": "scene_15_party_reckoning_done"},
	],
	"ereivyn": [
		{"dialogue": "scene_06_rynn_encounter", "requires": "ereivyn_threshold_dialogue_done", "done_flag": "scene_06_rynn_encounter_done"},
		{"dialogue": "scene_11_caelan_memory_fragment", "requires": "scene_10_first_angel_sign_done", "done_flag": "scene_11_caelan_memory_fragment_done"},
	],
	"solenne": [
		{"dialogue": "scene_07_lex_meeting", "requires": "solenne_arrival_dialogue_done", "done_flag": "scene_07_lex_meeting_done"},
		{"dialogue": "scene_12_solenne_crisis", "requires": "scene_11_caelan_memory_fragment_done", "done_flag": "scene_12_solenne_crisis_done"},
	],
	"velundrath": [
		{"dialogue": "scene_13_velundrath_archive", "requires": "scene_12_solenne_crisis_done", "done_flag": "scene_13_velundrath_archive_done"},
	],
}
