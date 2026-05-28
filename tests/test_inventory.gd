extends Node2D

## Tests for the inventory and item system.
## Run with: godot --headless --path . tests/test_inventory.tscn

const TAG = "[TEST_INVENTORY]"

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	print("%s Starting inventory tests..." % TAG)
	_test_item_data_resource_fields()
	_test_item_tres_files_load()
	_test_add_item()
	_test_remove_item()
	_test_remove_item_insufficient()
	_test_has_item()
	_test_get_count()
	_test_stack_limit()
	_test_use_consumable_heal_hp()
	_test_use_consumable_buff_attack()
	_test_quest_item_cannot_be_used()
	_test_get_all_items()
	_test_get_consumables_filter()
	_test_clear_inventory()
	_report()


func _assert(condition: bool, name: String) -> void:
	if condition:
		_passed += 1
		print("%s PASS: %s" % [TAG, name])
	else:
		_failed += 1
		printerr("%s FAIL: %s" % [TAG, name])


## --- Test 1: ItemData resource fields ---
func _test_item_data_resource_fields() -> void:
	var item = ItemData.new()
	item.name = "Test Herb"
	item.description = "A test item"
	item.item_type = ItemData.ItemType.CONSUMABLE
	item.effect_type = "heal_hp"
	item.effect_value = 25
	item.max_stack = 10

	_assert(item.name == "Test Herb", "ItemData: name field")
	_assert(item.description == "A test item", "ItemData: description field")
	_assert(item.item_type == ItemData.ItemType.CONSUMABLE, "ItemData: item_type CONSUMABLE")
	_assert(item.effect_type == "heal_hp", "ItemData: effect_type field")
	_assert(item.effect_value == 25, "ItemData: effect_value field")
	_assert(item.max_stack == 10, "ItemData: max_stack field")

	var quest = ItemData.new()
	quest.item_type = ItemData.ItemType.QUEST
	_assert(quest.item_type == ItemData.ItemType.QUEST, "ItemData: item_type QUEST")

	var key = ItemData.new()
	key.item_type = ItemData.ItemType.KEY
	_assert(key.item_type == ItemData.ItemType.KEY, "ItemData: item_type KEY")


## --- Test 2: Item .tres files load correctly ---
func _test_item_tres_files_load() -> void:
	var paths = [
		"res://data/items/healing_herb.tres",
		"res://data/items/antidote.tres",
		"res://data/items/ration.tres",
		"res://data/items/focus_crystal.tres",
		"res://data/items/warding_charm.tres",
		"res://data/items/threshold_shard.tres",
		"res://data/items/old_compass.tres",
	]
	for path in paths:
		var res = load(path)
		_assert(res != null, "Item .tres loads: %s" % path)
		if res != null:
			_assert(res is ItemData, "Item .tres is ItemData: %s" % path)
			_assert(res.name != "", "Item .tres has name: %s" % path)


## --- Test 3: Add item ---
func _test_add_item() -> void:
	InventoryManager.clear()
	InventoryManager.add_item("res://data/items/healing_herb.tres", 3)
	_assert(InventoryManager.get_count("res://data/items/healing_herb.tres") == 3, "add_item: count is 3")

	# Add more to same stack
	InventoryManager.add_item("res://data/items/healing_herb.tres", 2)
	_assert(InventoryManager.get_count("res://data/items/healing_herb.tres") == 5, "add_item: count grows to 5")
	InventoryManager.clear()


## --- Test 4: Remove item ---
func _test_remove_item() -> void:
	InventoryManager.clear()
	InventoryManager.add_item("res://data/items/healing_herb.tres", 5)

	var removed = InventoryManager.remove_item("res://data/items/healing_herb.tres", 2)
	_assert(removed == true, "remove_item: returns true on success")
	_assert(InventoryManager.get_count("res://data/items/healing_herb.tres") == 3, "remove_item: count is 3")

	# Remove all remaining
	InventoryManager.remove_item("res://data/items/healing_herb.tres", 3)
	_assert(InventoryManager.get_count("res://data/items/healing_herb.tres") == 0, "remove_item: fully removed")
	_assert(not InventoryManager.has_item("res://data/items/healing_herb.tres"), "remove_item: no longer in inventory")
	InventoryManager.clear()


