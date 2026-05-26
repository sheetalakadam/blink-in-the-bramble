extends Node2D

## Shrine & God Boon system tests
## Run with: godot --headless --path . tests/test_shrine_boons.tscn

const TAG = "[TEST_SHRINE_BOONS]"

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	print("%s Starting shrine & boon tests..." % TAG)

	# ShrineData resource tests
	_test_shrine_data_resource_creation()
	_test_shrine_data_fields()

	# God boon .tres file loading
	_test_load_auryn_boon()
	_test_load_morrael_boon()
	_test_load_thessia_boon()
	_test_load_varek_boon()
	_test_load_lyenne_boon()

	# ShrineManager tests
	_test_has_boon_default_false()
	_test_activate_boon_sufficient_affinity()
	_test_activate_boon_insufficient_affinity()
	_test_consume_boon_clears_active()
	_test_get_boon_effect()

	# Integration tests
	_test_integration_activate_deducts_affinity()
	_test_integration_activate_consume_cycle()
	_test_integration_boon_activated_signal()
	_test_integration_boon_consumed_signal()

	_report()


func _assert(condition: bool, name: String) -> void:
	if condition:
		_passed += 1
		print("%s PASS: %s" % [TAG, name])
	else:
		_failed += 1
		printerr("%s FAIL: %s" % [TAG, name])


# --- ShrineData resource tests ---

func _test_shrine_data_resource_creation() -> void:
	var data = ShrineData.new()
	_assert(data != null, "ShrineData resource can be created")
	_assert(data is Resource, "ShrineData is a Resource")


func _test_shrine_data_fields() -> void:
	var data = ShrineData.new()
	data.god_name = "Auryn"
	data.boon_name = "Wisdom's Sight"
	data.boon_description = "Reveals all armor types at battle start"
	data.cost_type = "affinity"
	data.cost_amount = 10
	data.boon_effect = "reveal_armor"

	_assert(data.god_name == "Auryn", "god_name field works")
	_assert(data.boon_name == "Wisdom's Sight", "boon_name field works")
	_assert(data.boon_description == "Reveals all armor types at battle start", "boon_description field works")
	_assert(data.cost_type == "affinity", "cost_type field works")
	_assert(data.cost_amount == 10, "cost_amount field works")
	_assert(data.boon_effect == "reveal_armor", "boon_effect field works")


# --- God boon .tres loading ---

func _test_load_auryn_boon() -> void:
	var data = load("res://data/shrines/auryn.tres") as ShrineData
	_assert(data != null, "auryn.tres loads as ShrineData")
	if data == null:
		return
	_assert(data.god_name == "Auryn", "Auryn god_name correct")
	_assert(data.boon_effect == "reveal_armor", "Auryn boon_effect is reveal_armor")
	_assert(data.cost_type == "affinity" or data.cost_type == "memory", "Auryn cost_type valid")


func _test_load_morrael_boon() -> void:
	var data = load("res://data/shrines/morrael.tres") as ShrineData
	_assert(data != null, "morrael.tres loads as ShrineData")
	if data == null:
		return
	_assert(data.god_name == "Morrael", "Morrael god_name correct")
	_assert(data.boon_effect == "auto_revive", "Morrael boon_effect is auto_revive")


func _test_load_thessia_boon() -> void:
	var data = load("res://data/shrines/thessia.tres") as ShrineData
	_assert(data != null, "thessia.tres loads as ShrineData")
	if data == null:
		return
	_assert(data.god_name == "Thessia", "Thessia god_name correct")
	_assert(data.boon_effect == "bond_strike", "Thessia boon_effect is bond_strike")


func _test_load_varek_boon() -> void:
	var data = load("res://data/shrines/varek.tres") as ShrineData
	_assert(data != null, "varek.tres loads as ShrineData")
	if data == null:
		return
	_assert(data.god_name == "Varek", "Varek god_name correct")
	_assert(data.boon_effect == "surge_extend", "Varek boon_effect is surge_extend")


func _test_load_lyenne_boon() -> void:
	var data = load("res://data/shrines/lyenne.tres") as ShrineData
	_assert(data != null, "lyenne.tres loads as ShrineData")
	if data == null:
		return
	_assert(data.god_name == "Lyenne", "Lyenne god_name correct")
	_assert(data.boon_effect == "extra_turn", "Lyenne boon_effect is extra_turn")


