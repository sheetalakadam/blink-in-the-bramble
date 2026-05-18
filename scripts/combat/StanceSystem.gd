extends RefCounted
class_name StanceSystem

# Stance advantage mappings: stance_name -> armor_type it's strong against
const STANCE_ADVANTAGES: Dictionary = {
	# Zi
	"Soldier's Edge": "",        # neutral
	"Counter Step": "Agile",     # advantage vs Agile
	"Iron Wall": "Heavy",        # advantage vs Heavy
	# Caelan
	"Threshold": "Corrupted",
	"Gentle Current": "Spirit",
	"Fractured Form": "",        # universal, high cost
	# Suri
	"Market Way": "Agile",
	"Harbor Guard": "Heavy",
	"Open Hand": "",             # support stance
}

const ADVANTAGE_MULT: float = 1.3
const NEUTRAL_MULT: float = 1.0
const DISADVANTAGE_MULT: float = 0.6

static func get_multiplier(stance_name: String, enemy_armor: String) -> float:
	if enemy_armor == "" or stance_name == "":
		return NEUTRAL_MULT
	var advantage = STANCE_ADVANTAGES.get(stance_name, "")
	if advantage == "":
		return NEUTRAL_MULT
	if advantage == enemy_armor:
		return ADVANTAGE_MULT
	return NEUTRAL_MULT
