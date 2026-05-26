extends Area2D

## Interactive shrine node placed in the world.
## When the player enters the collision area, emits a signal
## to open the boon selection UI.

signal shrine_entered(shrine_data: ShrineData)

@export var god_name: String = ""
@export var shrine_data: ShrineData


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("[ShrineNode] Player entered shrine of %s" % god_name)
		shrine_entered.emit(shrine_data)
