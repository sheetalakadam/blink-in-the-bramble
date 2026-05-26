extends Node

const SAVE_PATH = "user://save_slot_%d.res"

func save_game(slot: int) -> void:
	var data = SaveData.new()

	# Gather data from singletons
	data.party_level = PartyManager.party_level
	data.granted_milestones = PartyManager.get_granted_milestones()
	data.current_map_chunk = WorldManager.active_chunk_coord
	data.flags = GlobalFlags.flags
	data.affinity_data = AffinityManager.get_all_affinity()

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
		PartyManager.party_level = data.party_level
		PartyManager._granted_milestones = data.granted_milestones
		AffinityManager.set_all_affinity(data.affinity_data)
		return data

	return null
