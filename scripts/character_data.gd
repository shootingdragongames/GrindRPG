class_name CharacterData
extends Resource

@export var character_name: String = ""
@export var resource_pool_name: String = ""

# Base stats
@export var base_hp: int = 100
@export var base_sp: int = 100
@export var base_str: int = 3
@export var base_dex: int = 3
@export var base_wis: int = 3
@export var base_int: int = 3
@export var base_lck: int = 3

# Passive growth per level
@export var growth_hp: int = 0
@export var growth_resource: int = 0
@export var growth_str: int = 0
# Current level
@export var level: int = 1

# Allocated points (player distributed)
var alloc_str: int = 0
var alloc_dex: int = 0
var alloc_wis: int = 0
var alloc_int: int = 0
var alloc_lck: int = 0
var alloc_hp: int = 0
var alloc_resource: int = 0

# --- Calculated Stats ---
func get_str() -> int:
    return base_str + (growth_str * (level - 1)) + alloc_str

func get_dex() -> int:
    return base_dex + alloc_dex

func get_wis() -> int:
    return base_wis + alloc_wis

func get_int() -> int:
    return base_int + alloc_int

func get_lck() -> int:
    return base_lck + alloc_lck

func get_max_hp() -> int:
    return base_hp + (growth_hp * (level - 1)) + (alloc_hp * 10)

func get_max_resource() -> int:
    return base_sp + (growth_resource * (level - 1)) + (alloc_resource * 10)

# --- Derived Stats ---
func get_atk() -> int:
    return get_str() * 2

func get_mag() -> int:
    return get_int() * 2

func get_def() -> int:
    return get_str() + get_wis()

func get_mdef() -> int:
    return get_wis() + get_int()

func get_crit_chance() -> float:
    return (get_dex() + get_lck()) * 0.5

func get_spd() -> int:
    return int(get_dex() * 1.5)
