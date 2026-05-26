extends Node

## Tracks relationship scores between Vyn and companions.
## Autoloaded singleton — access via AffinityManager.

signal affinity_changed(character: String, new_value: int)

# Thresholds
const THRESHOLD_FRIENDLY: int = 25
const THRESHOLD_CLOSE: int = 50
const THRESHOLD_BONDED: int = 75

var _affinity: Dictionary = {
	"Caelan": 0,
	"Suri": 0,
	"Rynn": 0,
	"Lex": 0,
	"Vyn": 0,
}


func add_affinity(character: String, amount: int) -> void:
	var current = _affinity.get(character, 0)
	var new_value = clampi(current + amount, 0, 100)
	_affinity[character] = new_value
	affinity_changed.emit(character, new_value)


func get_affinity(character: String) -> int:
	return _affinity.get(character, 0)


func get_highest_affinity_pair() -> String:
	var highest_name: String = ""
	var highest_value: int = -1
	for character in _affinity:
		if _affinity[character] > highest_value:
			highest_value = _affinity[character]
			highest_name = character
	return highest_name


func get_threshold(character: String) -> String:
	var value = get_affinity(character)
	if value >= THRESHOLD_BONDED:
		return "bonded"
	elif value >= THRESHOLD_CLOSE:
		return "close"
	elif value >= THRESHOLD_FRIENDLY:
		return "friendly"
	return "neutral"


func get_all_affinity() -> Dictionary:
	return _affinity.duplicate()


func set_all_affinity(data: Dictionary) -> void:
	for key in data:
		_affinity[key] = data[key]


func reset() -> void:
	_affinity = {
		"Caelan": 0,
		"Suri": 0,
		"Rynn": 0,
		"Lex": 0,
		"Vyn": 0,
	}
