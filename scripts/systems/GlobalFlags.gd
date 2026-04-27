extends Node

signal flag_changed(flag_name: String, value: bool)

var flags: Dictionary = {}
var integers: Dictionary = {}

func set_flag(flag_name: String, value: bool) -> void:
	flags[flag_name] = value
	flag_changed.emit(flag_name, value)
	print("[GlobalFlags] Flag '", flag_name, "' set to: ", value)

func get_flag(flag_name: String) -> bool:
	return flags.get(flag_name, false)

func set_int(key: String, value: int) -> void:
	integers[key] = value

func get_int(key: String) -> int:
	return integers.get(key, 0)

func reset() -> void:
	flags.clear()
	integers.clear()