## --- Test 5: Remove fails with insufficient count ---
func _test_remove_item_insufficient() -> void:
	InventoryManager.clear()
	InventoryManager.add_item("res://data/items/healing_herb.tres", 2)

	var removed = InventoryManager.remove_item("res://data/items/healing_herb.tres", 5)
	_assert(removed == false, "remove_item: returns false for insufficient count")
	_assert(InventoryManager.get_count("res://data/items/healing_herb.tres") == 2, "remove_item: count unchanged after failed remove")
	InventoryManager.clear()


## --- Test 6: has_item ---
func _test_has_item() -> void:
	InventoryManager.clear()
	_assert(not InventoryManager.has_item("res://data/items/healing_herb.tres"), "has_item: false when empty")
	InventoryManager.add_item("res://data/items/healing_herb.tres", 1)
	_assert(InventoryManager.has_item("res://data/items/healing_herb.tres"), "has_item: true after adding")
	_assert(InventoryManager.has_item("res://data/items/healing_herb.tres", 1), "has_item: true with min_count=1")
	_assert(not InventoryManager.has_item("res://data/items/healing_herb.tres", 5), "has_item: false with min_count=5")
	InventoryManager.clear()


## --- Test 7: get_count ---
func _test_get_count() -> void:
	InventoryManager.clear()
	_assert(InventoryManager.get_count("res://data/items/healing_herb.tres") == 0, "get_count: 0 for missing item")
	InventoryManager.add_item("res://data/items/healing_herb.tres", 7)
	_assert(InventoryManager.get_count("res://data/items/healing_herb.tres") == 7, "get_count: returns 7")
	InventoryManager.clear()


## --- Test 8: Stack limit ---
func _test_stack_limit() -> void:
	InventoryManager.clear()
	# Healing herb has max_stack=10
	InventoryManager.add_item("res://data/items/healing_herb.tres", 15)
	_assert(InventoryManager.get_count("res://data/items/healing_herb.tres") == 10, "stack_limit: capped at 10")

	# Adding more doesn't exceed cap
	InventoryManager.add_item("res://data/items/healing_herb.tres", 5)
	_assert(InventoryManager.get_count("res://data/items/healing_herb.tres") == 10, "stack_limit: stays at 10")

	# Ration has max_stack=5
	InventoryManager.add_item("res://data/items/ration.tres", 10)
	_assert(InventoryManager.get_count("res://data/items/ration.tres") == 5, "stack_limit: ration capped at 5")
	InventoryManager.clear()


## --- Test 9: Use consumable heals HP ---
func _test_use_consumable_heal_hp() -> void:
	InventoryManager.clear()
	InventoryManager.add_item("res://data/items/healing_herb.tres", 3)

	var target = {"name": "Zi", "hp": 50, "max_hp": 100, "attack": 10, "defense": 10}
	var success = InventoryManager.use_item("res://data/items/healing_herb.tres", target)
	_assert(success == true, "use_item: returns true")
	_assert(target["hp"] == 80, "use_item: heals 30 HP (50 -> 80)")
	_assert(InventoryManager.get_count("res://data/items/healing_herb.tres") == 2, "use_item: count decremented")

	# Heal should not exceed max_hp
	target["hp"] = 90
	InventoryManager.use_item("res://data/items/healing_herb.tres", target)
	_assert(target["hp"] == 100, "use_item: does not exceed max_hp")
	InventoryManager.clear()


