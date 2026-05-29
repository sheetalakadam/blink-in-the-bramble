extends Node

## Manages background music and sound effects.
## Autoload singleton — access via AudioManager anywhere.

signal bgm_changed(track_name: String)

var bgm_player: AudioStreamPlayer = null
var sfx_player: AudioStreamPlayer = null

# Crossfade support
var _fade_tween: Tween = null
var _current_bgm_track: String = ""
var _region_bgm_before_combat: String = ""

# Region-to-BGM mapping
const REGION_BGM: Dictionary = {
	"naevoria": "bgm_ruins",
	"valdrihn": "bgm_military",
	"solenne": "bgm_trade",
	"ereivyn": "bgm_forest",
	"velundrath": "bgm_coast",
	"combat": "bgm_battle",
	"boss": "bgm_boss",
	"title": "bgm_title",
	"camp": "bgm_camp",
}

# Known SFX names (for documentation; any name can be played)
const KNOWN_SFX: Array[String] = [
	"hit", "heal", "menu_select", "menu_back", "level_up", "quest_complete",
]

const BGM_PATH_PREFIX: String = "res://assets/audio/bgm/"
const SFX_PATH_PREFIX: String = "res://assets/audio/sfx/"
const SUPPORTED_EXTENSIONS: Array[String] = [".ogg", ".wav", ".mp3"]


func _ready() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	bgm_player.bus = "Master"
	add_child(bgm_player)

	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SFXPlayer"
	sfx_player.bus = "Master"
	add_child(sfx_player)


## Play background music by track name or region key.
## If a region key is given (e.g. "naevoria"), it maps to the corresponding BGM file.
## Crossfades from the current track over fade_duration seconds.
func play_bgm(track_name: String, fade_duration: float = 1.0) -> void:
	# Resolve region key to actual track name
	var resolved: String = REGION_BGM.get(track_name.to_lower(), track_name)

	if resolved == _current_bgm_track and bgm_player.playing:
		return  # Already playing this track

	var stream = _load_audio(BGM_PATH_PREFIX, resolved)
	if stream == null:
		push_warning("[AudioManager] BGM not found: %s (resolved from '%s')" % [resolved, track_name])
		return

	# Crossfade: fade out current, then start new
	if bgm_player.playing and fade_duration > 0.0:
		_kill_fade_tween()
		var old_volume = bgm_player.volume_db
		_fade_tween = create_tween()
		_fade_tween.tween_property(bgm_player, "volume_db", -80.0, fade_duration * 0.5)
		_fade_tween.tween_callback(func():
			bgm_player.stop()
			bgm_player.stream = stream
			bgm_player.volume_db = -80.0
			bgm_player.play()
		)
		_fade_tween.tween_property(bgm_player, "volume_db", old_volume, fade_duration * 0.5)
	else:
		bgm_player.stream = stream
		bgm_player.play()

	_current_bgm_track = resolved
	bgm_changed.emit(resolved)
	print("[AudioManager] Playing BGM: %s" % resolved)


## Stop background music with optional fade out.
func stop_bgm(fade_duration: float = 1.0) -> void:
	if not bgm_player.playing:
		return

	if fade_duration > 0.0:
		_kill_fade_tween()
		_fade_tween = create_tween()
		_fade_tween.tween_property(bgm_player, "volume_db", -80.0, fade_duration)
		_fade_tween.tween_callback(func():
			bgm_player.stop()
			bgm_player.volume_db = 0.0
		)
	else:
		bgm_player.stop()

	_current_bgm_track = ""


## Play a sound effect by name. Loads from res://assets/audio/sfx/{sfx_name}.
func play_sfx(sfx_name: String) -> void:
	var stream = _load_audio(SFX_PATH_PREFIX, sfx_name)
	if stream == null:
		push_warning("[AudioManager] SFX not found: %s" % sfx_name)
		return

	sfx_player.stream = stream
	sfx_player.play()
	print("[AudioManager] Playing SFX: %s" % sfx_name)


## Set BGM volume using a linear scale (0.0 to 1.0).
func set_bgm_volume(linear: float) -> void:
	linear = clampf(linear, 0.0, 1.0)
	bgm_player.volume_db = linear_to_db(linear) if linear > 0.0 else -80.0


## Set SFX volume using a linear scale (0.0 to 1.0).
func set_sfx_volume(linear: float) -> void:
	linear = clampf(linear, 0.0, 1.0)
	sfx_player.volume_db = linear_to_db(linear) if linear > 0.0 else -80.0


## Get the current BGM track name (empty if nothing playing).
func get_current_bgm() -> String:
	return _current_bgm_track


## Play region BGM by region name. Convenience wrapper.
func play_region_bgm(region_name: String) -> void:
	play_bgm(region_name)


## Store the current BGM so it can be restored after combat.
func store_region_bgm() -> void:
	_region_bgm_before_combat = _current_bgm_track


## Restore the BGM that was playing before combat.
func restore_region_bgm() -> void:
	if _region_bgm_before_combat != "":
		play_bgm(_region_bgm_before_combat)
		_region_bgm_before_combat = ""


## Try to load an audio file with supported extensions.
func _load_audio(path_prefix: String, file_name: String) -> AudioStream:
	for ext in SUPPORTED_EXTENSIONS:
		var full_path = path_prefix + file_name + ext
		if ResourceLoader.exists(full_path):
			var resource = load(full_path)
			if resource is AudioStream:
				return resource
	return null


func _kill_fade_tween() -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
		_fade_tween = null
