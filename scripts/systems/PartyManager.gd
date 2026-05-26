extends Node

## Manages the active party roster and milestone-based leveling.
## Autoloaded singleton — access via PartyManager.

signal level_up(new_level: int)
signal party_changed

const MAX_PARTY_SIZE: int = 4  # Vyn + 3 companions

var party_level: int = 1
var _active_party: Array[CharacterData] = []
var _granted_milestones: Array[String] = []


func get_active_party() -> Array[CharacterData]:
	return _active_party


func add_to_party(char_data: CharacterData) -> void:
	if _active_party.size() >= MAX_PARTY_SIZE:
		print("[PartyManager] Party full, cannot add: ", char_data.name)
		return

	# Prevent duplicates
	for member in _active_party:
		if member.name == char_data.name:
			print("[PartyManager] %s already in party" % char_data.name)
			return

	_active_party.append(char_data)
	party_changed.emit()
	print("[PartyManager] Added %s to party" % char_data.name)


func remove_from_party(char_name: String) -> void:
	for i in range(_active_party.size()):
		if _active_party[i].name == char_name:
			_active_party.remove_at(i)
			party_changed.emit()
			print("[PartyManager] Removed %s from party" % char_name)
			return
	print("[PartyManager] %s not found in party" % char_name)


func grant_milestone(milestone_name: String) -> void:
	if milestone_name in _granted_milestones:
		print("[PartyManager] Milestone '%s' already granted" % milestone_name)
		return

	_granted_milestones.append(milestone_name)
	party_level += 1
	_apply_level_up()
	level_up.emit(party_level)
	print("[PartyManager] Milestone '%s' granted — party level now %d" % [milestone_name, party_level])


func _apply_level_up() -> void:
	for member in _active_party:
		# HP +10%, attack +1, defense +1 per level up
		member.max_hp = int(member.max_hp * 1.1)
		member.attack += 1
		member.defense += 1


func get_granted_milestones() -> Array[String]:
	return _granted_milestones


func reset() -> void:
	party_level = 1
	_active_party.clear()
	_granted_milestones.clear()
