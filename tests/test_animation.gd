extends Node2D

func _ready() -> void:
	print("[TEST_ANIM] Starting Animation & Idle Test...")
	
	# Create a dummy player structure
	var player = CharacterBody2D.new()
	player.name = "Zi"
	add_child(player)
	
	var idle_mgr = load("res://scripts/characters/IdleManager.gd").new()
	idle_mgr.name = "IdleManager"
	idle_mgr.idle_threshold = 1.0 # Short for test
	player.add_child(idle_mgr)
	
	idle_mgr.flavor_idle_triggered.connect(_on_flavor_triggered)
	
	print("[TEST_ANIM] Waiting for 1.5s idle trigger...")
	await get_tree().create_timer(1.5).timeout
	
	if DisplayServer.get_name() == "headless":
		get_tree().quit()

func _on_flavor_triggered(anim_name: String) -> void:
	print("[TEST_ANIM] SUCCESS: Flavor idle triggered: ", anim_name)
