    
extends Node2D

var fighter_data: CharacterData
var fighter_hp: int
var bandit_hp: int
var bandit_max_hp: int
var bandit_def: int = 3
var player_turn: bool = true

@onready var hp_bar = $UI/UIRoot/PartyPanel/ProgressBar
@onready var hp_label = $UI/UIRoot/PartyPanel/Label
@onready var bandit_hp_bar = $ColorRect2/ProgressBar
@onready var attack_btn = $UI/UIRoot/PartyPanel/ActionButtons/Attack
@onready var defend_btn = $UI/UIRoot/PartyPanel/ActionButtons/Defend

func _on_attack_pressed():
    if player_turn:
        player_attack()

func _on_defend_pressed():
    if player_turn:
        print("Fighter defends! Reduced damage next hit.")
        enemy_attack()
func show_damage(amount: int, position: Vector2, color: Color):
    var label = Label.new()
    label.text = str(amount)
    label.position = position
    label.add_theme_color_override("font_color", color)
    add_child(label)
    # Animate it floating up and fading
    var tween = create_tween()
    tween.tween_property(label, "position", position + Vector2(0, -60), 0.8)
    tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
    tween.tween_callback(label.queue_free)
    
func update_ui():
    hp_bar.max_value = fighter_data.get_max_hp()
    hp_bar.value = fighter_hp
    hp_label.text = "Fighter  HP: " + str(fighter_hp) + "/" + str(fighter_data.get_max_hp())
    bandit_hp_bar.max_value = bandit_max_hp
    bandit_hp_bar.value = max(0, bandit_hp)

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
    attack_btn.pressed.connect(_on_attack_pressed)
    defend_btn.pressed.connect(_on_defend_pressed)

func _input(event):
    if event.is_action_pressed("ui_accept") and player_turn:
        player_attack()

func _process(_delta):
    if Input.is_action_just_pressed("ui_cancel"):
        get_tree().reload_current_scene()

func player_attack():
    var weapon_bonus: int = 10
    var atk = fighter_data.get_atk() + weapon_bonus
    var base_damage = max(0, atk - bandit_def)
    var variance = randf_range(0.85, 1.15)
    var damage = max(1, int(base_damage * variance))
    bandit_hp -= damage
    print("Fighter attacks! ", damage, " damage. Bandit HP: ", max(0, bandit_hp))
    show_damage(damage, $ColorRect2.position + Vector2(0, -20), Color.RED)
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
    var base_damage = max(0, bandit_atk - fighter_data.get_def())
    var variance = randf_range(0.85, 1.15)
    var damage = max(1, int(base_damage * variance))
    fighter_hp -= damage
    print("Bandit attacks! ", damage, " damage. Fighter HP: ", fighter_hp)
    show_damage(damage, $ColorRect.position + Vector2(0, -20), Color.WHITE)
    if fighter_hp <= 0:
        print("=== FIGHTER DEFEATED ===")
        player_turn = false
    update_ui()
