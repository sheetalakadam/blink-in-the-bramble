class_name BossController
extends RefCounted

## Manages boss phase transitions during combat.
## Works alongside CombatController — converts BossData into an enemy dictionary
## and handles phase changes when HP crosses thresholds.

signal phase_changed(enemy_dict: Dictionary, phase_index: int, phase_data: Dictionary)


## Creates a combat-ready enemy dictionary from BossData.
## The dict includes all standard enemy fields plus boss-specific metadata.
func create_enemy_dict(boss_data: BossData) -> Dictionary:
	var first_phase: Dictionary = boss_data.phases[0]
	return {
		"name": boss_data.boss_name,
		"hp": boss_data.total_hp,
		"max_hp": boss_data.total_hp,
		"attack": first_phase.attack,
		"defense": first_phase.defense,
		"armor_type": first_phase.armor_type,
		"speed": boss_data.speed,
		"is_enemy": true,
		"is_boss": true,
		"phases": boss_data.phases,
		"boss_data": boss_data,
		"_current_phase_index": 0,
		"_current_attack_name": first_phase.attack_name,
	}


## Checks whether the enemy's HP has crossed a phase threshold.
## If so, updates the enemy dict with new phase stats and returns true.
## Should be called after any damage is applied to a boss enemy.
func check_phase_transition(enemy_dict: Dictionary) -> bool:
	if not enemy_dict.has("phases"):
		return false

	var phases: Array = enemy_dict.phases
	var current_index: int = enemy_dict.get("_current_phase_index", 0)
	var max_hp: int = enemy_dict.max_hp
	var current_hp: int = enemy_dict.hp
	var hp_fraction: float = float(current_hp) / float(max_hp)

	# Find the correct phase for current HP
	# Phases are ordered by threshold descending: [1.0, 0.5, ...]
	# We want the last phase whose threshold >= hp_fraction
	var target_index: int = current_index
	for i in range(current_index + 1, phases.size()):
		var threshold: float = phases[i].hp_threshold
		if hp_fraction <= threshold:
			target_index = i

	if target_index == current_index:
		return false

	# Apply phase transition
	var new_phase: Dictionary = phases[target_index]
	enemy_dict._current_phase_index = target_index
	enemy_dict.armor_type = new_phase.armor_type
	enemy_dict.attack = new_phase.attack
	enemy_dict.defense = new_phase.defense
	enemy_dict._current_attack_name = new_phase.attack_name

	phase_changed.emit(enemy_dict, target_index, new_phase)
	return true


## Returns the telegraph string for a boss enemy showing their current phase attack.
func get_boss_telegraph(enemy_dict: Dictionary) -> String:
	var attack_name: String = enemy_dict.get("_current_attack_name", "Attack")
	return "%s: preparing %s" % [enemy_dict.name, attack_name]


## Called when a boss is defeated. Grants the appropriate milestone.
func on_boss_defeated(boss_data: BossData) -> void:
	var milestone = boss_data.get_milestone_id()
	print("[BossController] Boss '%s' defeated — granting milestone '%s'" % [boss_data.boss_name, milestone])
	PartyManager.grant_milestone(milestone)


## Returns the phase transition log message for the combat log.
static func get_phase_transition_message(enemy_dict: Dictionary, phase_index: int) -> String:
	return "[Boss] %s enters Phase %d!" % [enemy_dict.name, phase_index + 1]
