extends Resource
class_name ItemData

enum ItemType { CONSUMABLE, QUEST, KEY }

@export var name: String = ""
@export_multiline var description: String = ""
@export var item_type: ItemType = ItemType.CONSUMABLE

@export_group("Effect")
## heal_hp, heal_mp, cure_poison, cure_rooted, buff_attack, buff_defense
@export var effect_type: String = ""
@export var effect_value: int = 0

@export_group("Stacking")
@export var max_stack: int = 10
