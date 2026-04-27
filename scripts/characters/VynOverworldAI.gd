extends CharacterBody2D

@export var follow_target_path: NodePath
@onready var follow_target = get_node_or_null(follow_target_path)

@export var follow_distance: float = 40.0
@export var lerp_speed: float = 3.0

func _physics_process(delta: float) -> void:
	if not follow_target:
		# Try to find the player if not set
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			follow_target = players[0]
		return
		
	var target_pos = follow_target.global_position
	var current_pos = global_position
	var distance = current_pos.distance_to(target_pos)
	
	if distance > follow_distance:
		var direction = (target_pos - current_pos).normalized()
		var move_to = target_pos - (direction * follow_distance)
		global_position = global_position.lerp(move_to, lerp_speed * delta)
		
		# Simple look-at (flip visual)
		var sprite = get_node_or_null("PlaceholderSprite")
		if sprite:
			if target_pos.x < current_pos.x:
				sprite.scale.x = -1
			else:
				sprite.scale.x = 1

	move_and_slide()
