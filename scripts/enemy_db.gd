extends Node

var enemies: Dictionary = {}

func _ready():
    load_all_enemies()

func load_all_enemies():
    var enemy_files = [
        "res://data/enemies/bandit.tres",
    ]
    for path in enemy_files:
        if ResourceLoader.exists(path):
            var data = load(path)
            enemies[data.enemy_name.to_lower()] = data
            print("Loaded enemy: ", data.enemy_name)
        else:
            print("Missing enemy: ", path)

func get_enemy(name: String) -> EnemyData:
    return enemies.get(name.to_lower(), null)

func get_all_enemies() -> Array:
    return enemies.values()
