class_name EnemyData
extends Resource

@export var enemy_name: String = ""
@export var monsterpedia_note: String = ""
@export var note_character: String = ""

# Base stats
@export var base_hp: int = 100
@export var base_atk: int = 8
@export var base_def: int = 3
@export var base_mdef: int = 2
@export var base_dex: int = 3
@export var base_lck: int = 3


# Color interactions
@export var weakness: String = ""     # color that deals 2x
@export var resistance: String = ""   # color that deals 0.5x

# Shiny
@export var can_be_shiny: bool = true

# Rewards
@export var base_xp: int = 10
@export var base_gold: int = 5

# Derived
func get_initiative() -> float:
    return (base_dex + base_lck) / 2.0
    
func get_lck() -> int:
    return base_lck
