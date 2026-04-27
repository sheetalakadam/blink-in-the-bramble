extends Node

signal chunk_loaded(coord: Vector2i)
signal chunk_unloaded(coord: Vector2i)

@export var chunk_size: Vector2i = Vector2i(64, 64)
@export var tile_size: int = 32
@export var render_distance: int = 1 # Number of chunks around the player to keep loaded

var loaded_chunks: Dictionary = {} # Vector2i -> Node2D
var active_chunk_coord: Vector2i = Vector2i(-999, -999)

func _ready() -> void:
	# Initial check will be triggered by player spawn
	pass

func update_player_position(pos: Vector2) -> void:
	var world_pixel_size = chunk_size * tile_size
	var current_coord = Vector2i(
		floor(pos.x / world_pixel_size.x),
		floor(pos.y / world_pixel_size.y)
	)
	
	if current_coord != active_chunk_coord:
		active_chunk_coord = current_coord
		_refresh_chunks()

func _refresh_chunks() -> void:
	var needed_coords = []
	for x in range(active_chunk_coord.x - render_distance, active_chunk_coord.x + render_distance + 1):
		for y in range(active_chunk_coord.y - render_distance, active_chunk_coord.y + render_distance + 1):
			needed_coords.append(Vector2i(x, y))
	
	# Unload distant chunks
	var to_unload = []
	for coord in loaded_chunks.keys():
		if coord not in needed_coords:
			to_unload.append(coord)
	
	for coord in to_unload:
		_unload_chunk(coord)
		
	# Load needed chunks
	for coord in needed_coords:
		if coord not in loaded_chunks:
			_load_chunk(coord)

func _load_chunk(coord: Vector2i) -> void:
	# In a real build, we'd use ResourceLoader.load_threaded_request here
	# For now, we'll instance a placeholder or check if a file exists
	var chunk_path = "res://scenes/world/chunks/chunk_%d_%d.tscn" % [coord.x, coord.y]
	
	if FileAccess.file_exists(chunk_path):
		var scene = load(chunk_path)
		var chunk = scene.instantiate()
		var world_pixel_size = chunk_size * tile_size
		chunk.position = Vector2(coord.x * world_pixel_size.x, coord.y * world_pixel_size.y)
		
		get_tree().root.get_node("NaevoriaRuins").add_child(chunk)
		loaded_chunks[coord] = chunk
		chunk_loaded.emit(coord)
	else:
		# Optionally create a default empty chunk for debugging
		pass

func _unload_chunk(coord: Vector2i) -> void:
	if coord in loaded_chunks:
		var chunk = loaded_chunks[coord]
		chunk.queue_free()
		loaded_chunks.erase(coord)
		chunk_unloaded.emit(coord)
