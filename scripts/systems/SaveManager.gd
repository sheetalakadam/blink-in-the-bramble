extends Node

const SAVE_PATH = "user://save_slot_%d.res"

func save_game(slot: int) -> void:
	var data = SaveData.new()
	
	# Gather data from singletons
	data.party_level = 1 
	data.current_map_chunk = WorldManager.active_chunk_coord
	data.flags = GlobalFlags.flags
	data.affinity_data = {} # Placeholder
	
	data.timestamp = Time.get_datetime_string_from_system()
	
	var err = ResourceSaver.save(data, SAVE_PATH % slot)
	if err == OK:
		print("[SaveManager] Game saved to slot: ", slot)
	else:
		printerr("[SaveManager] Save failed with error: ", err)

func load_game(slot: int) -> SaveData:
	var path = SAVE_PATH % slot
	if not FileAccess.file_exists(path):
		printerr("[SaveManager] No save found at: ", path)
		return null
		
	var data = ResourceLoader.load(path) as SaveData
	if data:
		print("[SaveManager] Game loaded from slot: ", slot)
		# Push data back to singletons
		WorldManager.active_chunk_coord = data.current_map_chunk
		GlobalFlags.flags = data.flags
		return data
	
	return null