## --- Test 10: Use consumable buffs attack ---
func _test_use_consumable_buff_attack() -> void:
	InventoryManager.clear()
	InventoryManager.add_item("res://data/items/focus_crystal.tres", 1)

	var target = {"name": "Zi", "hp": 100, "max_hp": 100, "attack": 10, "defense": 10}
	var success = InventoryManager.use_item("res://data/items/focus_crystal.tres", target)
	_assert(success == true, "use_item buff: returns true")
	_assert(target["attack"] == 13, "use_item buff: attack increased by 3")
	_assert(target.has("_item_buffs"), "use_item buff: tracks buff info")
	InventoryManager.clear()


## --- Test 11: Quest items cannot be used ---
func _test_quest_item_cannot_be_used() -> void:
	InventoryManager.clear()
	InventoryManager.add_item("res://data/items/threshold_shard.tres", 1)
	InventoryManager.add_item("res://data/items/old_compass.tres", 1)

	var target = {"name": "Zi", "hp": 100, "max_hp": 100, "attack": 10, "defense": 10}
	var result1 = InventoryManager.use_item("res://data/items/threshold_shard.tres", target)
	_assert(result1 == false, "quest_item: threshold_shard cannot be used")
	_assert(InventoryManager.get_count("res://data/items/threshold_shard.tres") == 1, "quest_item: not consumed")

	var result2 = InventoryManager.use_item("res://data/items/old_compass.tres", target)
	_assert(result2 == false, "quest_item: old_compass cannot be used")
	_assert(InventoryManager.get_count("res://data/items/old_compass.tres") == 1, "quest_item: not consumed")
	InventoryManager.clear()


## --- Test 12: get_all_items returns correct array ---
func _test_get_all_items() -> void:
	InventoryManager.clear()
	InventoryManager.add_item("res://data/items/healing_herb.tres", 2)
	InventoryManager.add_item("res://data/items/threshold_shard.tres", 1)

	var all_items = InventoryManager.get_all_items()
	_assert(all_items.size() == 2, "get_all_items: returns 2 entries")

	var has_herb = false
	var has_shard = false
	for entry in all_items:
		if entry["path"] == "res://data/items/healing_herb.tres":
			has_herb = true
			_assert(entry["count"] == 2, "get_all_items: herb count is 2")
		if entry["path"] == "res://data/items/threshold_shard.tres":
			has_shard = true
			_assert(entry["count"] == 1, "get_all_items: shard count is 1")
	_assert(has_herb, "get_all_items: contains healing herb")
	_assert(has_shard, "get_all_items: contains threshold shard")
	InventoryManager.clear()


## --- Test 13: get_consumables filters out quest items ---
func _test_get_consumables_filter() -> void:
	InventoryManager.clear()
	InventoryManager.add_item("res://data/items/healing_herb.tres", 2)
	InventoryManager.add_item("res://data/items/threshold_shard.tres", 1)
	InventoryManager.add_item("res://data/items/focus_crystal.tres", 1)

	var consumables = InventoryManager.get_consumables()
	_assert(consumables.size() == 2, "get_consumables: returns only 2 consumables")
	for entry in consumables:
		var item: ItemData = entry["item"]
		_assert(item.item_type == ItemData.ItemType.CONSUMABLE, "get_consumables: all are CONSUMABLE type")
	InventoryManager.clear()


## --- Test 14: clear empties inventory ---
func _test_clear_inventory() -> void:
	InventoryManager.add_item("res://data/items/healing_herb.tres", 5)
	InventoryManager.add_item("res://data/items/ration.tres", 3)
	InventoryManager.clear()
	_assert(InventoryManager.get_all_items().size() == 0, "clear: inventory is empty")
	_assert(InventoryManager.get_count("res://data/items/healing_herb.tres") == 0, "clear: herb count is 0")


func _report() -> void:
	print("%s Results: %d passed, %d failed" % [TAG, _passed, _failed])
	if _failed == 0:
		print("%s ALL TESTS PASSED" % TAG)
	else:
		printerr("%s SOME TESTS FAILED" % TAG)
	if DisplayServer.get_name() == "headless":
		get_tree().quit()
