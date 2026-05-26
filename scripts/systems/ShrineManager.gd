extends Node

## Manages shrine boon activation and consumption.
## Autoloaded singleton — access via ShrineManager.

signal boon_activated(shrine_data: ShrineData)
signal boon_consumed

var active_boon: ShrineData = null


func activate_boon(shrine_data: ShrineData) -> bool:
	if shrine_data.cost_type == "affinity":
		var am = get_node_or_null("/root/AffinityManager")
		if am == null:
			push_error("[ShrineManager] AffinityManager not found")
			return false

		# Find highest-affinity companion to pay the cost
		var highest = am.get_highest_affinity_pair()
		if highest == "":
			return false

		var current = am.get_affinity(highest)
		if current < shrine_data.cost_amount:
			return false

		# Deduct the cost
		am.add_affinity(highest, -shrine_data.cost_amount)

	elif shrine_data.cost_type == "memory":
		var gf = get_node_or_null("/root/GlobalFlags")
		if gf == null:
			push_error("[ShrineManager] GlobalFlags not found")
			return false
		# Memory cost: tracked via GlobalFlags integer counter
		var lore_count = gf.get_int("lore_entries")
		if lore_count < shrine_data.cost_amount:
			return false
		gf.set_int("lore_entries", lore_count - shrine_data.cost_amount)

	active_boon = shrine_data
	boon_activated.emit(shrine_data)
	print("[ShrineManager] Boon activated: %s (%s)" % [shrine_data.boon_name, shrine_data.god_name])
	return true


func consume_boon() -> void:
	if active_boon != null:
		print("[ShrineManager] Boon consumed: %s" % active_boon.boon_name)
		active_boon = null
		boon_consumed.emit()


func has_boon() -> bool:
	return active_boon != null


func get_boon_effect() -> String:
	if active_boon == null:
		return ""
	return active_boon.boon_effect


func reset() -> void:
	active_boon = null
