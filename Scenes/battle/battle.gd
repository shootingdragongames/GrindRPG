extends Node2D

# Grid settings
const SLOT_SIZE = Vector2(80, 80)
const GAP = Vector2(10, 25)
const PLAYER_GRID_ORIGIN = Vector2(50, 30)
const ENEMY_GRID_ORIGIN = Vector2(750, 30)

# Combat state
var combatants: Array = []
var current_turn_index: int = 0
var battle_active: bool = true

# UI refs
@onready var hp_bar = $UI/UIRoot/PartyPanel/ProgressBar
@onready var hp_label = $UI/UIRoot/PartyPanel/Label
@onready var attack_btn = $UI/UIRoot/PartyPanel/ActionButtons/Attack
@onready var defend_btn = $UI/UIRoot/PartyPanel/ActionButtons/Defend

func _ready():
    attack_btn.pressed.connect(_on_attack_pressed)
    defend_btn.pressed.connect(_on_defend_pressed)
    setup_grid()
    build_combatants()
    sort_by_initiative()
    print("=== BATTLE START ===")
    print_turn_order()
    start_turn()

# =====================
# GRID SETUP
# =====================

func setup_grid():
    for row in range(3):
        for col in range(3):
            var slot = ColorRect.new()
            slot.size = SLOT_SIZE
            slot.position = Vector2(
                PLAYER_GRID_ORIGIN.x + col * (SLOT_SIZE.x + GAP.x),
                PLAYER_GRID_ORIGIN.y + row * (SLOT_SIZE.y + GAP.y)
            )
            slot.color = Color(0.2, 0.2, 0.2, 0.5)
            add_child(slot)

    for row in range(3):
        for col in range(3):
            var slot = ColorRect.new()
            slot.size = SLOT_SIZE
            slot.position = Vector2(
                ENEMY_GRID_ORIGIN.x + col * (SLOT_SIZE.x + GAP.x),
                ENEMY_GRID_ORIGIN.y + row * (SLOT_SIZE.y + GAP.y)
            )
            slot.color = Color(0.3, 0.1, 0.1, 0.5)
            add_child(slot)

# =====================
# BUILD COMBATANTS
# =====================

func build_combatants():
    var party = GameState.selected_party
    for i in range(party.size()):
        var char_data = party[i]
        var grid_pos = Vector2(1, i)
        var rect = create_character_rect(char_data, grid_pos)
        combatants.append({
            "name": char_data.character_name,
            "type": "player",
            "data": char_data,
            "current_hp": char_data.get_max_hp(),
            "max_hp": char_data.get_max_hp(),
            "is_ko": false,
            "is_defending": false,
            "grid_pos": grid_pos,
            "rect": rect,
            "rolled_initiative": 0.0
        })

    var bandit = EnemyDB.get_enemy("bandit")
    if bandit:
        var avg_player_atk = get_avg_player_atk()
        var bandit_hp = bandit.base_hp
        var grid_pos = Vector2(1, 0)
        var rect = create_enemy_rect(bandit, grid_pos)
        combatants.append({
            "name": bandit.enemy_name,
            "type": "enemy",
            "data": bandit,
            "current_hp": bandit_hp,
            "max_hp": bandit_hp,
            "is_ko": false,
            "is_defending": false,
            "grid_pos": grid_pos,
            "rect": rect,
            "rolled_initiative": 0.0
        })

func get_avg_player_atk() -> int:
    var total = 0
    for c in combatants:
        if c.type == "player":
            total += c.data.get_atk()
    return max(1, total / max(1, combatants.size()))

func create_character_rect(char_data: CharacterData, grid_pos: Vector2) -> ColorRect:
    var rect = ColorRect.new()
    rect.size = SLOT_SIZE
    rect.color = char_data.player_color
    rect.position = Vector2(
        PLAYER_GRID_ORIGIN.x + grid_pos.x * (SLOT_SIZE.x + GAP.x),
        PLAYER_GRID_ORIGIN.y + grid_pos.y * (SLOT_SIZE.y + GAP.y)
    )
    var label = Label.new()
    label.text = char_data.character_name
    label.position = Vector2(0, SLOT_SIZE.y + 2)
    rect.add_child(label)
    add_child(rect)
    return rect

func create_enemy_rect(enemy_data: EnemyData, grid_pos: Vector2) -> ColorRect:
    var rect = ColorRect.new()
    rect.size = SLOT_SIZE
    rect.color = Color(0.5, 0.5, 0.5)
    rect.position = Vector2(
        ENEMY_GRID_ORIGIN.x + grid_pos.x * (SLOT_SIZE.x + GAP.x),
        ENEMY_GRID_ORIGIN.y + grid_pos.y * (SLOT_SIZE.y + GAP.y)
    )
    var label = Label.new()
    label.text = enemy_data.enemy_name
    label.position = Vector2(0, SLOT_SIZE.y + 2)
    rect.add_child(label)
    add_child(rect)
    return rect

# =====================
# INITIATIVE & TURN ORDER
# =====================

func get_rolled_initiative(combatant: Dictionary) -> float:
    var base = combatant.data.get_initiative()
    var lck = combatant.data.get_lck()
    var num_dice: int
    if base <= 25:
        num_dice = 1
    elif base <= 50:
        num_dice = 2
    elif base <= 75:
        num_dice = 3
    else:
        num_dice = 4

    var best_roll: float = 0
    for i in range(num_dice):
        var roll: float
        if randf() < lck * 0.001:
            roll = 20
            print(combatant.name, " got lucky! Natural 20!")
        else:
            roll = randf_range(1, 20)
        if roll > best_roll:
            best_roll = roll

    return base + best_roll

