extends Node2D
class_name WorldTemplateBase

## Base script for tilemap-ready world scenes.
##
## Scenes can start with ColorRect placeholders during prototyping.
## When real tilesets are ready, assign the tileset resource to
## the TileMapLayer node and remove the placeholder ColorRects.
##
## Usage:
##   1. Inherit from this scene (or duplicate WorldTemplate.tscn).
##   2. Add your own nodes (NPCs, triggers, etc.) as children.
##   3. When you have a tileset .tres, call setup_tilemap() or
##      assign it directly to the TileMapLayer in the editor.

@onready var tile_map_layer: TileMapLayer = $TileMapLayer


func _ready() -> void:
	if tile_map_layer and tile_map_layer.tile_set == null:
		print("[WorldTemplate] No tileset assigned yet -- using placeholder visuals.")


## Convenience: load a tileset by name via SpriteLoader and assign it.
func setup_tilemap(tileset_name: String) -> bool:
	var ts := SpriteLoader.get_tileset(tileset_name)
	if ts == null:
		push_warning("[WorldTemplate] Tileset '%s' not found." % tileset_name)
		return false
	tile_map_layer.tile_set = ts
	return true
