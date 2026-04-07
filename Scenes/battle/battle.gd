extends Node2D

var player_grid = {}
var enemy_grid = {}
var grid_slots = []
var fighter_data: CharacterData
var fighter_hp: int
var bandit_hp: int
var bandit_max_hp: int
var bandit_def: int = 3
var player_turn: bool = true
var is_defending: bool = false

# Bandit position for damage numbers
var bandit_pos = Vector2(650, 150)
var fighter_pos = Vector2(150, 150)

@onready var hp_bar = $UI/UIRoot/PartyPanel/ProgressBar
@onready var hp_label = $UI/UIRoot/PartyPanel/Label
@onready var attack_btn = $UI/UIRoot/PartyPanel/ActionButtons/Attack
@onready var defend_btn = $UI/UIRoot/PartyPanel/ActionButtons/Defend

func setup_grid():
    var slot_size = Vector2(80, 80)
    var gap = Vector2(10, 25)
    
    # Player grid - left side
    for row in range(3):
        for col in range(3):
            var slot = ColorRect.new()
            slot.size = slot_size
            slot.position = Vector2(
                50 + col * (slot_size.x + gap.x),
                30 + row * (slot_size.y + gap.y)
            )
            slot.color = Color(0.2, 0.2, 0.2, 0.5)
            slot.set_meta("grid_pos", Vector2(col, row))
            slot.set_meta("side", "player")
            add_child(slot)
            grid_slots.append(slot)
    
    # Enemy grid - right side
    for row in range(3):
        for col in range(3):
            var slot = ColorRect.new()
            slot.size = slot_size
            slot.position = Vector2(
                750 + col * (slot_size.x + gap.x),
                30 + row * (slot_size.y + gap.y)
            )
            slot.color = Color(0.3, 0.1, 0.1, 0.5)
            add_child(slot)

func place_enemies_in_default():
    var slot_size = Vector2(80, 80)
    var gap = Vector2(10, 25)
    
    # Bandit in middle column, first row of enemy grid
    var bandit_rect = ColorRect.new()
    bandit_rect.size = slot_size
    bandit_rect.color = Color(0.5, 0.5, 0.5)  # grey
    bandit_rect.position = Vector2(
        750 + 1 * (slot_size.x + gap.x),  # middle column
        30 + 0 * (slot_size.y + gap.y)    # first row
    )
    
    var label = Label.new()
    label.text = "Bandit"
    label.position = Vector2(0, slot_size.y + 2)
    bandit_rect.add_child(label)
    
    # Store bandit position for damage numbers
    bandit_pos = bandit_rect.position + Vector2(40, 40)
    
    add_child(bandit_rect)

func place_party_in_default():
    var slot_size = Vector2(80, 80)
    var gap = Vector2(10, 25)
    
    for i in range(GameState.selected_party.size()):
        var character = GameState.selected_party[i]
        player_grid[Vector2(1, i)] = character
        
        # Create visual character square in middle column
        var char_rect = ColorRect.new()
        char_rect.size = slot_size
        char_rect.color = character.player_color
        char_rect.position = Vector2(
            50 + 1 * (slot_size.x + gap.x),  # middle column = col 1
            30 + i * (slot_size.y + gap.y)    # row based on party order
        )
        
        # Add name label
        var label = Label.new()
        label.text = character.character_name
        label.position = Vector2(0, slot_size.y + 2)
        char_rect.add_child(label)
        
        add_child(char_rect)
        print("Placed ", character.character_name, " at row ", i, " middle column")

func show_damage(amount: int, pos: Vector2, color: Color):
    var label = Label.new()
    label.text = str(amount)
    label.position = pos
    label.add_theme_color_override("font_color", color)
    add_child(label)
    var tween = create_tween()
    tween.tween_property(label, "position", pos + Vector2(0, -60), 0.8)
    tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
    tween.tween_callback(label.queue_free)

func update_ui():
    hp_bar.max_value = fighter_data.get_max_hp()
    hp_bar.value = fighter_hp
    hp_label.text = fighter_data.character_name + "  HP: " + str(fighter_hp) + "/" + str(fighter_data.get_max_hp())

func _ready():
    if GameState.selected_party.size() > 0:
        fighter_data = GameState.selected_party[0]
    else:
        fighter_data = load("res://data/fighter.tres")
    
    fighter_hp = fighter_data.get_max_hp()
    bandit_max_hp = fighter_data.get_atk() * 5
    bandit_hp = bandit_max_hp
    
    attack_btn.pressed.connect(_on_attack_pressed)
    defend_btn.pressed.connect(_on_defend_pressed)
    
    print("=== BATTLE START ===")
    print("Playing as: ", fighter_data.character_name)
    print("HP: ", fighter_hp)
    print("Bandit HP: ", bandit_hp)
    
    update_ui()
    setup_grid()
    place_party_in_default()
    place_enemies_in_default()

func _input(event):
    if event.is_action_pressed("ui_accept") and player_turn:
        player_attack()

func _process(_delta):
    if Input.is_action_just_pressed("ui_cancel"):
        get_tree().reload_current_scene()

func _on_attack_pressed():
    if player_turn:
        player_attack()

func _on_defend_pressed():
    if player_turn:
        is_defending = true
        print("Fighter defends!")
        enemy_attack()

func player_attack():
    var weapon_bonus: int = 10
    var atk = fighter_data.get_atk() + weapon_bonus
    var base_damage = max(0, atk - bandit_def)
    var variance = randf_range(0.85, 1.15)
    var damage = max(1, int(base_damage * variance))
    bandit_hp -= damage
    print("Fighter attacks! ", damage, " damage. Bandit HP: ", max(0, bandit_hp))
    show_damage(damage, bandit_pos + Vector2(0, -20), Color.RED)
    if bandit_hp <= 0:
        print("=== BANDIT DEFEATED ===")
        print("Fighter wins!")
        player_turn = false
    else:
        enemy_attack()
    update_ui()

func enemy_attack():
    var bandit_atk: int = 12
    var base_damage = max(0, bandit_atk - fighter_data.get_def())
    var variance = randf_range(0.85, 1.15)
    var damage = max(1, int(base_damage * variance))
    if is_defending:
        var reduction = randf_range(0.50, 0.75)
        damage = max(1, int(damage * (1.0 - reduction)))
        print("Fighter defended! Reduced damage: ", damage)
        is_defending = false
    fighter_hp -= damage
    print("Bandit attacks! ", damage, " damage. Fighter HP: ", fighter_hp)
    show_damage(damage, fighter_pos + Vector2(0, -20), Color.WHITE)
    if fighter_hp <= 0:
        print("=== FIGHTER DEFEATED ===")
        player_turn = false
    update_ui()