# --- ShrineManager tests ---

func _test_has_boon_default_false() -> void:
	var sm = get_node_or_null("/root/ShrineManager")
	_assert(sm != null, "ShrineManager autoload exists")
	if sm == null:
		return

	sm.reset()
	_assert(sm.has_boon() == false, "has_boon is false by default")


func _test_activate_boon_sufficient_affinity() -> void:
	var sm = get_node_or_null("/root/ShrineManager")
	var am = get_node_or_null("/root/AffinityManager")
	if sm == null or am == null:
		_assert(false, "Required autoloads exist for activate test")
		return

	sm.reset()
	am.reset()
	am.add_affinity("Caelan", 30)

	var data = ShrineData.new()
	data.god_name = "Auryn"
	data.boon_name = "Test Boon"
	data.boon_description = "Test"
	data.cost_type = "affinity"
	data.cost_amount = 10
	data.boon_effect = "reveal_armor"

	var result = sm.activate_boon(data)
	_assert(result == true, "activate_boon returns true with sufficient affinity")
	_assert(sm.has_boon() == true, "has_boon is true after activation")
	_assert(sm.active_boon == data, "active_boon is set correctly")

	sm.reset()
	am.reset()


func _test_activate_boon_insufficient_affinity() -> void:
	var sm = get_node_or_null("/root/ShrineManager")
	var am = get_node_or_null("/root/AffinityManager")
	if sm == null or am == null:
		_assert(false, "Required autoloads exist for insufficient test")
		return

	sm.reset()
	am.reset()
	# All affinities start at 0

	var data = ShrineData.new()
	data.god_name = "Auryn"
	data.boon_name = "Test Boon"
	data.boon_description = "Test"
	data.cost_type = "affinity"
	data.cost_amount = 10
	data.boon_effect = "reveal_armor"

	var result = sm.activate_boon(data)
	_assert(result == false, "activate_boon returns false with insufficient affinity")
	_assert(sm.has_boon() == false, "has_boon remains false after failed activation")

	sm.reset()
	am.reset()


func _test_consume_boon_clears_active() -> void:
	var sm = get_node_or_null("/root/ShrineManager")
	var am = get_node_or_null("/root/AffinityManager")
	if sm == null or am == null:
		_assert(false, "Required autoloads exist for consume test")
		return

	sm.reset()
	am.reset()
	am.add_affinity("Caelan", 50)

	var data = ShrineData.new()
	data.god_name = "Morrael"
	data.boon_name = "Rebirth"
	data.boon_description = "Test"
	data.cost_type = "affinity"
	data.cost_amount = 5
	data.boon_effect = "auto_revive"

	sm.activate_boon(data)
	_assert(sm.has_boon() == true, "Boon is active before consume")

	sm.consume_boon()
	_assert(sm.has_boon() == false, "has_boon is false after consume")
	_assert(sm.active_boon == null, "active_boon is null after consume")

	sm.reset()
	am.reset()


func _test_get_boon_effect() -> void:
	var sm = get_node_or_null("/root/ShrineManager")
	var am = get_node_or_null("/root/AffinityManager")
	if sm == null or am == null:
		_assert(false, "Required autoloads exist for effect test")
		return

	sm.reset()
	am.reset()
	am.add_affinity("Caelan", 50)

	_assert(sm.get_boon_effect() == "", "get_boon_effect returns empty when no boon")

	var data = ShrineData.new()
	data.god_name = "Lyenne"
	data.boon_name = "Extra Turn"
	data.boon_description = "Test"
	data.cost_type = "affinity"
	data.cost_amount = 5
	data.boon_effect = "extra_turn"

	sm.activate_boon(data)
	_assert(sm.get_boon_effect() == "extra_turn", "get_boon_effect returns correct effect")

	sm.reset()
	am.reset()


# --- Integration tests ---

