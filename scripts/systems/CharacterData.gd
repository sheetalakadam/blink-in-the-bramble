extends Resource
class_name CharacterData

@export var name: String = ""
@export_multiline var bio: String = ""
@export var portrait: Texture2D

@export_group("Stats")
@export var max_hp: int = 100
@export var attack: int = 10
@export var defense: int = 10
@export var speed: int = 10

@export_group("Combat")
@export var stances: Array[String] = []
@export var skills: Array[SkillData] = []

@export_group("Progression")
@export var level: int = 1
@export var experience: int = 0
@export var affinity: int = 0
