extends Node2D

var fighter_data: CharacterData
var fighter_hp: int
var bandit_hp: int
var bandit_max_hp: int
var bandit_def: int = 3
var player_turn: bool = true

@onready var hp_bar = $UI/UIRoot/PartyPanel/ProgressBar
@onready var hp_label = $UI/UIRoot/PartyPanel/Label

func update_ui():
    hp_bar.max_value = fighter_data.get_max_hp()
    hp_bar.value = fighter_hp
    hp_label.text = "Fighter  HP: " + str(fighter_hp) + "/" + str(fighter_data.get_max_hp())

func _ready():
    fighter_data = load("res://data/fighter.tres")
    fighter_hp = fighter_data.get_max_hp()
    bandit_max_hp = fighter_data.get_atk() * 5
    bandit_hp = bandit_max_hp
    print("=== BATTLE START ===")
    print("Fighter HP: ", fighter_hp)
    print("Bandit HP: ", bandit_hp)
    print("Press SPACE to attack!")
    update_ui()

func _input(event):
    if event.is_action_pressed("ui_accept") and player_turn:
        player_attack()

func _process(_delta):
    if Input.is_action_just_pressed("ui_cancel"):
        get_tree().reload_current_scene()

func player_attack():
    var weapon_bonus: int = 10
    var atk = fighter_data.get_atk() + weapon_bonus
    var damage = max(0, atk - bandit_def)
    bandit_hp -= damage
    print("Fighter attacks! ", damage, " damage. Bandit HP: ", max(0, bandit_hp))
    if bandit_hp <= 0:
        print("=== BANDIT DEFEATED ===")
        print("Fighter wins!")
        print("Press ESC to restart")
        player_turn = false
    else:
        enemy_attack()
    update_ui()

func enemy_attack():
    var bandit_atk: int = 12
    var damage = max(0, bandit_atk - fighter_data.get_def())
    fighter_hp -= damage
    print("Bandit attacks! ", damage, " damage. Fighter HP: ", fighter_hp)
    if fighter_hp <= 0:
        print("=== FIGHTER DEFEATED ===")
        player_turn = false
    update_ui()
