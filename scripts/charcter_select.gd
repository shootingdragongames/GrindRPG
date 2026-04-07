extends Node2D

var selected_party: Array = []
var max_party_size: int = 4
var char_buttons: Dictionary = {}

func _ready():
    display_characters()
    add_confirm_button()

func display_characters():
    var all_chars = CharacterDB.get_all_characters()
    var x_pos = 100
    for character in all_chars:
        var btn = Button.new()
        btn.text = character.character_name
        btn.position = Vector2(x_pos, 200)
        btn.size = Vector2(120, 60)
        btn.pressed.connect(_on_character_selected.bind(character, btn))
        add_child(btn)
        char_buttons[character.character_name] = btn
        x_pos += 140

func add_confirm_button():
    var confirm = Button.new()
    confirm.text = "Confirm Party"
    confirm.position = Vector2(300, 350)
    confirm.size = Vector2(160, 50)
    confirm.pressed.connect(_on_confirm)
    add_child(confirm)

func _on_character_selected(character: CharacterData, btn: Button):
    if character in selected_party:
        selected_party.erase(character)
        btn.modulate = Color.WHITE
        print("Removed: ", character.character_name)
    else:
        if selected_party.size() < max_party_size:
            selected_party.append(character)
            btn.modulate = Color.GREEN
            print("Selected: ", character.character_name)
    print("Party: ", selected_party.map(func(c): return c.character_name))

func _on_confirm():
    if selected_party.is_empty():
        print("Select at least one character!")
        return
    print("Starting battle with: ", selected_party.map(func(c): return c.character_name))
    # Later this will transition to the battle scene
