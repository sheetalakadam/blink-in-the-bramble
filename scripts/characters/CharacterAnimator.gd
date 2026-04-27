extends Node2D

@onready var sprite: ColorRect = get_node_or_null("Visual") # Using ColorRect for now
@onready var anim_player: AnimationPlayer = get_node_or_null("AnimationPlayer")

func _process(_delta: float) -> void:
	var parent = get_parent()
	if not parent is CharacterBody2D:
		return
		
	var velocity = parent.velocity
	
	if velocity.length() > 0:
		_handle_movement_animation(velocity)
	else:
		_handle_idle_animation()

func _handle_movement_animation(velocity: Vector2) -> void:
	# 4-Way Flip Logic
	if sprite:
		if velocity.x < 0:
			sprite.scale.x = -1
		elif velocity.x > 0:
			sprite.scale.x = 1
			
	# Animation selection (Up/Down/Side)
	if anim_player:
		if abs(velocity.x) > abs(velocity.y):
			anim_player.play("walk_side")
		elif velocity.y < 0:
			anim_player.play("walk_up")
		else:
			anim_player.play("walk_down")

func _handle_idle_animation() -> void:
	if anim_player:
		anim_player.play("idle")
