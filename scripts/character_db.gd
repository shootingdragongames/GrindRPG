extends Node

var characters: Dictionary = {}

func _ready():
    load_all_characters()

func load_all_characters():
    var char_files = [
        "res://data/fighter.tres",
        "res://data/thief.tres",
        "res://data/mage.tres",
        "res://data/cleric.tres",
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
