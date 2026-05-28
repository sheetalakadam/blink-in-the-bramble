extends RefCounted
class_name BattleRewards

## Calculates post-combat rewards: milestone XP, affinity gains, and loot.
## This is a static utility class — no instance needed.

# XP values by enemy type (milestone-based, not grind-based)
const XP_BOSS: int = 50
const XP_NORMAL: int = 10
const XP_SPIRIT: int = 15

# Affinity gains
const AFFINITY_FOUGHT_TOGETHER: int = 5
const AFFINITY_COMBO_BONUS: int = 10


static func calculate_rewards(party: Array[Dictionary], enemies: Array[Dictionary]) -> Dictionary:
	var result: Dictionary = {
		"milestone_xp": 0,
		"affinity_gains": {},
		"loot": [] as Array[String],
	}

	# --- Milestone XP based on enemy types ---
	for enemy in enemies:
		var enemy_type: String = enemy.get("type", "normal").to_lower()
		if enemy.get("is_boss", false) or enemy_type == "boss":
			result.milestone_xp += XP_BOSS
		elif enemy_type == "spirit":
			result.milestone_xp += XP_SPIRIT
		else:
			result.milestone_xp += XP_NORMAL

	# --- Affinity gains for each pair that fought together ---
	var alive_names: Array[String] = []
	for member in party:
		if not member.get("is_enemy", false):
			alive_names.append(member.get("name", ""))

	# Every pair of party members who fought together gets +5
	for i in range(alive_names.size()):
		for j in range(i + 1, alive_names.size()):
			var name_a: String = alive_names[i]
			var name_b: String = alive_names[j]
			if not result.affinity_gains.has(name_a):
				result.affinity_gains[name_a] = 0
			if not result.affinity_gains.has(name_b):
				result.affinity_gains[name_b] = 0
			result.affinity_gains[name_a] += AFFINITY_FOUGHT_TOGETHER
			result.affinity_gains[name_b] += AFFINITY_FOUGHT_TOGETHER

	# --- Combo bonus: check if any combos triggered during combat ---
	# ComboSystem._last_actions tracks actions recorded during combat.
	# If any combo actions were recorded for a pair, they get a bonus.
	var combo_pairs := _detect_combo_pairs(party)
	for pair in combo_pairs:
		var name_a: String = pair[0]
		var name_b: String = pair[1]
		if not result.affinity_gains.has(name_a):
			result.affinity_gains[name_a] = 0
		if not result.affinity_gains.has(name_b):
			result.affinity_gains[name_b] = 0
		result.affinity_gains[name_a] += AFFINITY_COMBO_BONUS
		result.affinity_gains[name_b] += AFFINITY_COMBO_BONUS

	# --- Loot from enemy drops ---
	for enemy in enemies:
		var drops: Array = enemy.get("drops", [])
		for drop in drops:
			if drop is String and drop != "":
				result.loot.append(drop)

	return result


static func _detect_combo_pairs(party: Array[Dictionary]) -> Array:
	## Returns an array of [name_a, name_b] pairs that triggered combos.
	## We check ComboSystem._last_actions for evidence of combo setups.
	var pairs: Array = []
	var last_actions: Dictionary = ComboSystem._last_actions

	# Check known combo chains
	if last_actions.has("Zi") and last_actions.get("Zi") == "Read":
		if _has_member(party, "Caelan"):
			pairs.append(["Zi", "Caelan"])

	if last_actions.has("Suri") and last_actions.get("Suri") == "Setup Strike":
		if _has_member(party, "Zi"):
			pairs.append(["Suri", "Zi"])

	if last_actions.has("Lex") and last_actions.get("Lex") == "Field Notes":
		if _has_member(party, "Rynn"):
			pairs.append(["Lex", "Rynn"])

	if last_actions.has("Suri") and last_actions.get("Suri") == "Stand Beside":
		if _has_member(party, "Vyn"):
			pairs.append(["Suri", "Vyn"])

	return pairs


static func _has_member(party: Array[Dictionary], name: String) -> bool:
	for member in party:
		if member.get("name", "") == name:
			return true
	return false


static func get_level_for_xp(total_xp: int) -> int:
	## Returns the level for a given XP total.
	## Milestone-based thresholds — not a grind curve.
	if total_xp >= 200:
		return 5
	elif total_xp >= 120:
		return 4
	elif total_xp >= 60:
		return 3
	elif total_xp >= 25:
		return 2
	return 1


static func check_level_up(old_xp: int, new_xp: int) -> bool:
	## Returns true if gaining this XP crosses a level threshold.
	return get_level_for_xp(new_xp) > get_level_for_xp(old_xp)
