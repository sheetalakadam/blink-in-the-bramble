class_name EncounterTable
extends RefCounted

## Returns a randomized enemy formation for the given region.
static func get_encounter(region: String) -> Array[Dictionary]:
	var table: Array = ENCOUNTERS.get(region, ENCOUNTERS.get("naevoria", []))
	if table.is_empty():
		return [_make("Green Slime", 20, 5, 0, 5, "Agile")]
	var formation: Array = table[randi() % table.size()]
	var result: Array[Dictionary] = []
	for enemy in formation:
		result.append(enemy.duplicate(true))
	return result


static func _make(n: String, hp: int, atk: int, def: int, spd: int, armor: String, drops: Array[String] = []) -> Dictionary:
	return {
		"name": n, "hp": hp, "max_hp": hp,
		"attack": atk, "defense": def, "speed": spd,
		"armor_type": armor, "is_enemy": true, "drops": drops,
	}


const ENCOUNTERS: Dictionary = {
	"naevoria": [
		[_make("Green Slime", 20, 5, 0, 5, "Agile", ["res://data/items/healing_herb.tres"])],
		[_make("Green Slime", 20, 5, 0, 5, "Agile"), _make("Green Slime", 20, 5, 0, 5, "Agile")],
		[_make("Corrupted Husk", 40, 14, 4, 8, "Magic", ["res://data/items/antidote.tres"])],
	],
	"valdrihn": [
		[_make("Valdrihn Soldier", 35, 12, 10, 6, "Heavy", ["res://data/items/warding_charm.tres"])],
		[_make("Valdrihn Scout", 25, 10, 5, 10, "Agile"), _make("Valdrihn Scout", 25, 10, 5, 10, "Agile")],
		[_make("Valdrihn Soldier", 35, 12, 10, 6, "Heavy"), _make("Valdrihn Scout", 25, 10, 5, 10, "Agile")],
		[_make("Valdrihn Captain", 50, 15, 12, 5, "Heavy", ["res://data/items/focus_crystal.tres"])],
		[_make("Valdrihn Soldier", 35, 12, 10, 6, "Heavy"), _make("Valdrihn Soldier", 35, 12, 10, 6, "Heavy"), _make("Valdrihn Scout", 25, 10, 5, 10, "Agile")],
	],
	"solenne": [
		[_make("Solenné Scout", 30, 11, 3, 8, "Agile", ["res://data/items/healing_herb.tres"])],
		[_make("Solenné Pickpocket", 20, 8, 3, 12, "Agile"), _make("Solenné Pickpocket", 20, 8, 3, 12, "Agile"), _make("Solenné Pickpocket", 20, 8, 3, 12, "Agile")],
		[_make("Solenné Enforcer", 40, 14, 8, 7, "Heavy", ["res://data/items/focus_crystal.tres"])],
		[_make("Solenné Scout", 30, 11, 3, 8, "Agile"), _make("Solenné Enforcer", 40, 14, 8, 7, "Heavy")],
	],
	"ereivyn": [
		[_make("Ereivyn Wisp", 25, 9, 4, 9, "Spirit", ["res://data/items/antidote.tres"])],
		[_make("Ereivyn Shade", 30, 11, 5, 8, "Magic"), _make("Ereivyn Wisp", 25, 9, 4, 9, "Spirit")],
		[_make("Ereivyn Thorn Beast", 45, 13, 7, 6, "Heavy", ["res://data/items/ration.tres"])],
		[_make("Ereivyn Shade", 30, 11, 5, 8, "Magic"), _make("Ereivyn Shade", 30, 11, 5, 8, "Magic")],
		[_make("Ereivyn Wisp", 25, 9, 4, 9, "Spirit"), _make("Ereivyn Wisp", 25, 9, 4, 9, "Spirit"), _make("Ereivyn Thorn Beast", 45, 13, 7, 6, "Heavy")],
	],
	"velundrath": [
		[_make("Velundrath Guardian", 40, 13, 8, 5, "Heavy", ["res://data/items/warding_charm.tres"])],
		[_make("Velundrath Tide Caller", 35, 12, 6, 7, "Magic"), _make("Velundrath Guardian", 40, 13, 8, 5, "Heavy")],
		[_make("Velundrath Archivist", 30, 10, 8, 5, "Spirit", ["res://data/items/healing_herb.tres"])],
		[_make("Velundrath Tide Caller", 35, 12, 6, 7, "Magic"), _make("Velundrath Tide Caller", 35, 12, 6, 7, "Magic"), _make("Velundrath Archivist", 30, 10, 8, 5, "Spirit")],
	],
	"corrupted": [
		[_make("Corrupted Husk", 40, 14, 4, 8, "Magic", ["res://data/items/antidote.tres"])],
		[_make("Corrupted Fragment", 25, 16, 2, 11, "Spirit"), _make("Corrupted Fragment", 25, 16, 2, 11, "Spirit")],
		[_make("Corrupted Husk", 40, 14, 4, 8, "Magic"), _make("Corrupted Fragment", 25, 16, 2, 11, "Spirit")],
		[_make("Corrupted Husk", 40, 14, 4, 8, "Magic"), _make("Corrupted Husk", 40, 14, 4, 8, "Magic"), _make("Corrupted Fragment", 25, 16, 2, 11, "Spirit")],
	],
}
