extends Node

var characters: Dictionary = {}

func _ready():
    load_all_characters()

func load_all_characters():
    var char_files = [
        "res://data/characters/fighter.tres",
        "res://data/characters/thief.tres",
        "res://data/characters/mage.tres",
        "res://data/characters/cleric.tres",
    ]
    for path in char_files:
        if ResourceLoader.exists(path):
            var data = load(path)
            characters[data.character_name.to_lower()] = data
            print("Loaded: ", data.character_name)
        else:
            print("Missing: ", path)

func get_character(name: String) -> CharacterData:
    return characters.get(name.to_lower(), null)

func get_all_characters() -> Array:
    return characters.values()
