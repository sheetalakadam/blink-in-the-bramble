extends Node

## Autoload singleton managing the player's inventory.
## Items are keyed by their resource path (e.g. "res://data/items/healing_herb.tres").

## inventory[item_path] = { "item": ItemData, "count": int }
var inventory: Dictionary = {}

signal inventory_changed
signal item_used_signal(item_path: String, target: Dictionary)


func add_item(item_path: String, count: int = 1) -> void:
	if inventory.has(item_path):
		var entry: Dictionary = inventory[item_path]
		entry["count"] = mini(entry["count"] + count, entry["item"].max_stack)
	else:
		var item_res = load(item_path) as ItemData
		if item_res == null:
			push_error("[InventoryManager] Failed to load item: %s" % item_path)
			return
		inventory[item_path] = {
			"item": item_res,
			"count": mini(count, item_res.max_stack),
		}
	inventory_changed.emit()


func remove_item(item_path: String, count: int = 1) -> bool:
	if not inventory.has(item_path):
		return false
	var entry: Dictionary = inventory[item_path]
	if entry["count"] < count:
		return false
	entry["count"] -= count
	if entry["count"] <= 0:
		inventory.erase(item_path)
	inventory_changed.emit()
	return true


func has_item(item_path: String, min_count: int = 1) -> bool:
	if not inventory.has(item_path):
		return false
	return inventory[item_path]["count"] >= min_count


func get_count(item_path: String) -> int:
	if not inventory.has(item_path):
		return 0
	return inventory[item_path]["count"]


func use_item(item_path: String, target: Dictionary) -> bool:
	if not inventory.has(item_path):
		return false

	var entry: Dictionary = inventory[item_path]
	var item: ItemData = entry["item"]

	# Only consumables can be used
	if item.item_type != ItemData.ItemType.CONSUMABLE:
		return false

	# Apply effect
	_apply_effect(item, target)

	# Consume one
	remove_item(item_path, 1)
	item_used_signal.emit(item_path, target)
	return true


func get_all_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for path in inventory.keys():
		var entry: Dictionary = inventory[path]
		result.append({
			"path": path,
			"item": entry["item"],
			"count": entry["count"],
		})
	return result


func get_consumables() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for path in inventory.keys():
		var entry: Dictionary = inventory[path]
		if entry["item"].item_type == ItemData.ItemType.CONSUMABLE:
			result.append({
				"path": path,
				"item": entry["item"],
				"count": entry["count"],
			})
	return result


func _apply_effect(item: ItemData, target: Dictionary) -> void:
	match item.effect_type:
		"heal_hp":
			var max_hp: int = target.get("max_hp", 100)
			target["hp"] = mini(target.get("hp", 0) + item.effect_value, max_hp)
		"heal_mp":
			var max_mp: int = target.get("max_mp", 50)
			target["mp"] = mini(target.get("mp", 0) + item.effect_value, max_mp)
		"cure_poison":
			if target.has("status_effects"):
				var effects: Array = target["status_effects"]
				effects.erase("poison")
			# Also clear via StatusEffectSystem if available
			if Engine.has_singleton("StatusEffectSystem") or get_node_or_null("/root/StatusEffectSystem"):
				pass  # StatusEffectSystem uses its own dict; clearing is handled by the system
			target.erase("poisoned")
		"cure_rooted":
			target.erase("rooted")
		"buff_attack":
			target["attack"] = target.get("attack", 10) + item.effect_value
			# Store buff info so combat can track it
			if not target.has("_item_buffs"):
				target["_item_buffs"] = []
			target["_item_buffs"].append({"stat": "attack", "value": item.effect_value})
		"buff_defense":
			target["defense"] = target.get("defense", 10) + item.effect_value
			if not target.has("_item_buffs"):
				target["_item_buffs"] = []
			target["_item_buffs"].append({"stat": "defense", "value": item.effect_value})


func clear() -> void:
	inventory.clear()
	inventory_changed.emit()
