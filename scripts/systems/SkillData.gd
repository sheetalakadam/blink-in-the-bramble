extends Resource
class_name SkillData

enum TargetType { SINGLE_ENEMY, ALL_ENEMIES, SINGLE_ALLY, ALL_ALLIES, SELF }

@export var name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D

@export_group("Mechanics")
@export var damage_multiplier: float = 1.0
@export var momentum_change: float = 10.0 # How much this skill fills/drains the gauge
@export var target_type: TargetType = TargetType.SINGLE_ENEMY
@export var stamina_cost: int = 0

@export_group("Effects")
@export var status_effect: String = ""
@export var effect_chance: float = 0.0
