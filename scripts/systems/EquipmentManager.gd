extends RefCounted
class_name EquipmentManager

## Returns total stance bonus multiplier from equipped items for the given stance.
static func get_stance_bonus(equipment: Array[EquipmentData], stance: String) -> float:
	var total: float = 0.0
	for item in equipment:
		if item.stance_bonus == stance and item.stance_bonus != "":
			total += item.stance_bonus_amount
	return total


## Returns combined stat bonuses from all equipped items.
static func get_stat_bonuses(equipment: Array[EquipmentData]) -> Dictionary:
	var combined: Dictionary = {}
	for item in equipment:
		for stat_name in item.stat_bonus:
			combined[stat_name] = combined.get(stat_name, 0) + item.stat_bonus[stat_name]
	return combined


## Returns an array of skill paths unlocked by equipped items.
static func get_unlocked_skills(equipment: Array[EquipmentData]) -> Array[String]:
	var paths: Array[String] = []
	for item in equipment:
		if item.unlocked_skill_path != "":
			paths.append(item.unlocked_skill_path)
	return paths
