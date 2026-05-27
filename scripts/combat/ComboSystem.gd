extends RefCounted
class_name ComboSystem

## Affinity combo system. Detects when paired characters trigger bonus effects
## through specific action sequences. Combos are discovered through play.

static var _last_actions: Dictionary = {}

# Combo definitions: each entry maps a pair + trigger to an effect
const AFFINITY_THRESHOLD: int = 50

static func record_action(char_name: String, action_name: String) -> void:
	_last_actions[char_name] = action_name

static func reset() -> void:
	_last_actions = {}

static func check_combo(attacker: Dictionary, action_name: String, next_actor: Dictionary, all_combatants: Array) -> Dictionary:
	var inactive := {"active": false}
	var attacker_name: String = attacker.get("name", "")

	# Zi + Caelan: Zi uses Read, Caelan attacks next -> +50% damage
	if attacker_name == "Caelan" and _last_actions.get("Zi") == "Read":
		if _pair_has_affinity("Zi", "Caelan"):
			return {
				"active": true,
				"type": "zi_caelan_read",
				"bonus": 0.5,
				"message": "[Combo] Zi and Caelan \u2014 Studied Strike! +50% damage"
			}

	# Suri + Zi: Suri uses Setup Strike, Zi attacks next -> armor pierce
	if attacker_name == "Zi" and _last_actions.get("Suri") == "Setup Strike":
		if _pair_has_affinity("Zi", "Suri"):
			return {
				"active": true,
				"type": "suri_zi_setup",
				"bonus": 0.3,
				"message": "[Combo] Suri and Zi \u2014 Piercing Follow-up! Armor pierce"
			}

	# Rynn + Lex: Lex uses Field Notes, Rynn attacks next -> hits all weak points
	if attacker_name == "Rynn" and _last_actions.get("Lex") == "Field Notes":
		if _pair_has_affinity("Rynn", "Lex"):
			return {
				"active": true,
				"type": "rynn_lex_fieldnotes",
				"bonus": 0.4,
				"message": "[Combo] Lex and Rynn \u2014 Marked Quarry! Hits all weak points"
			}

	# Suri + Vyn: Suri uses Stand Beside for Vyn -> Vyn retaliates twice
	if attacker_name == "Vyn" and _last_actions.get("Suri") == "Stand Beside":
		if _pair_has_affinity("Suri", "Vyn"):
			return {
				"active": true,
				"type": "suri_vyn_standbeside",
				"bonus": 1.0,
				"message": "[Combo] Suri and Vyn \u2014 Shoulder to Shoulder! Double retaliation"
			}

	return inactive

static func get_passive_bonus(party: Array, enemies: Array) -> float:
	# Caelan + Lex: Both in party vs Spirit enemies -> +20% damage to spirits
	var has_caelan := false
	var has_lex := false
	for member in party:
		if member.get("name") == "Caelan":
			has_caelan = true
		elif member.get("name") == "Lex":
			has_lex = true

	if has_caelan and has_lex and _pair_has_affinity("Caelan", "Lex"):
		var has_spirit := false
		for enemy in enemies:
			if enemy.get("type", "") == "Spirit":
				has_spirit = true
				break
		if has_spirit:
			return 0.2

	return 0.0

static func has_combo_available(entity_name: String, next_entity_name: String) -> bool:
	## Quick check for combo indicator in turn queue display.
	## Returns true if a combo might fire for entity_name given the current state.
	# Check if entity is the attacker in any combo that could trigger
	if entity_name == "Caelan" and _last_actions.get("Zi") == "Read":
		if _pair_has_affinity("Zi", "Caelan"):
			return true
	if entity_name == "Zi" and _last_actions.get("Suri") == "Setup Strike":
		if _pair_has_affinity("Zi", "Suri"):
			return true
	if entity_name == "Rynn" and _last_actions.get("Lex") == "Field Notes":
		if _pair_has_affinity("Rynn", "Lex"):
			return true
	if entity_name == "Vyn" and _last_actions.get("Suri") == "Stand Beside":
		if _pair_has_affinity("Suri", "Vyn"):
			return true
	return false

static func _pair_has_affinity(char_a: String, char_b: String) -> bool:
	## Check if both characters in a pair meet the affinity threshold.
	## Since AffinityManager tracks each character's affinity (with the player/party),
	## we require both members to be at or above the close threshold.
	var affinity_a: int = AffinityManager.get_affinity(char_a)
	var affinity_b: int = AffinityManager.get_affinity(char_b)
	# For Vyn (player character), affinity is always considered max
	if char_a == "Vyn":
		affinity_a = 100
	if char_b == "Vyn":
		affinity_b = 100
	return affinity_a >= AFFINITY_THRESHOLD and affinity_b >= AFFINITY_THRESHOLD
