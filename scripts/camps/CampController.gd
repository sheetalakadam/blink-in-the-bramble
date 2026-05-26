extends Node

## Controls base camp logic: Quarters (companion conversations),
## Forge (upgrades — placeholder), and Sanctum (party healing).
## Attached to the CampScene root node.

signal quarters_conversation_available(companion: String)
signal sanctum_healed
signal forge_opened

## Tracks current HP for party members while in camp.
## Keys are character names, values are current HP.
var _party_current_hp: Dictionary = {}

## Whether the Sanctum has been used this camp visit.
var _sanctum_used: bool = false


func _ready() -> void:
	_sync_party_hp()


## Sync party HP from PartyManager. Initializes current HP to max if not tracked.
func _sync_party_hp() -> void:
	for member in PartyManager.get_active_party():
		if not _party_current_hp.has(member.name):
			_party_current_hp[member.name] = member.max_hp


# ---------------------------------------------------------------------------
# Quarters
# ---------------------------------------------------------------------------

## Returns true if a companion conversation is available at the Quarters.
## Requires: highest-affinity companion has affinity >= 25 AND the conversation
## has not been seen yet (checked via GlobalFlags).
func is_quarters_conversation_available() -> bool:
	var companion = AffinityManager.get_highest_affinity_pair()
	if companion == "":
		return false
	var affinity = AffinityManager.get_affinity(companion)
	if affinity < AffinityManager.THRESHOLD_FRIENDLY:
		return false
	var flag_name = "camp_conversation_seen_%s" % companion
	if GlobalFlags.get_flag(flag_name):
		return false
	return true


## Returns the name of the companion with the highest affinity who qualifies
## for a Quarters conversation, or "" if none.
func get_quarters_companion() -> String:
	if not is_quarters_conversation_available():
		return ""
	return AffinityManager.get_highest_affinity_pair()


## Marks the current Quarters conversation as seen so it won't trigger again.
func mark_quarters_conversation_seen() -> void:
	var companion = AffinityManager.get_highest_affinity_pair()
	if companion != "":
		var flag_name = "camp_conversation_seen_%s" % companion
		GlobalFlags.set_flag(flag_name, true)


## Triggers the Quarters companion dialogue. Call from Area2D body_entered.
func enter_quarters() -> void:
	var companion = get_quarters_companion()
	if companion == "":
		return
	# Build dialogue ID from companion name (e.g., "camp_caelan_01")
	var dialogue_id = "camp_%s_01" % companion.to_lower()
	quarters_conversation_available.emit(companion)
	DialogueManager.start_dialogue(dialogue_id)
	mark_quarters_conversation_seen()


# ---------------------------------------------------------------------------
# Forge
# ---------------------------------------------------------------------------

## Returns the current Forge status. For MVP, always "coming_soon".
func get_forge_status() -> String:
	return "coming_soon"


## Called when the player enters the Forge zone.
func enter_forge() -> void:
	forge_opened.emit()


# ---------------------------------------------------------------------------
# Sanctum
# ---------------------------------------------------------------------------

## Heals all party members to full HP. Returns true if healing occurred,
## false if the Sanctum was already used this visit.
func use_sanctum() -> bool:
	if _sanctum_used:
		return false

	_sync_party_hp()

	for member in PartyManager.get_active_party():
		_party_current_hp[member.name] = member.max_hp

	_sanctum_used = true
	sanctum_healed.emit()
	return true


# ---------------------------------------------------------------------------
# Camp lifecycle
# ---------------------------------------------------------------------------

## Resets camp state for a new visit. Call when re-entering the camp scene.
func reset_camp() -> void:
	_sanctum_used = false
	_party_current_hp.clear()
	_sync_party_hp()


# ---------------------------------------------------------------------------
# Scene signal handlers (connected via CampScene.tscn)
# ---------------------------------------------------------------------------

func _on_quarters_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_update_quarters_glow()
		enter_quarters()


func _on_forge_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		enter_forge()
		var panel = get_node_or_null("ForgePanel")
		if panel:
			panel.visible = true


func _on_sanctum_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var healed = use_sanctum()
		if healed:
			var msg = get_node_or_null("HealMessage")
			if msg:
				msg.visible = true
				get_tree().create_timer(2.0).timeout.connect(func(): msg.visible = false)


func _on_forge_close_pressed() -> void:
	var panel = get_node_or_null("ForgePanel")
	if panel:
		panel.visible = false


## Updates the glow indicator on Quarters when a conversation is available.
func _update_quarters_glow() -> void:
	var glow = get_node_or_null("Quarters/GlowIndicator")
	if glow:
		glow.visible = is_quarters_conversation_available()
