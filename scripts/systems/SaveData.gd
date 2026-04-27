extends Resource
class_name SaveData

@export var party_level: int = 1
@export var current_map_chunk: Vector2i = Vector2i.ZERO
@export var player_position: Vector2 = Vector2.ZERO
@export var flags: Dictionary = {}
@export var affinity_data: Dictionary = {}
@export var inventory_data: Dictionary = {}
@export var timestamp: String = ""
