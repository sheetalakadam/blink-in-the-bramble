class_name ShrineData
extends Resource

## Data resource for a god's shrine boon.
## Each shrine offers one boon tied to a god.

@export var god_name: String = ""
@export var boon_name: String = ""
@export_multiline var boon_description: String = ""
@export_enum("affinity", "memory") var cost_type: String = "affinity"
@export var cost_amount: int = 10
@export_enum("reveal_armor", "auto_revive", "bond_strike", "surge_extend", "extra_turn") var boon_effect: String = ""
