extends Resource
class_name EquipmentData

@export var name: String = ""
@export_multiline var description: String = ""

## "weapon", "armor", or "accessory"
@export var slot: String = ""

@export_group("Stance")
## Which stance this equipment enhances (empty = none)
@export var stance_bonus: String = ""
## Additional multiplier when in the enhanced stance (e.g. 0.1 = +10%)
@export var stance_bonus_amount: float = 0.0

@export_group("Stats")
## Small stat bonuses: {"attack": 2, "defense": 1} etc.
@export var stat_bonus: Dictionary = {}

@export_group("Skills")
## Path to a SkillData .tres this equipment unlocks (empty = none)
@export var unlocked_skill_path: String = ""
