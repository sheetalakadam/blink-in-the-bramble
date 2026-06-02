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
	data.inventory_data = InventoryManager.get_save_data()

	# Save player position and current scene
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		data.player_position = players[0].global_position
	if get_tree().current_scene:
		data.current_scene_path = get_tree().current_scene.scene_file_path

	# Save defeated enemies
	if get_node_or_null("/root/BattleTransition"):
		data.defeated_enemies = BattleTransition.defeated_enemies.duplicate()

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
		InventoryManager.load_save_data(data.inventory_data)

		# Restore defeated enemies
		if get_node_or_null("/root/BattleTransition"):
			BattleTransition.defeated_enemies = data.defeated_enemies.duplicate()

		# Store pending position for the world scene to restore
		_pending_position = data.player_position
		_has_pending_position = true

		# Change to the saved scene
		if data.current_scene_path != "":
			get_tree().change_scene_to_file(data.current_scene_path)

		return data

	return null


## Pending player position from a loaded save. World scenes call consume_pending_position()
## in _ready() to restore the player's location.
var _pending_position: Vector2 = Vector2.ZERO
var _has_pending_position: bool = false


func consume_pending_position() -> Vector2:
	if _has_pending_position:
		_has_pending_position = false
		return _pending_position
	return Vector2.ZERO


func has_pending_position() -> bool:
	return _has_pending_position
