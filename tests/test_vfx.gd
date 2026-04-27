extends Node2D

@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	CombatVFXManager.register_camera(camera)
	print("[TEST_VFX] Ready. Press Space to trigger Hit-Stop and Shake.")
	
	if DisplayServer.get_name() == "headless":
		print("[TEST_VFX] Headless mode detected. Auto-triggering in 0.5s...")
		await get_tree().create_timer(0.5).timeout
		_test_impact()
		await get_tree().create_timer(0.5).timeout
		get_tree().quit()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_test_impact()

func _test_impact() -> void:
	print("[TEST_VFX] Triggering Impact Juice...")
	CombatVFXManager.trigger_hit_stop(0.15)
	CombatVFXManager.trigger_screen_shake(10.0, 0.2)
