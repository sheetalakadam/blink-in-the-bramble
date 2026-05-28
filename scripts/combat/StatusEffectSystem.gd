class_name StatusEffectSystem
extends RefCounted

## Manages status effects applied during combat.
## Uses entity names as keys since combat entities are dictionaries.

# {entity_name: [{"type": "poison", "turns": 3, "source_attack": 8}, ...]}
static var _active_effects: Dictionary = {}


## Apply a status effect to a target entity.
static func apply_effect(target: Dictionary, effect_type: String, duration: int, source_attack: int) -> void:
	var entity_name: String = target.get("name", "")
	if entity_name == "":
		return

	if not _active_effects.has(entity_name):
		_active_effects[entity_name] = []

	# Don't stack the same effect type — refresh it instead
	var effects: Array = _active_effects[entity_name]
	for i in range(effects.size()):
		if effects[i]["type"] == effect_type:
			effects[i]["turns"] = duration
			effects[i]["source_attack"] = source_attack
			return

	effects.append({
		"type": effect_type,
		"turns": duration,
		"source_attack": source_attack,
	})


## Process effects at the start of an entity's turn. Returns log messages.
static func process_turn_start(entity: Dictionary) -> Array[String]:
	var entity_name: String = entity.get("name", "")
	var messages: Array[String] = []

	if not _active_effects.has(entity_name):
		return messages

	var effects: Array = _active_effects[entity_name]

	for effect in effects:
		match effect["type"]:
			"poison":
				var damage: int = maxi(1, int(effect["source_attack"] * 0.15))
				entity.hp -= damage
				messages.append("%s takes %d poison damage!" % [entity_name, damage])
			"rooted":
				messages.append("%s is rooted and cannot act!" % entity_name)

	return messages


## Process effects at the end of an entity's turn. Decrements durations and removes expired.
static func process_turn_end(entity: Dictionary) -> void:
	var entity_name: String = entity.get("name", "")

	if not _active_effects.has(entity_name):
		return

	var effects: Array = _active_effects[entity_name]
	var remaining: Array = []

	for effect in effects:
		# Permanent effects (duration 0) never expire
		if effect["turns"] <= 0:
			remaining.append(effect)
			continue

		effect["turns"] -= 1
		if effect["turns"] > 0:
			remaining.append(effect)

	_active_effects[entity_name] = remaining


## Check if an entity has a specific effect active.
static func has_effect(entity: Dictionary, effect_type: String) -> bool:
	var entity_name: String = entity.get("name", "")
	if not _active_effects.has(entity_name):
		return false

	for effect in _active_effects[entity_name]:
		if effect["type"] == effect_type:
			return true

	return false


## Consume "marked" effect and return the bonus multiplier (0.3), or 0.0 if not marked.
static func consume_marked(target: Dictionary) -> float:
	var entity_name: String = target.get("name", "")
	if not _active_effects.has(entity_name):
		return 0.0

	var effects: Array = _active_effects[entity_name]
	for i in range(effects.size()):
		if effects[i]["type"] == "marked":
			effects.remove_at(i)
			return 0.3

	return 0.0


## Clear all effects from a specific entity.
static func clear_effects(entity: Dictionary) -> void:
	var entity_name: String = entity.get("name", "")
	_active_effects.erase(entity_name)


## Reset all effects (call at end of combat).
static func reset() -> void:
	_active_effects.clear()


## Get a display string of active effects for an entity, e.g. "[poison][rooted]"
static func get_effect_display(entity: Dictionary) -> String:
	var entity_name: String = entity.get("name", "")
	if not _active_effects.has(entity_name):
		return ""

	var effects: Array = _active_effects[entity_name]
	if effects.is_empty():
		return ""

	var parts: PackedStringArray = []
	for effect in effects:
		parts.append("[%s]" % effect["type"])

	return " " + " ".join(parts)
