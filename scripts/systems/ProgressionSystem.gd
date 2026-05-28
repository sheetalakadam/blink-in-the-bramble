extends RefCounted
class_name ProgressionSystem

## Maps character names to ordered skill unlock paths.
## Level 1-5:  first two skills available
## Level 6-10: third skill unlocks
## Level 11-15: fourth skill unlocks
## Level 16+: affinity combos available (handled elsewhere)

const SKILL_TABLE: Dictionary = {
	"Zi": [
		"res://data/skills/zi_strike.tres",
		"res://data/skills/zi_read.tres",
		"res://data/skills/zi_cleave.tres",
		"res://data/skills/zi_pressure_point.tres",
	],
	"Caelan": [
		"res://data/skills/caelan_divine_strike.tres",
		"res://data/skills/caelan_remnant_light.tres",
		"res://data/skills/caelan_threshold_hold.tres",
		"res://data/skills/caelan_fracture_touch.tres",
	],
	"Suri": [
		"res://data/skills/suri_quick_strike.tres",
		"res://data/skills/suri_double_tap.tres",
		"res://data/skills/suri_setup_strike.tres",
	],
	"Rynn": [
		"res://data/skills/rynn_snare.tres",
		"res://data/skills/rynn_ereivyn_toxin.tres",
		"res://data/skills/rynn_valdrihn_flash.tres",
		"res://data/skills/rynn_solenne_charm.tres",
		"res://data/skills/rynn_velundrath_vial.tres",
	],
	"Lex": [
		"res://data/skills/lex_pressure_strike.tres",
		"res://data/skills/lex_field_notes.tres",
		"res://data/skills/lex_pattern_break.tres",
		"res://data/skills/lex_studied_strike.tres",
	],
}

## Returns an array of skill resource paths available for a character at a given level.
static func get_available_skills(character_name: String, level: int) -> Array[String]:
	var result: Array[String] = []
	if not SKILL_TABLE.has(character_name):
		return result

	var all_skills: Array = SKILL_TABLE[character_name]

	# Determine how many skills are unlocked based on level
	var unlock_count: int = 0
	if level >= 1:
		unlock_count = mini(2, all_skills.size())  # Base two skills
	if level >= 6:
		unlock_count = mini(3, all_skills.size())   # Third skill
	if level >= 11:
		unlock_count = all_skills.size()             # All remaining skills

	for i in range(unlock_count):
		result.append(all_skills[i])

	return result


## Returns true if affinity combos are available at this level.
static func has_affinity_combos(level: int) -> bool:
	return level >= 16
