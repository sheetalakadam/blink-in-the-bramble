extends RefCounted
class_name SpriteLoader

## Loads sprite and portrait textures from the asset directories.
## Returns null when a file is missing, allowing callers to fall back
## to coloured-rect placeholders without crashing.

const CHARACTER_SPRITE_DIR := "res://assets/sprites/characters/"
const ENEMY_SPRITE_DIR := "res://assets/sprites/enemies/"
const PORTRAIT_DIR := "res://assets/portraits/"
const TILESET_DIR := "res://assets/tilesets/"


static func get_character_sprite(char_name: String) -> Texture2D:
	var path := CHARACTER_SPRITE_DIR + char_name + ".png"
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


static func get_enemy_sprite(enemy_name: String) -> Texture2D:
	var slug := enemy_name.to_lower().replace(" ", "_").replace("é", "e")
	var path := ENEMY_SPRITE_DIR + slug + ".png"
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


static func get_portrait(char_name: String, state: String) -> Texture2D:
	var path := PORTRAIT_DIR + char_name + "_" + state + ".png"
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


static func get_tileset(tileset_name: String) -> TileSet:
	var path := TILESET_DIR + tileset_name + ".tres"
	if not ResourceLoader.exists(path):
		return null
	return load(path) as TileSet
