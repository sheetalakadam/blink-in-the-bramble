extends CharacterBody2D

## Overworld enemy that roams randomly and triggers combat on player contact.

signal player_contacted(enemy: CharacterBody2D)

@export var speed: float = 40.0
@export var enemy_name: String = "Slime"
@export var enemy_level: int = 1

var _roam_direction: Vector2 = Vector2.ZERO
var _roam_timer: float = 0.0
var _pause_timer: float = 0.0
var _is_paused: bool = false
var _is_visible_on_screen: bool = true
var _defeated: bool = false

func _ready() -> void:
	_pick_new_roam()


func _physics_process(delta: float) -> void:
	if _defeated:
		return
	if not _is_visible_on_screen:
		return

	if _is_paused:
		_pause_timer -= delta
		if _pause_timer <= 0.0:
			_is_paused = false
			_pick_new_roam()
		return

	_roam_timer -= delta
	if _roam_timer <= 0.0:
		_start_pause()
		return

	velocity = _roam_direction * speed
	move_and_slide()


func _pick_new_roam() -> void:
	var angle = randf() * TAU
	_roam_direction = Vector2(cos(angle), sin(angle)).normalized()
	_roam_timer = randf_range(1.0, 2.0)


func _start_pause() -> void:
	_is_paused = true
	_pause_timer = randf_range(0.5, 1.5)
	velocity = Vector2.ZERO


func mark_defeated() -> void:
	_defeated = true
	queue_free()


func get_enemy_data() -> Dictionary:
	return {
		"name": enemy_name,
		"level": enemy_level,
		"speed": 5,
		"hp": 20 + enemy_level * 5,
		"attack": 3 + enemy_level * 2,
	}


func _on_detection_area_body_entered(body: Node2D) -> void:
	if _defeated:
		return
	if body.is_in_group("player"):
		player_contacted.emit(self)


func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	_is_visible_on_screen = true


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	_is_visible_on_screen = false
