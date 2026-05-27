class_name BossData
extends Resource

## Data resource for a boss enemy.
## Each boss has multiple phases with different armor types, stats, and attacks.
## Phases are ordered by HP threshold descending (phase 1 = full HP, last phase = lowest HP).

@export var boss_name: String = ""
@export var phases: Array[Dictionary] = []
## Each phase dictionary: {
##   "armor_type": String,      — e.g. "Heavy", "Agile"
##   "hp_threshold": float,     — fraction of total HP (1.0 = phase starts at full HP, 0.5 = starts at 50%)
##   "attack": int,
##   "defense": int,
##   "attack_name": String      — telegraphed attack name
## }
@export var total_hp: int = 100
@export var speed: int = 5
@export var dialogue_on_phase_change: String = ""

## Milestone ID granted on defeat — derived from boss_name if not set explicitly.
@export var milestone_id: String = ""

func get_milestone_id() -> String:
	if milestone_id != "":
		return milestone_id
	# Convert "Corrupted Sentinel" -> "corrupted_sentinel_defeated"
	return boss_name.to_lower().replace(" ", "_") + "_defeated"
