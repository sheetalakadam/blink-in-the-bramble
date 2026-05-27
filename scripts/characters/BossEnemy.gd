extends CharacterBody2D

## Overworld boss enemy — stationary, larger visual, triggers boss combat on player contact.
## Unlike regular OverworldEnemy, bosses do not roam.

signal player_contacted(enemy: CharacterBody2D)

@export var boss_resource: BossData
var _defeated: bool = false


func _ready() -> void:
	pass


func mark_defeated() -> void:
	_defeated = true
	queue_free()


func get_enemy_data() -> Dictionary:
	if boss_resource == null:
		push_error("[BossEnemy] No boss_resource assigned!")
		return {"name": "Unknown Boss", "hp": 1, "max_hp": 1, "attack": 1, "defense": 0, "armor_type": "", "speed": 1, "is_enemy": true, "is_boss": true}

	var controller = BossController.new()
	return controller.create_enemy_dict(boss_resource)


func _on_detection_area_body_entered(body: Node2D) -> void:
	if _defeated:
		return
	if body.is_in_group("player"):
		player_contacted.emit(self)
