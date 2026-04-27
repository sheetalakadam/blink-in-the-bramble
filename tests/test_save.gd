extends Node2D

func _ready() -> void:
	print("[TEST_SAVE] Starting Save/Load Test...")
	var global_flags = get_node_or_null("/root/GlobalFlags")
	var save_manager = get_node_or_null("/root/SaveManager")
	
	if not global_flags or not save_manager:
		printerr("[TEST_SAVE] CRITICAL ERROR: Singletons not found!")
		return
	
	# 1. Set a flag
	global_flags.set_flag("test_event_complete", true)
	print("[TEST_SAVE] Current flag state: ", global_flags.get_flag("test_event_complete"))
	
	# 2. Save to slot 99 (test slot)
	save_manager.save_game(99)
	
	# 3. Reset state
	global_flags.reset()
	print("[TEST_SAVE] State reset. Flag is now: ", global_flags.get_flag("test_event_complete"))
	
	# 4. Load from slot 99
	save_manager.load_game(99)
	
	# 5. Assert
	var final_val = global_flags.get_flag("test_event_complete")
	print("[TEST_SAVE] After loading, flag is: ", final_val)
	
	if final_val == true:
		print("[TEST_SAVE] SUCCESS: Data persisted through save/load cycle.")
	else:
		printerr("[TEST_SAVE] FAILED: Data lost!")
