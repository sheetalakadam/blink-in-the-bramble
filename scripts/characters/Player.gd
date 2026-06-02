extends CharacterBody2D

@export var speed: float = 150.0

var _sprite: Sprite2D = null
var _walk_timer: float = 0.0
var _walk_frame: int = 0

func _ready() -> void:
	add_to_group("player")
	_try_load_sprite()

func _try_load_sprite() -> void:
	var tex := SpriteLoader.get_character_sprite("zi")
	if tex == null:
		return
	# Hide placeholder ColorRect
	var placeholder = get_node_or_null("PlaceholderSprite")
	if placeholder:
		placeholder.visible = false
	# Create sprite from sheet (128x32, 4 frames of 32x32)
	_sprite = Sprite2D.new()
	_sprite.texture = tex
	_sprite.hframes = 4
	_sprite.frame = 0
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)

func _physics_process(delta: float) -> void:
	var input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_direction * speed

	move_and_slide()

	if Engine.has_singleton("WorldManager") or get_tree().root.has_node("WorldManager"):
		WorldManager.update_player_position(global_position)

	if _sprite:
		if velocity.length() > 0:
			# Walk animation: alternate frames 1 and 2
			_walk_timer += delta
			if _walk_timer > 0.15:
				_walk_timer = 0.0
				_walk_frame = 1 if _walk_frame == 2 else 2
				_sprite.frame = _walk_frame
			# Flip based on direction
			if velocity.x < 0:
				_sprite.flip_h = true
			elif velocity.x > 0:
				_sprite.flip_h = false
		else:
			_sprite.frame = 0
			_walk_timer = 0.0
