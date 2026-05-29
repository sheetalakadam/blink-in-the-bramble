extends Node2D

var _tests_passed: int = 0
var _tests_failed: int = 0

func _ready() -> void:
	print("[TEST_AUDIO] Starting audio manager tests...")

	_test_audio_manager_exists()
	_test_players_created()
	_test_play_bgm_missing_file()
	_test_stop_bgm_when_not_playing()
	_test_play_sfx_missing_file()
	_test_volume_controls()
	_test_volume_clamping()
	_test_region_bgm_mapping()
	_test_store_restore_region_bgm()
	_test_get_current_bgm()

	print("[TEST_AUDIO] Results: %d passed, %d failed" % [_tests_passed, _tests_failed])
	if _tests_failed == 0:
		print("[TEST_AUDIO] SUCCESS")
	else:
		printerr("[TEST_AUDIO] FAILED")

	if DisplayServer.get_name() == "headless":
		get_tree().quit()


func _assert(condition: bool, test_name: String) -> void:
	if condition:
		_tests_passed += 1
	else:
		_tests_failed += 1
		printerr("[TEST_AUDIO] FAIL: ", test_name)


func _test_audio_manager_exists() -> void:
	var am = get_node_or_null("/root/AudioManager")
	_assert(am != null, "AudioManager autoload should exist")


func _test_players_created() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am == null:
		_assert(false, "AudioManager not found for player test")
		return
	_assert(am.bgm_player != null, "BGM player should be created")
	_assert(am.sfx_player != null, "SFX player should be created")
	_assert(am.bgm_player is AudioStreamPlayer, "BGM player should be AudioStreamPlayer")
	_assert(am.sfx_player is AudioStreamPlayer, "SFX player should be AudioStreamPlayer")


func _test_play_bgm_missing_file() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am == null:
		_assert(false, "AudioManager not found for play_bgm test")
		return
	# Should not crash when file doesn't exist
	am.play_bgm("nonexistent_track_12345")
	_assert(true, "play_bgm with missing file should not crash")
	_assert(not am.bgm_player.playing, "BGM player should not be playing with missing file")


func _test_stop_bgm_when_not_playing() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am == null:
		_assert(false, "AudioManager not found for stop_bgm test")
		return
	# Should not crash when nothing is playing
	am.stop_bgm(0.0)
	_assert(true, "stop_bgm when not playing should not crash")


func _test_play_sfx_missing_file() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am == null:
		_assert(false, "AudioManager not found for play_sfx test")
		return
	# Should not crash when file doesn't exist
	am.play_sfx("nonexistent_sfx_12345")
	_assert(true, "play_sfx with missing file should not crash")
	_assert(not am.sfx_player.playing, "SFX player should not be playing with missing file")


func _test_volume_controls() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am == null:
		_assert(false, "AudioManager not found for volume test")
		return

	# Test BGM volume
	am.set_bgm_volume(1.0)
	_assert(am.bgm_player.volume_db == 0.0, "BGM volume 1.0 should be 0 dB")

	am.set_bgm_volume(0.0)
	_assert(am.bgm_player.volume_db == -80.0, "BGM volume 0.0 should be -80 dB")

	# Test SFX volume
	am.set_sfx_volume(1.0)
	_assert(am.sfx_player.volume_db == 0.0, "SFX volume 1.0 should be 0 dB")

	am.set_sfx_volume(0.0)
	_assert(am.sfx_player.volume_db == -80.0, "SFX volume 0.0 should be -80 dB")

	# Reset to default
	am.set_bgm_volume(1.0)
	am.set_sfx_volume(1.0)


func _test_volume_clamping() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am == null:
		_assert(false, "AudioManager not found for clamping test")
		return

	# Values above 1.0 should clamp
	am.set_bgm_volume(5.0)
	_assert(am.bgm_player.volume_db == 0.0, "BGM volume above 1.0 should clamp to 0 dB")

	# Negative values should clamp to 0.0
	am.set_bgm_volume(-1.0)
	_assert(am.bgm_player.volume_db == -80.0, "BGM volume below 0.0 should clamp to -80 dB")

	# Reset
	am.set_bgm_volume(1.0)


func _test_region_bgm_mapping() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am == null:
		_assert(false, "AudioManager not found for region mapping test")
		return

	# Verify the mapping dictionary has expected keys
	_assert(am.REGION_BGM.has("naevoria"), "REGION_BGM should have 'naevoria'")
	_assert(am.REGION_BGM.has("valdrihn"), "REGION_BGM should have 'valdrihn'")
	_assert(am.REGION_BGM.has("solenne"), "REGION_BGM should have 'solenne'")
	_assert(am.REGION_BGM.has("ereivyn"), "REGION_BGM should have 'ereivyn'")
	_assert(am.REGION_BGM.has("velundrath"), "REGION_BGM should have 'velundrath'")
	_assert(am.REGION_BGM.has("combat"), "REGION_BGM should have 'combat'")
	_assert(am.REGION_BGM.has("boss"), "REGION_BGM should have 'boss'")
	_assert(am.REGION_BGM.has("title"), "REGION_BGM should have 'title'")
	_assert(am.REGION_BGM.has("camp"), "REGION_BGM should have 'camp'")

	# Verify mapping values
	_assert(am.REGION_BGM["naevoria"] == "bgm_ruins", "naevoria should map to bgm_ruins")
	_assert(am.REGION_BGM["combat"] == "bgm_battle", "combat should map to bgm_battle")


func _test_store_restore_region_bgm() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am == null:
		_assert(false, "AudioManager not found for store/restore test")
		return

	# Store and restore should not crash even with no BGM playing
	am.store_region_bgm()
	am.restore_region_bgm()
	_assert(true, "store/restore region BGM should not crash with nothing playing")


func _test_get_current_bgm() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am == null:
		_assert(false, "AudioManager not found for get_current_bgm test")
		return

	# With no BGM playing, should return empty string
	am.stop_bgm(0.0)
	_assert(am.get_current_bgm() == "", "get_current_bgm should return empty when nothing playing")
