class_name VynCombatAI
extends RefCounted

## Vyn's semi-autonomous combat AI.
## Vyn acts on his own each turn — the player does not choose his actions.

## Chooses Vyn's action based on battlefield state.
## Returns {"action": "wild_strike"/"root"/"pack_instinct", "target": enemy_dict}
static func choose_action(vyn: Dictionary, party: Array, enemies: Array, last_target: Dictionary) -> Dictionary:
	var alive_enemies = enemies.filter(func(e): return e.get("hp", 0) > 0)
	if alive_enemies.is_empty():
		return {"action": "wild_strike", "target": {}}

	# Priority 1: Root a dangerous enemy if any party member is below 25% HP
	var party_in_danger = party.filter(func(p): return p.get("hp", 0) > 0 and p.get("hp", 0) < p.get("max_hp", 1) * 0.25)
	if not party_in_danger.is_empty():
		# Find enemy that attacked last turn, otherwise pick highest attack
		var threat = alive_enemies.filter(func(e): return e.get("attacked_last_turn", false))
		if not threat.is_empty():
			return {"action": "root", "target": threat[0]}
		# Fallback: root the enemy with highest attack
		var sorted = alive_enemies.duplicate()
		sorted.sort_custom(func(a, b): return a.get("attack", 0) > b.get("attack", 0))
		return {"action": "root", "target": sorted[0]}

	# Priority 2: Pack Instinct if an ally just attacked a target and it's still alive
	if not last_target.is_empty() and last_target.get("hp", 0) > 0:
		# Find matching enemy in alive list
		for enemy in alive_enemies:
			if enemy.get("name", "") == last_target.get("name", "") and enemy.get("hp", 0) > 0:
				return {"action": "pack_instinct", "target": enemy}

	# Default: Wild Strike on highest HP enemy
	var sorted_hp = alive_enemies.duplicate()
	sorted_hp.sort_custom(func(a, b): return a.get("hp", 0) > b.get("hp", 0))
	return {"action": "wild_strike", "target": sorted_hp[0]}


## Returns damage multiplier based on Zi's HP.
## 1.5x if Zi is below 30% HP, 1.0x otherwise.
static func get_damage_multiplier(vyn: Dictionary, party: Array) -> float:
	for member in party:
		if member.get("name", "") == "Zi":
			var hp_ratio = float(member.get("hp", 0)) / float(member.get("max_hp", 1))
			if hp_ratio < 0.3:
				return 1.5
	return 1.0


## Returns a random variance for Wild Strike (0.7 to 1.3).
static func calculate_wild_strike_variance() -> float:
	return randf_range(0.7, 1.3)