func sort_by_initiative():
    # Pre-roll everyone's initiative first
    for c in combatants:
        c["rolled_initiative"] = get_rolled_initiative(c)

    # Sort using stored values
    combatants.sort_custom(func(a, b):
        if a.rolled_initiative == b.rolled_initiative:
            return a.type == "player"
        return a.rolled_initiative > b.rolled_initiative
    )

func print_turn_order():
    print("Turn order:")
    for c in combatants:
        print("  ", c.name, " - Initiative: ", c.rolled_initiative)

# =====================
# TURN MANAGEMENT
# =====================

func start_turn():
    if not battle_active:
        return

    var attempts = 0
    while combatants[current_turn_index].is_ko:
        current_turn_index = (current_turn_index + 1) % combatants.size()
        attempts += 1
        if attempts > combatants.size():
            return

    var current = combatants[current_turn_index]
    highlight_active(current)
    update_ui(current)
    print("--- " + current.name + "'s turn ---")

    if current.type == "player":
        enable_buttons(true)
    else:
        enable_buttons(false)
        await get_tree().create_timer(0.8).timeout
        enemy_act(current)

func next_turn():
    if not battle_active:
        return
    current_turn_index = (current_turn_index + 1) % combatants.size()
    start_turn()

func highlight_active(active_combatant: Dictionary):
    for c in combatants:
        if c.rect:
            c.rect.modulate = Color(0.6, 0.6, 0.6) if c != active_combatant else Color(1, 1, 1)

func enable_buttons(enabled: bool):
    attack_btn.disabled = not enabled
    defend_btn.disabled = not enabled

# =====================
# PLAYER ACTIONS
# =====================

func _on_attack_pressed():
    var current = combatants[current_turn_index]
    if current.type != "player":
        return
    enable_buttons(false)
    player_attack(current)

func _on_defend_pressed():
    var current = combatants[current_turn_index]
    if current.type != "player":
        return
    enable_buttons(false)
    current.is_defending = true
    print(current.name, " defends!")
    next_turn()

func player_attack(attacker: Dictionary):
    var target = null
    for c in combatants:
        if c.type == "enemy" and not c.is_ko:
            target = c
            break

    if not target:
        check_battle_end()
        return

    var weapon_bonus: int = 10
    var atk = attacker.data.get_atk() + weapon_bonus
    var base_damage = max(0, atk - target.data.base_def)
    var variance = randf_range(0.85, 1.15)
    var damage = max(1, int(base_damage * variance))

    target.current_hp -= damage
    print(attacker.name, " attacks ", target.name, " for ", damage, " damage! HP: ", max(0, target.current_hp))
    show_damage(damage, target.rect.position + Vector2(40, 0), Color.RED)

    if target.current_hp <= 0:
        target.current_hp = 0
        target.is_ko = true
        target.rect.modulate = Color(0.3, 0.3, 0.3)
        print(target.name, " defeated!")

    update_ui(attacker)

    if check_battle_end():
        return

    next_turn()

# =====================
# ENEMY ACTIONS
# =====================

func enemy_act(enemy: Dictionary):
    var target = null
    for c in combatants:
        if c.type == "player" and not c.is_ko:
            target = c
            break

    if not target:
        check_battle_end()
        return

    var base_damage = max(0, enemy.data.base_atk - target.data.get_def())
    var variance = randf_range(0.85, 1.15)
    var damage = max(1, int(base_damage * variance))

    if target.is_defending:
        var reduction = randf_range(0.50, 0.75)
        damage = max(1, int(damage * (1.0 - reduction)))
        target.is_defending = false
        print(target.name, " blocked! Reduced to ", damage)

    target.current_hp -= damage
    print(enemy.name, " attacks ", target.name, " for ", damage, "! HP: ", max(0, target.current_hp))
    show_damage(damage, target.rect.position + Vector2(40, 0), Color.WHITE)

    if target.current_hp <= 0:
        target.current_hp = 0
        target.is_ko = true
        target.rect.modulate = Color(0.3, 0.3, 0.3)
        print(target.name, " is KO'd!")

    update_ui(combatants[current_turn_index])

    if check_battle_end():
        return

    next_turn()

# =====================
# BATTLE END CHECK
# =====================

func check_battle_end() -> bool:
    var players_alive = combatants.any(func(c): return c.type == "player" and not c.is_ko)
    var enemies_alive = combatants.any(func(c): return c.type == "enemy" and not c.is_ko)

    if not enemies_alive:
        battle_active = false
        print("=== VICTORY! ===")
        enable_buttons(false)
        return true

    if not players_alive:
        battle_active = false
        print("=== DEFEAT ===")
        enable_buttons(false)
        return true

    return false

# =====================
# UI
# =====================

func update_ui(active: Dictionary):
    hp_bar.max_value = active.max_hp
    hp_bar.value = active.current_hp
    hp_label.text = active.name + "  HP: " + str(active.current_hp) + "/" + str(active.max_hp)

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

func _process(_delta):
    if Input.is_action_just_pressed("ui_cancel"):
        get_tree().reload_current_scene()