func _test_integration_activate_deducts_affinity() -> void:
	var sm = get_node_or_null("/root/ShrineManager")
	var am = get_node_or_null("/root/AffinityManager")
	if sm == null or am == null:
		_assert(false, "Required autoloads exist for deduction test")
		return

	sm.reset()
	am.reset()
	am.add_affinity("Caelan", 40)

	var data = ShrineData.new()
	data.god_name = "Thessia"
	data.boon_name = "Bond Strike"
	data.boon_description = "Test"
	data.cost_type = "affinity"
	data.cost_amount = 15
	data.boon_effect = "bond_strike"

	var before = am.get_affinity("Caelan")
	sm.activate_boon(data)
	var after = am.get_affinity("Caelan")

	_assert(after == before - 15, "Affinity deducted by cost_amount (before: %d, after: %d)" % [before, after])

	sm.reset()
	am.reset()


func _test_integration_activate_consume_cycle() -> void:
	var sm = get_node_or_null("/root/ShrineManager")
	var am = get_node_or_null("/root/AffinityManager")
	if sm == null or am == null:
		_assert(false, "Required autoloads exist for cycle test")
		return

	sm.reset()
	am.reset()
	am.add_affinity("Suri", 50)

	var data = ShrineData.new()
	data.god_name = "Varek"
	data.boon_name = "Surge Extend"
	data.boon_description = "Test"
	data.cost_type = "affinity"
	data.cost_amount = 10
	data.boon_effect = "surge_extend"

	# Activate
	var result = sm.activate_boon(data)
	_assert(result == true, "Cycle: boon activated")
	_assert(sm.has_boon() == true, "Cycle: has_boon true after activate")
	_assert(am.get_affinity("Suri") == 40, "Cycle: affinity deducted to 40")

	# Consume at battle start
	sm.consume_boon()
	_assert(sm.has_boon() == false, "Cycle: has_boon false after consume")

	# Activate again
	var result2 = sm.activate_boon(data)
	_assert(result2 == true, "Cycle: second activation succeeds")
	_assert(am.get_affinity("Suri") == 30, "Cycle: affinity deducted again to 30")

	sm.reset()
	am.reset()


func _test_integration_boon_activated_signal() -> void:
	var sm = get_node_or_null("/root/ShrineManager")
	var am = get_node_or_null("/root/AffinityManager")
	if sm == null or am == null:
		_assert(false, "Required autoloads exist for signal test")
		return

	sm.reset()
	am.reset()
	am.add_affinity("Caelan", 50)

	var signal_received = false
	var received_data: ShrineData = null

	var callback = func(shrine_data: ShrineData) -> void:
		signal_received = true
		received_data = shrine_data

	sm.boon_activated.connect(callback)

	var data = ShrineData.new()
	data.god_name = "Auryn"
	data.boon_name = "Signal Test"
	data.boon_description = "Test"
	data.cost_type = "affinity"
	data.cost_amount = 5
	data.boon_effect = "reveal_armor"

	sm.activate_boon(data)

	_assert(signal_received, "boon_activated signal emitted")
	_assert(received_data == data, "boon_activated signal carries correct data")

	sm.boon_activated.disconnect(callback)
	sm.reset()
	am.reset()


func _test_integration_boon_consumed_signal() -> void:
	var sm = get_node_or_null("/root/ShrineManager")
	var am = get_node_or_null("/root/AffinityManager")
	if sm == null or am == null:
		_assert(false, "Required autoloads exist for consumed signal test")
		return

	sm.reset()
	am.reset()
	am.add_affinity("Caelan", 50)

	var signal_received = false
	var callback = func() -> void:
		signal_received = true

	sm.boon_consumed.connect(callback)

	var data = ShrineData.new()
	data.god_name = "Morrael"
	data.boon_name = "Consume Signal Test"
	data.boon_description = "Test"
	data.cost_type = "affinity"
	data.cost_amount = 5
	data.boon_effect = "auto_revive"

	sm.activate_boon(data)
	sm.consume_boon()

	_assert(signal_received, "boon_consumed signal emitted")

	sm.boon_consumed.disconnect(callback)
	sm.reset()
	am.reset()


func _report() -> void:
	print("%s Results: %d passed, %d failed" % [TAG, _passed, _failed])
	if _failed == 0:
		print("%s SUCCESS" % TAG)
	else:
		printerr("%s FAILED" % TAG)
	if DisplayServer.get_name() == "headless":
		get_tree().quit()
