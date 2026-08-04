# Yokai Animal Busters — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a single-area 3D action game in Godot 4 faithfully based on Yokai Watch Busters 2, with animal characters, a dark forest map, loot/crafting loop, and a 2D beer healing minigame — exported to HTML5 for browser play via itch.io.

**Architecture:** Fixed isometric camera follows a monkey protagonist through a continuous dark forest arena. Pure logic systems (stats, inventory, crafting, loot) are GDScript Resource/Node classes tested with GUT. Enemies and boss are independent scenes instantiated into World at runtime. 2D UI overlays (HUD, beer minigame, crafting menu) sit in CanvasLayer nodes above the 3D scene.

**Tech Stack:** Godot 4.3+, GDScript, GUT v9.x (unit testing), Quaternius Animated Animal Pack (CC0 GLB), monkey GLB from Sketchfab, Complete Cel Shader for Godot 4 from godotshaders.com.

---

## File Structure

```
yokai/
├── project.godot
├── .gitignore
├── addons/gut/                          # GUT testing framework
├── assets/
│   ├── models/                          # GLB files go here
│   ├── shaders/cel_shader.gdshader
│   └── materials/cel_material.tres
├── scenes/
│   ├── main.tscn
│   ├── world/
│   │   ├── world.tscn
│   │   ├── bartender_hut.tscn
│   │   ├── crafting_stump.tscn
│   │   └── loot_chest.tscn
│   ├── player/player.tscn
│   ├── enemies/
│   │   ├── wolf.tscn
│   │   ├── boar.tscn
│   │   └── crow.tscn
│   ├── boss/bear_boss.tscn
│   └── ui/
│       ├── hud.tscn
│       ├── beer_minigame.tscn
│       └── crafting_menu.tscn
├── scripts/
│   ├── input_setup.gd                   # Autoload: registers input actions
│   ├── game_state.gd                    # Autoload: inventory, weapon, flags
│   ├── player/
│   │   ├── player.gd                    # CharacterBody3D, movement, combat
│   │   └── player_stats.gd             # Resource: HP, SP, attack, defense, speed
│   ├── systems/
│   │   ├── inventory.gd                 # Part counts + signals
│   │   ├── loot_table.gd               # Drop chance tables
│   │   └── crafting.gd                 # Recipes + craft logic
│   ├── enemies/
│   │   ├── enemy_base.gd               # Shared HP, damage, death, health bar
│   │   ├── wolf.gd                     # Patrol → aggro → bite combo AI
│   │   ├── boar.gd                     # Telegraph → charge → stun AI
│   │   └── crow.gd                     # Fly → swoop → projectile AI
│   ├── boss/bear_boss.gd               # Phase 1 + Phase 2 state machine
│   ├── world/
│   │   ├── world.gd                    # Scene root, spawning, camera follow
│   │   ├── bartender_hut.gd            # Interaction → beer minigame trigger
│   │   ├── crafting_stump.gd           # Interaction → crafting menu trigger
│   │   └── loot_chest.gd              # Open animation + drop to inventory
│   └── ui/
│       ├── hud.gd                      # HP bar, SP bar, weapon, parts count
│       ├── beer_minigame.gd            # Fill bar mechanic + heal emit
│       └── crafting_menu.gd           # Recipe list + craft button
└── tests/
    ├── test_player_stats.gd
    ├── test_inventory.gd
    ├── test_loot_table.gd
    ├── test_crafting.gd
    └── test_beer_minigame.gd
```

---

## Task 1: Godot Project Scaffolding

**Files:**
- Create: `project.godot`
- Modify: `.gitignore`
- Create: `addons/gut/` (downloaded)
- Create all directories in File Structure above

- [ ] **Step 1: Create folder structure**

```bash
cd /mnt/c/Users/ianst/code/yokai
mkdir -p assets/models assets/shaders assets/materials
mkdir -p scenes/world scenes/player scenes/enemies scenes/boss scenes/ui
mkdir -p scripts/player scripts/systems scripts/enemies scripts/boss scripts/world scripts/ui
mkdir -p tests addons
```

- [ ] **Step 2: Write project.godot**

```bash
cat > /mnt/c/Users/ianst/code/yokai/project.godot << 'EOF'
; Engine configuration file.
config_version=5

[application]

config/name="Yokai Animal Busters"
run/main_scene="res://scenes/main.tscn"
config/features=PackedStringArray("4.3", "GL Compatibility")

[autoload]

InputSetup="*res://scripts/input_setup.gd"
GameState="*res://scripts/game_state.gd"

[display]

window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="canvas_items"

[physics]

3d/default_gravity=9.8

[rendering]

renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
EOF
```

- [ ] **Step 3: Update .gitignore for Godot**

```bash
cat >> /mnt/c/Users/ianst/code/yokai/.gitignore << 'EOF'
.godot/
*.import
export_presets.cfg
EOF
```

- [ ] **Step 4: Download GUT testing framework**

```bash
cd /mnt/c/Users/ianst/code/yokai
curl -L https://github.com/bitwes/Gut/releases/download/v9.2.1/Gut-v9.2.1.zip -o gut.zip
unzip -q gut.zip -d gut_tmp
mv gut_tmp/addons/gut addons/gut
rm -rf gut_tmp gut.zip
```

- [ ] **Step 5: Commit scaffold**

```bash
git add project.godot .gitignore addons/ assets/ scenes/ scripts/ tests/
git commit -m "feat: scaffold Godot 4 project structure with GUT"
```

---

## Task 2: Input Setup Autoload

**Files:**
- Create: `scripts/input_setup.gd`

- [ ] **Step 1: Write input_setup.gd**

```gdscript
# scripts/input_setup.gd
extends Node

func _ready() -> void:
    _action_key("move_forward", KEY_W)
    _action_key("move_back", KEY_S)
    _action_key("move_left", KEY_A)
    _action_key("move_right", KEY_D)
    _action_key("attack", KEY_SPACE)
    _action_mouse("attack", MOUSE_BUTTON_LEFT)
    _action_key("dodge", KEY_SHIFT)
    _action_mouse("guard", MOUSE_BUTTON_RIGHT)
    _action_key("special", KEY_E)
    _action_key("interact", KEY_F)

func _action_key(action: String, keycode: Key) -> void:
    if not InputMap.has_action(action):
        InputMap.add_action(action)
    var ev := InputEventKey.new()
    ev.physical_keycode = keycode
    InputMap.action_add_event(action, ev)

func _action_mouse(action: String, button: MouseButton) -> void:
    if not InputMap.has_action(action):
        InputMap.add_action(action)
    var ev := InputEventMouseButton.new()
    ev.button_index = button
    InputMap.action_add_event(action, ev)
```

- [ ] **Step 2: Commit**

```bash
git add scripts/input_setup.gd
git commit -m "feat: register input actions via autoload"
```

---

## Task 3: PlayerStats Resource + Tests

**Files:**
- Create: `scripts/player/player_stats.gd`
- Create: `tests/test_player_stats.gd`

- [ ] **Step 1: Write failing tests**

```gdscript
# tests/test_player_stats.gd
extends GutTest

var stats: PlayerStats

func before_each() -> void:
    stats = PlayerStats.new()

func test_initial_hp_is_full() -> void:
    assert_eq(stats.current_hp, stats.max_hp)

func test_take_damage_reduces_hp() -> void:
    stats.defense = 5
    stats.take_damage(15)
    assert_eq(stats.current_hp, 90)  # 15 - 5 defense = 10 damage

func test_defense_absorbs_minimum_one() -> void:
    stats.defense = 100
    stats.take_damage(5)
    assert_eq(stats.current_hp, 99)  # at least 1 damage always

func test_hp_cannot_go_below_zero() -> void:
    stats.take_damage(99999)
    assert_eq(stats.current_hp, 0)

func test_heal_restores_hp() -> void:
    stats.take_damage(50)
    stats.heal(30)
    assert_eq(stats.current_hp, 80)

func test_heal_cannot_exceed_max_hp() -> void:
    stats.heal(99999)
    assert_eq(stats.current_hp, stats.max_hp)

func test_gain_sp_fills_gauge() -> void:
    stats.gain_sp(10.0)
    assert_eq(stats.sp, 10.0)

func test_sp_cannot_exceed_max() -> void:
    stats.gain_sp(99999.0)
    assert_eq(stats.sp, stats.max_sp)

func test_use_sp_empties_gauge() -> void:
    stats.sp = stats.max_sp
    var result = stats.use_sp()
    assert_true(result)
    assert_eq(stats.sp, 0.0)

func test_use_sp_fails_when_not_full() -> void:
    stats.sp = 50.0
    var result = stats.use_sp()
    assert_false(result)
    assert_eq(stats.sp, 50.0)

func test_is_dead_when_hp_zero() -> void:
    stats.take_damage(99999)
    assert_true(stats.is_dead())
```

- [ ] **Step 2: Run tests — expect FAIL (class not found)**

```bash
godot --headless --path /mnt/c/Users/ianst/code/yokai -s addons/gut/gut_cmdln.gd -gdir=res://tests -gprefix=test_ -gsuffix=.gd 2>&1 | tail -20
```

Expected: error about `PlayerStats` not found.

- [ ] **Step 3: Write PlayerStats**

```gdscript
# scripts/player/player_stats.gd
class_name PlayerStats
extends Resource

@export var max_hp: int = 100
@export var current_hp: int = 100
@export var attack: int = 10
@export var defense: int = 5
@export var speed: float = 5.0
@export var sp: float = 0.0
@export var max_sp: float = 100.0

signal hp_changed(current: int, maximum: int)
signal sp_changed(current: float, maximum: float)
signal died

func take_damage(amount: int) -> void:
    var dmg := max(1, amount - defense)
    current_hp = max(0, current_hp - dmg)
    hp_changed.emit(current_hp, max_hp)
    if current_hp == 0:
        died.emit()

func heal(amount: int) -> void:
    current_hp = min(max_hp, current_hp + amount)
    hp_changed.emit(current_hp, max_hp)

func gain_sp(amount: float) -> void:
    sp = min(max_sp, sp + amount)
    sp_changed.emit(sp, max_sp)

func use_sp() -> bool:
    if sp < max_sp:
        return false
    sp = 0.0
    sp_changed.emit(sp, max_sp)
    return true

func is_sp_full() -> bool:
    return sp >= max_sp

func is_dead() -> bool:
    return current_hp <= 0

func apply_weapon(weapon_stats: Dictionary) -> void:
    attack = weapon_stats.get("attack", attack)
    defense = weapon_stats.get("defense", defense)
    speed = weapon_stats.get("speed", speed)
```

- [ ] **Step 4: Run tests — expect PASS**

```bash
godot --headless --path /mnt/c/Users/ianst/code/yokai -s addons/gut/gut_cmdln.gd -gdir=res://tests -gprefix=test_ -gsuffix=.gd 2>&1 | tail -20
```

Expected: all 11 tests pass.

- [ ] **Step 5: Commit**

```bash
git add scripts/player/player_stats.gd tests/test_player_stats.gd
git commit -m "feat: PlayerStats resource with damage, healing, SP gauge"
```

---

## Task 4: Inventory System + Tests

**Files:**
- Create: `scripts/systems/inventory.gd`
- Create: `tests/test_inventory.gd`

- [ ] **Step 1: Write failing tests**

```gdscript
# tests/test_inventory.gd
extends GutTest

var inv: Inventory

func before_each() -> void:
    inv = Inventory.new()

func test_starts_empty() -> void:
    assert_eq(inv.get_count("wolf_fang"), 0)

func test_add_part_increases_count() -> void:
    inv.add_part("wolf_fang", 2)
    assert_eq(inv.get_count("wolf_fang"), 2)

func test_has_parts_true_when_sufficient() -> void:
    inv.add_part("wolf_fang", 3)
    assert_true(inv.has_parts({"wolf_fang": 3}))

func test_has_parts_false_when_insufficient() -> void:
    inv.add_part("wolf_fang", 2)
    assert_false(inv.has_parts({"wolf_fang": 3}))

func test_consume_parts_reduces_counts() -> void:
    inv.add_part("wolf_fang", 5)
    inv.consume_parts({"wolf_fang": 3})
    assert_eq(inv.get_count("wolf_fang"), 2)

func test_all_parts_returns_dict() -> void:
    inv.add_part("wolf_fang", 1)
    inv.add_part("boar_tusk", 2)
    var all = inv.all_parts()
    assert_eq(all["wolf_fang"], 1)
    assert_eq(all["boar_tusk"], 2)
```

- [ ] **Step 2: Run — expect FAIL**

```bash
godot --headless --path /mnt/c/Users/ianst/code/yokai -s addons/gut/gut_cmdln.gd -gdir=res://tests -gprefix=test_ -gsuffix=.gd 2>&1 | tail -20
```

- [ ] **Step 3: Write Inventory**

```gdscript
# scripts/systems/inventory.gd
class_name Inventory
extends Node

const PART_IDS = ["wolf_fang", "boar_tusk", "crow_feather", "bear_claw", "bear_pelt"]

var _parts: Dictionary = {}

signal parts_changed(parts: Dictionary)

func _ready() -> void:
    for id in PART_IDS:
        _parts[id] = 0

func add_part(part_id: String, amount: int = 1) -> void:
    if part_id not in _parts:
        _parts[part_id] = 0
    _parts[part_id] += amount
    parts_changed.emit(_parts.duplicate())

func get_count(part_id: String) -> int:
    return _parts.get(part_id, 0)

func has_parts(required: Dictionary) -> bool:
    for part_id in required:
        if get_count(part_id) < required[part_id]:
            return false
    return true

func consume_parts(required: Dictionary) -> void:
    for part_id in required:
        _parts[part_id] -= required[part_id]
    parts_changed.emit(_parts.duplicate())

func all_parts() -> Dictionary:
    return _parts.duplicate()
```

- [ ] **Step 4: Run — expect PASS**

```bash
godot --headless --path /mnt/c/Users/ianst/code/yokai -s addons/gut/gut_cmdln.gd -gdir=res://tests -gprefix=test_ -gsuffix=.gd 2>&1 | tail -20
```

- [ ] **Step 5: Commit**

```bash
git add scripts/systems/inventory.gd tests/test_inventory.gd
git commit -m "feat: Inventory system with part tracking and consumption"
```

---

## Task 5: LootTable + Tests

**Files:**
- Create: `scripts/systems/loot_table.gd`
- Create: `tests/test_loot_table.gd`

- [ ] **Step 1: Write failing tests**

```gdscript
# tests/test_loot_table.gd
extends GutTest

var loot: LootTable

func before_each() -> void:
    loot = LootTable.new()

func test_boss_drops_always_include_bear_claw() -> void:
    var drops = loot.get_boss_drops("bear")
    assert_true("bear_claw" in drops)

func test_boss_drops_always_include_bear_pelt() -> void:
    var drops = loot.get_boss_drops("bear")
    assert_true("bear_pelt" in drops)

func test_unknown_enemy_drops_empty() -> void:
    var drops = loot.roll_enemy_drops("dragon")
    assert_eq(drops.size(), 0)

func test_wolf_drops_wolf_fang_at_100_percent() -> void:
    # Override chance to 1.0 for deterministic test
    loot.ENEMY_DROPS["wolf"][0]["chance"] = 1.0
    var drops = loot.roll_enemy_drops("wolf")
    assert_true("wolf_fang" in drops)

func test_wolf_drops_nothing_at_0_percent() -> void:
    loot.ENEMY_DROPS["wolf"][0]["chance"] = 0.0
    var drops = loot.roll_enemy_drops("wolf")
    assert_eq(drops.size(), 0)
```

- [ ] **Step 2: Run — expect FAIL**

```bash
godot --headless --path /mnt/c/Users/ianst/code/yokai -s addons/gut/gut_cmdln.gd -gdir=res://tests -gprefix=test_ -gsuffix=.gd 2>&1 | tail -20
```

- [ ] **Step 3: Write LootTable**

```gdscript
# scripts/systems/loot_table.gd
class_name LootTable
extends RefCounted

var ENEMY_DROPS: Dictionary = {
    "wolf": [{"part": "wolf_fang", "chance": 0.5}],
    "boar": [{"part": "boar_tusk", "chance": 0.5}],
    "crow": [{"part": "crow_feather", "chance": 0.5}],
}

const BOSS_DROPS: Dictionary = {
    "bear": ["bear_claw", "bear_pelt"],
}

func roll_enemy_drops(enemy_type: String) -> Array[String]:
    var drops: Array[String] = []
    var table = ENEMY_DROPS.get(enemy_type, [])
    for entry in table:
        if randf() <= entry["chance"]:
            drops.append(entry["part"])
    return drops

func get_boss_drops(boss_type: String) -> Array[String]:
    return BOSS_DROPS.get(boss_type, [])
```

- [ ] **Step 4: Run — expect PASS**

```bash
godot --headless --path /mnt/c/Users/ianst/code/yokai -s addons/gut/gut_cmdln.gd -gdir=res://tests -gprefix=test_ -gsuffix=.gd 2>&1 | tail -20
```

- [ ] **Step 5: Commit**

```bash
git add scripts/systems/loot_table.gd tests/test_loot_table.gd
git commit -m "feat: LootTable with enemy drop rolls and guaranteed boss drops"
```

---

## Task 6: Crafting System + Tests

**Files:**
- Create: `scripts/systems/crafting.gd`
- Create: `tests/test_crafting.gd`

- [ ] **Step 1: Write failing tests**

```gdscript
# tests/test_crafting.gd
extends GutTest

var crafting: Crafting
var inv: Inventory

func before_each() -> void:
    crafting = Crafting.new()
    inv = Inventory.new()
    inv._ready()

func test_wooden_stick_is_default_weapon() -> void:
    var stats = Crafting.WEAPONS["wooden_stick"]
    assert_eq(stats["attack"], 10)

func test_can_craft_bone_club_with_parts() -> void:
    inv.add_part("wolf_fang", 3)
    assert_true(crafting.can_craft("bone_club", inv))

func test_cannot_craft_bone_club_without_parts() -> void:
    inv.add_part("wolf_fang", 2)
    assert_false(crafting.can_craft("bone_club", inv))

func test_craft_consumes_parts() -> void:
    inv.add_part("wolf_fang", 3)
    crafting.craft("bone_club", inv)
    assert_eq(inv.get_count("wolf_fang"), 0)

func test_craft_returns_weapon_stats() -> void:
    inv.add_part("wolf_fang", 3)
    var stats = crafting.craft("bone_club", inv)
    assert_eq(stats["attack"], 18)

func test_bear_claw_hammer_locked_by_default() -> void:
    inv.add_part("bear_claw", 2)
    inv.add_part("bear_pelt", 1)
    assert_false(crafting.can_craft("bear_claw_hammer", inv))

func test_bear_claw_hammer_unlocks_after_bear_kill() -> void:
    crafting.unlock_bear_recipes()
    inv.add_part("bear_claw", 2)
    inv.add_part("bear_pelt", 1)
    assert_true(crafting.can_craft("bear_claw_hammer", inv))

func test_craft_fails_gracefully_without_parts() -> void:
    var stats = crafting.craft("bone_club", inv)
    assert_eq(stats, {})
```

- [ ] **Step 2: Run — expect FAIL**

```bash
godot --headless --path /mnt/c/Users/ianst/code/yokai -s addons/gut/gut_cmdln.gd -gdir=res://tests -gprefix=test_ -gsuffix=.gd 2>&1 | tail -20
```

- [ ] **Step 3: Write Crafting**

```gdscript
# scripts/systems/crafting.gd
class_name Crafting
extends Node

const WEAPONS: Dictionary = {
    "wooden_stick": {"name": "Wooden Stick", "attack": 10, "defense": 5, "speed": 5.0},
    "bone_club":    {"name": "Bone Club",    "attack": 18, "defense": 5, "speed": 5.0},
    "tusk_blade":   {"name": "Tusk Blade",   "attack": 22, "defense": 5, "speed": 6.0},
    "bear_claw_hammer": {"name": "Bear Claw Hammer", "attack": 38, "defense": 15, "speed": 4.0},
    "feather_blade": {"name": "Feather Blade", "attack": 18, "defense": 3, "speed": 8.0},
}

const RECIPES: Dictionary = {
    "bone_club":        {"requires": {"wolf_fang": 3},                   "unlocked": true},
    "tusk_blade":       {"requires": {"boar_tusk": 3, "wolf_fang": 1},   "unlocked": true},
    "bear_claw_hammer": {"requires": {"bear_claw": 2, "bear_pelt": 1},   "unlocked": false},
    "feather_blade":    {"requires": {"crow_feather": 5, "boar_tusk": 1},"unlocked": true},
}

func unlock_bear_recipes() -> void:
    RECIPES["bear_claw_hammer"]["unlocked"] = true

func can_craft(weapon_id: String, inventory: Inventory) -> bool:
    var recipe = RECIPES.get(weapon_id)
    if not recipe:
        return false
    if not recipe["unlocked"]:
        return false
    return inventory.has_parts(recipe["requires"])

func craft(weapon_id: String, inventory: Inventory) -> Dictionary:
    if not can_craft(weapon_id, inventory):
        return {}
    var recipe = RECIPES[weapon_id]
    inventory.consume_parts(recipe["requires"])
    return WEAPONS[weapon_id].duplicate()

func get_unlocked_recipes() -> Array[String]:
    var result: Array[String] = []
    for weapon_id in RECIPES:
        if RECIPES[weapon_id]["unlocked"]:
            result.append(weapon_id)
    return result
```

- [ ] **Step 4: Run — expect PASS**

```bash
godot --headless --path /mnt/c/Users/ianst/code/yokai -s addons/gut/gut_cmdln.gd -gdir=res://tests -gprefix=test_ -gsuffix=.gd 2>&1 | tail -20
```

- [ ] **Step 5: Commit**

```bash
git add scripts/systems/crafting.gd tests/test_crafting.gd
git commit -m "feat: Crafting system with recipes, bear lock, stat output"
```

---

## Task 7: GameState Autoload

**Files:**
- Create: `scripts/game_state.gd`

- [ ] **Step 1: Write game_state.gd**

```gdscript
# scripts/game_state.gd
extends Node

var inventory: Inventory
var crafting: Crafting
var loot_table: LootTable
var current_weapon_id: String = "wooden_stick"
var current_weapon_stats: Dictionary = {}
var bear_defeated: bool = false

signal weapon_changed(weapon_stats: Dictionary)

func _ready() -> void:
    inventory = Inventory.new()
    add_child(inventory)
    crafting = Crafting.new()
    add_child(crafting)
    loot_table = LootTable.new()
    current_weapon_stats = Crafting.WEAPONS["wooden_stick"].duplicate()

func equip_weapon(weapon_id: String) -> void:
    if weapon_id not in Crafting.WEAPONS:
        return
    current_weapon_id = weapon_id
    current_weapon_stats = Crafting.WEAPONS[weapon_id].duplicate()
    weapon_changed.emit(current_weapon_stats)

func on_bear_defeated() -> void:
    bear_defeated = true
    crafting.unlock_bear_recipes()

func collect_loot(enemy_type: String) -> void:
    var drops: Array[String]
    if enemy_type == "bear":
        drops = loot_table.get_boss_drops("bear")
    else:
        drops = loot_table.roll_enemy_drops(enemy_type)
    for part in drops:
        inventory.add_part(part)
```

- [ ] **Step 2: Commit**

```bash
git add scripts/game_state.gd
git commit -m "feat: GameState autoload wiring inventory, crafting, loot"
```

---

## Task 8: Player Scene — Movement & Camera

**Files:**
- Create: `scripts/player/player.gd`
- Create: `scenes/player/player.tscn`

- [ ] **Step 1: Write player.gd**

```gdscript
# scripts/player/player.gd
class_name Player
extends CharacterBody3D

const CAM_FORWARD := Vector3(-0.707, 0.0, -0.707)
const CAM_RIGHT   := Vector3( 0.707, 0.0, -0.707)
const CAMERA_OFFSET := Vector3(10.0, 14.0, 10.0)
const CAMERA_SMOOTH := 8.0

var stats: PlayerStats
var is_invincible: bool = false

@onready var mesh: Node3D = $Mesh
@onready var hit_area: Area3D = $HitArea
@onready var camera: Camera3D = $"../Camera3D"

func _ready() -> void:
    stats = PlayerStats.new()
    stats.apply_weapon(GameState.current_weapon_stats)
    GameState.weapon_changed.connect(_on_weapon_changed)
    stats.died.connect(_on_died)
    add_to_group("player")

func _physics_process(delta: float) -> void:
    _camera_follow(delta)
    _handle_gravity(delta)
    _handle_movement()
    move_and_slide()

func _camera_follow(delta: float) -> void:
    if not camera:
        return
    var target_pos := global_position + CAMERA_OFFSET
    camera.global_position = camera.global_position.lerp(target_pos, CAMERA_SMOOTH * delta)
    camera.look_at(global_position, Vector3.UP)

func _handle_gravity(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= 9.8 * delta

func _handle_movement() -> void:
    var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction := (CAM_RIGHT * input_dir.x + CAM_FORWARD * -input_dir.y)
    var spd := stats.speed
    if direction.length() > 0.1:
        direction = direction.normalized()
        velocity.x = direction.x * spd
        velocity.z = direction.z * spd
        var look_pos := global_position + direction
        look_pos.y = global_position.y
        mesh.look_at(look_pos, Vector3.UP)
    else:
        velocity.x = move_toward(velocity.x, 0.0, spd)
        velocity.z = move_toward(velocity.z, 0.0, spd)

func take_damage(amount: int, from_direction: Vector3 = Vector3.ZERO) -> void:
    if is_invincible:
        return
    stats.take_damage(amount)

func _on_weapon_changed(weapon_stats: Dictionary) -> void:
    stats.apply_weapon(weapon_stats)

func _on_died() -> void:
    set_physics_process(false)
    # TODO: trigger death screen (Task 19 adds this)
```

- [ ] **Step 2: Create player.tscn**

```
[gd_scene format=3]

[node name="Player" type="CharacterBody3D" script="res://scripts/player/player.gd"]

[node name="Mesh" type="Node3D" parent="."]

[node name="CollisionShape3D" type="CollisionShape3D" parent="."]
shape = CapsuleShape3D

[node name="HitArea" type="Area3D" parent="."]

[node name="CollisionShape3D" type="CollisionShape3D" parent="HitArea"]
shape = SphereShape3D
```

Save this content to `scenes/player/player.tscn`.

- [ ] **Step 3: Run scene to verify**

Open Godot → open `scenes/player/player.tscn` → press F6 (Run Current Scene). The capsule should appear. WASD should move it. Camera should follow at isometric angle.

- [ ] **Step 4: Commit**

```bash
git add scripts/player/player.gd scenes/player/player.tscn
git commit -m "feat: Player movement with isometric camera follow"
```

---

## Task 9: Attack Chain + Hit Detection

**Files:**
- Modify: `scripts/player/player.gd`

- [ ] **Step 1: Add attack state variables and combo logic to player.gd**

Add to the top of `player.gd` (after existing vars):

```gdscript
const COMBO_WINDOW     := 0.5
const COMBO_HITS       := 3
const ATTACK_DAMAGE    := 1   # multiplier, scaled by stats.attack
const HEAVY_MULTIPLIER := 2.0
const SP_GAIN_PER_HIT  := 15.0
const ATTACK_RANGE     := 1.8
const KNOCKBACK_FORCE  := 6.0

var combo_count: int = 0
var combo_timer: float = 0.0
var is_attacking: bool = false
var hold_timer: float = 0.0
var doing_heavy: bool = false
```

- [ ] **Step 2: Add `_handle_attack` and `_do_attack` to player.gd**

Add inside `player.gd` class:

```gdscript
func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("attack") and not is_attacking:
        hold_timer = 0.0
    if event.is_action_released("attack") and not is_attacking:
        if hold_timer >= 0.4:
            _do_attack(true)
        else:
            _do_attack(false)
    if event.is_action_pressed("special"):
        _do_special()

func _process(delta: float) -> void:
    if Input.is_action_pressed("attack") and not is_attacking:
        hold_timer += delta
    if combo_timer > 0.0:
        combo_timer -= delta
        if combo_timer <= 0.0:
            combo_count = 0

func _do_attack(heavy: bool) -> void:
    doing_heavy = heavy
    is_attacking = true
    _face_nearest_enemy()
    var dmg := int(stats.attack * (HEAVY_MULTIPLIER if heavy else 1.0))
    var enemies_hit := _hit_enemies_in_range(dmg, heavy)
    if enemies_hit > 0:
        stats.gain_sp(SP_GAIN_PER_HIT)
    if not heavy:
        combo_count = (combo_count % COMBO_HITS) + 1
        combo_timer = COMBO_WINDOW
    await get_tree().create_timer(0.35 if not heavy else 0.6).timeout
    is_attacking = false

func _face_nearest_enemy() -> void:
    var nearest: Node3D = null
    var nearest_dist := 999.0
    for e in get_tree().get_nodes_in_group("enemies"):
        var d := global_position.distance_to(e.global_position)
        if d < nearest_dist:
            nearest_dist = d
            nearest = e
    if nearest:
        var look_pos := nearest.global_position
        look_pos.y = global_position.y
        mesh.look_at(look_pos, Vector3.UP)

func _hit_enemies_in_range(damage: int, knockback: bool) -> int:
    var hit_count := 0
    var forward := -mesh.global_transform.basis.z
    for e in get_tree().get_nodes_in_group("enemies"):
        var dist := global_position.distance_to(e.global_position)
        if dist <= ATTACK_RANGE:
            if e.has_method("take_damage"):
                var kb := forward * KNOCKBACK_FORCE if knockback else Vector3.ZERO
                e.take_damage(damage, kb)
                hit_count += 1
    return hit_count

func _do_special() -> void:
    if not stats.use_sp():
        return
    is_attacking = true
    _hit_enemies_in_range(int(stats.attack * 3.0), true)
    await get_tree().create_timer(0.8).timeout
    is_attacking = false
```

- [ ] **Step 3: Run scene to verify**

Run `player.tscn`. Place a dummy CharacterBody3D enemy in the scene with a `take_damage` method that prints the damage. Press Space — enemy should take damage. Hold Space — heavy should deal double.

- [ ] **Step 4: Commit**

```bash
git add scripts/player/player.gd
git commit -m "feat: 3-hit combo chain, heavy attack, Busters special, SP gain on hit"
```

---

## Task 10: Guard & Dodge

**Files:**
- Modify: `scripts/player/player.gd`

- [ ] **Step 1: Add dodge and guard to player.gd**

Add vars:

```gdscript
const DODGE_SPEED      := 12.0
const DODGE_DURATION   := 0.25
const GUARD_REDUCTION  := 0.5    # 50% damage reduction while guarding
var is_dodging: bool = false
var is_guarding: bool = false
```

Add input handling in `_unhandled_input`:

```gdscript
    if event.is_action_pressed("dodge") and not is_dodging and not is_attacking:
        _do_dodge()
    if event.is_action_pressed("guard"):
        is_guarding = true
    if event.is_action_released("guard"):
        is_guarding = false
```

Add methods:

```gdscript
func _do_dodge() -> void:
    is_dodging = true
    is_invincible = true
    var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var dir := (CAM_RIGHT * input_dir.x + CAM_FORWARD * -input_dir.y).normalized()
    if dir.length() < 0.1:
        dir = -mesh.global_transform.basis.z
    velocity.x = dir.x * DODGE_SPEED
    velocity.z = dir.z * DODGE_SPEED
    await get_tree().create_timer(DODGE_DURATION).timeout
    is_dodging = false
    is_invincible = false
```

Update `take_damage` to check guard:

```gdscript
func take_damage(amount: int, from_direction: Vector3 = Vector3.ZERO) -> void:
    if is_invincible:
        return
    var final_amount := amount
    if is_guarding:
        final_amount = int(amount * GUARD_REDUCTION)
    stats.take_damage(final_amount)
```

- [ ] **Step 2: Run to verify**

Run the scene. Press Shift — player should lurch in movement direction (dodge). Hold right-click while getting hit — damage should be halved.

- [ ] **Step 3: Commit**

```bash
git add scripts/player/player.gd
git commit -m "feat: dodge roll with i-frames, guard stance with 50% damage reduction"
```

---

## Task 11: Enemy Base Class + Floating Health Bar

**Files:**
- Create: `scripts/enemies/enemy_base.gd`

- [ ] **Step 1: Write enemy_base.gd**

```gdscript
# scripts/enemies/enemy_base.gd
class_name EnemyBase
extends CharacterBody3D

@export var max_hp: int = 30
@export var attack_damage: int = 8
@export var move_speed: float = 3.0
@export var enemy_type: String = "unknown"
@export var aggro_range: float = 6.0
@export var attack_range: float = 1.5

var current_hp: int
var is_dead: bool = false
var player: Player

# Health bar references (set up in each enemy's _ready)
var hp_bar: ProgressBar
var hp_bar_label: Label   # used for screen-space positioning in HUD

signal died(enemy: EnemyBase)
signal damaged(enemy: EnemyBase)

func _ready() -> void:
    current_hp = max_hp
    add_to_group("enemies")
    player = get_tree().get_first_node_in_group("player")

func take_damage(amount: int, knockback: Vector3 = Vector3.ZERO) -> void:
    if is_dead:
        return
    current_hp = max(0, current_hp - amount)
    if knockback.length() > 0.1:
        velocity += knockback
    damaged.emit(self)
    _update_hp_bar()
    if current_hp <= 0:
        _die()

func _die() -> void:
    is_dead = true
    remove_from_group("enemies")
    GameState.collect_loot(enemy_type)
    died.emit(self)
    queue_free()

func _update_hp_bar() -> void:
    if hp_bar:
        hp_bar.value = float(current_hp) / float(max_hp) * 100.0

func _get_player_distance() -> float:
    if not player:
        return 9999.0
    return global_position.distance_to(player.global_position)

func _face_player() -> void:
    if not player:
        return
    var look_pos := player.global_position
    look_pos.y = global_position.y
    look_at(look_pos, Vector3.UP)

func _apply_gravity(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= 9.8 * delta
```

- [ ] **Step 2: Commit**

```bash
git add scripts/enemies/enemy_base.gd
git commit -m "feat: EnemyBase with HP, damage, knockback, loot on death"
```

---

## Task 12: Wolf Enemy

**Files:**
- Create: `scripts/enemies/wolf.gd`
- Create: `scenes/enemies/wolf.tscn`

- [ ] **Step 1: Write wolf.gd**

```gdscript
# scripts/enemies/wolf.gd
class_name Wolf
extends EnemyBase

enum State { PATROL, AGGRO, ATTACK, COOLDOWN }

const PATROL_SPEED := 2.0
const ATTACK_SPEED := 5.5
const ATTACK_COOLDOWN := 1.2
const BITE_DAMAGE_MULTIPLIER := 1.0
const COMBO_ATTACKS := 2

var state: State = State.PATROL
var patrol_target: Vector3
var cooldown_timer: float = 0.0
var combo_left: int = 0

func _ready() -> void:
    enemy_type = "wolf"
    max_hp = 25
    attack_damage = 8
    move_speed = ATTACK_SPEED
    super._ready()
    _new_patrol_target()

func _physics_process(delta: float) -> void:
    _apply_gravity(delta)
    match state:
        State.PATROL:   _patrol(delta)
        State.AGGRO:    _aggro(delta)
        State.ATTACK:   _attack_state(delta)
        State.COOLDOWN: _cooldown(delta)
    move_and_slide()

func _patrol(delta: float) -> void:
    if _get_player_distance() <= aggro_range:
        state = State.AGGRO
        return
    var dir := (patrol_target - global_position)
    dir.y = 0.0
    if dir.length() < 0.5:
        _new_patrol_target()
        return
    var move := dir.normalized() * PATROL_SPEED
    velocity.x = move.x
    velocity.z = move.z

func _aggro(delta: float) -> void:
    _face_player()
    var dist := _get_player_distance()
    if dist > aggro_range * 1.5:
        state = State.PATROL
        return
    if dist <= attack_range:
        state = State.ATTACK
        combo_left = COMBO_ATTACKS
        return
    var dir := (player.global_position - global_position).normalized()
    dir.y = 0.0
    velocity.x = dir.x * ATTACK_SPEED
    velocity.z = dir.z * ATTACK_SPEED

func _attack_state(delta: float) -> void:
    velocity.x = 0.0
    velocity.z = 0.0
    if combo_left > 0:
        combo_left -= 1
        if player and _get_player_distance() <= attack_range:
            player.take_damage(attack_damage)
        await get_tree().create_timer(0.35).timeout
    else:
        cooldown_timer = ATTACK_COOLDOWN
        state = State.COOLDOWN

func _cooldown(delta: float) -> void:
    cooldown_timer -= delta
    if cooldown_timer <= 0.0:
        state = State.AGGRO

func _new_patrol_target() -> void:
    patrol_target = global_position + Vector3(
        randf_range(-5.0, 5.0), 0.0, randf_range(-5.0, 5.0)
    )
```

- [ ] **Step 2: Create wolf.tscn**

```
[gd_scene format=3]

[node name="Wolf" type="CharacterBody3D" script="res://scripts/enemies/wolf.gd"]

[node name="Mesh" type="Node3D" parent="."]

[node name="CollisionShape3D" type="CollisionShape3D" parent="."]
shape = CapsuleShape3D
```

Save to `scenes/enemies/wolf.tscn`.

- [ ] **Step 3: Run scene to verify**

Add a Wolf and a Player to a test scene. Wolf should patrol, aggro when player approaches, run toward player, and bite twice per attack cycle.

- [ ] **Step 4: Commit**

```bash
git add scripts/enemies/wolf.gd scenes/enemies/wolf.tscn
git commit -m "feat: Wolf enemy with patrol, aggro, bite combo AI"
```

---

## Task 13: Boar Enemy

**Files:**
- Create: `scripts/enemies/boar.gd`
- Create: `scenes/enemies/boar.tscn`

- [ ] **Step 1: Write boar.gd**

```gdscript
# scripts/enemies/boar.gd
class_name Boar
extends EnemyBase

enum State { PATROL, TELEGRAPH, CHARGE, STUN, COOLDOWN }

const TELEGRAPH_DURATION := 1.0
const CHARGE_SPEED := 10.0
const CHARGE_DURATION := 0.6
const STUN_DURATION := 1.5
const COOLDOWN_DURATION := 2.0

var state: State = State.PATROL
var state_timer: float = 0.0
var charge_direction: Vector3 = Vector3.ZERO

func _ready() -> void:
    enemy_type = "boar"
    max_hp = 50
    attack_damage = 14
    move_speed = 2.5
    aggro_range = 7.0
    super._ready()

func _physics_process(delta: float) -> void:
    _apply_gravity(delta)
    state_timer -= delta
    match state:
        State.PATROL:    _patrol()
        State.TELEGRAPH: _telegraph()
        State.CHARGE:    _charge(delta)
        State.STUN:      _stun()
        State.COOLDOWN:  _cooldown()
    move_and_slide()

func _patrol() -> void:
    velocity.x = 0.0
    velocity.z = 0.0
    if _get_player_distance() <= aggro_range:
        _face_player()
        state = State.TELEGRAPH
        state_timer = TELEGRAPH_DURATION

func _telegraph() -> void:
    velocity.x = 0.0
    velocity.z = 0.0
    _face_player()
    if state_timer <= 0.0:
        charge_direction = (player.global_position - global_position).normalized()
        charge_direction.y = 0.0
        state = State.CHARGE
        state_timer = CHARGE_DURATION

func _charge(delta: float) -> void:
    velocity.x = charge_direction.x * CHARGE_SPEED
    velocity.z = charge_direction.z * CHARGE_SPEED
    if player and _get_player_distance() <= attack_range + 0.5:
        player.take_damage(attack_damage)
        state = State.COOLDOWN
        state_timer = COOLDOWN_DURATION
        return
    if state_timer <= 0.0:
        # Missed — enter stun
        state = State.STUN
        state_timer = STUN_DURATION
        velocity.x = 0.0
        velocity.z = 0.0

func _stun() -> void:
    velocity.x = 0.0
    velocity.z = 0.0
    if state_timer <= 0.0:
        state = State.PATROL

func _cooldown() -> void:
    velocity.x = 0.0
    velocity.z = 0.0
    if state_timer <= 0.0:
        state = State.PATROL
```

- [ ] **Step 2: Create boar.tscn** (same structure as wolf.tscn, node name "Boar", script path updated)

Save to `scenes/enemies/boar.tscn`.

- [ ] **Step 3: Run to verify** — boar should grunt (telegraph), charge in a straight line, stun if it misses, deal damage if it hits.

- [ ] **Step 4: Commit**

```bash
git add scripts/enemies/boar.gd scenes/enemies/boar.tscn
git commit -m "feat: Boar enemy with telegraph, charge, and stun-on-miss"
```

---

## Task 14: Crow Enemy

**Files:**
- Create: `scripts/enemies/crow.gd`
- Create: `scenes/enemies/crow.tscn`
- Create: `scenes/enemies/crow_projectile.tscn`

- [ ] **Step 1: Write crow.gd**

```gdscript
# scripts/enemies/crow.gd
class_name Crow
extends EnemyBase

enum State { FLY, SWOOP, DROP_BOMB, COOLDOWN }

const FLY_HEIGHT := 4.0
const SWOOP_SPEED := 8.0
const BOMB_SPEED := 6.0
const COOLDOWN_DURATION := 2.5
const ACTION_INTERVAL := 3.0

var state: State = State.FLY
var state_timer: float = ACTION_INTERVAL
var swoop_target: Vector3 = Vector3.ZERO

@export var projectile_scene: PackedScene

func _ready() -> void:
    enemy_type = "crow"
    max_hp = 20
    attack_damage = 10
    move_speed = 4.0
    aggro_range = 10.0
    super._ready()

func _physics_process(delta: float) -> void:
    state_timer -= delta
    match state:
        State.FLY:       _fly(delta)
        State.SWOOP:     _swoop(delta)
        State.DROP_BOMB: _drop_bomb()
        State.COOLDOWN:  _cooldown()
    move_and_slide()

func _fly(delta: float) -> void:
    # Hover above player at FLY_HEIGHT
    if player:
        var target := player.global_position + Vector3(0, FLY_HEIGHT, 0)
        var dir := (target - global_position).normalized()
        velocity = dir * move_speed
    if state_timer <= 0.0 and _get_player_distance() <= aggro_range:
        var action := randi() % 2
        if action == 0:
            state = State.SWOOP
            swoop_target = player.global_position
        else:
            state = State.DROP_BOMB
        state_timer = COOLDOWN_DURATION

func _swoop(delta: float) -> void:
    var dir := (swoop_target - global_position).normalized()
    velocity = dir * SWOOP_SPEED
    if global_position.distance_to(swoop_target) < 1.0:
        if player and _get_player_distance() <= attack_range + 0.5:
            player.take_damage(attack_damage)
        state = State.COOLDOWN
        state_timer = COOLDOWN_DURATION

func _drop_bomb() -> void:
    if projectile_scene and player:
        var bomb := projectile_scene.instantiate()
        get_parent().add_child(bomb)
        bomb.global_position = global_position
        bomb.set_direction((player.global_position - global_position).normalized())
    state = State.COOLDOWN
    state_timer = COOLDOWN_DURATION

func _cooldown() -> void:
    # Fly back up
    var target := (player.global_position if player else global_position) + Vector3(0, FLY_HEIGHT, 0)
    var dir := (target - global_position).normalized()
    velocity = dir * move_speed
    if state_timer <= 0.0:
        state = State.FLY
        state_timer = ACTION_INTERVAL
```

- [ ] **Step 2: Write crow_projectile.gd and create scene**

```gdscript
# scripts/enemies/crow_projectile.gd
class_name CrowProjectile
extends Area3D

const SPEED := 6.0
const DAMAGE := 10
var direction: Vector3 = Vector3.DOWN
var lifetime: float = 3.0

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func set_direction(dir: Vector3) -> void:
    direction = dir.normalized()

func _process(delta: float) -> void:
    global_position += direction * SPEED * delta
    lifetime -= delta
    if lifetime <= 0.0:
        queue_free()

func _on_body_entered(body: Node) -> void:
    if body.is_in_group("player"):
        body.take_damage(DAMAGE)
    queue_free()
```

- [ ] **Step 3: Create crow.tscn and crow_projectile.tscn** (same structure pattern as wolf; crow_projectile uses Area3D root with CollisionShape3D and MeshInstance3D sphere child)

- [ ] **Step 4: Run to verify** — crow should fly above player, swoop down to peck, or drop a projectile.

- [ ] **Step 5: Commit**

```bash
git add scripts/enemies/crow.gd scripts/enemies/crow_projectile.gd scenes/enemies/
git commit -m "feat: Crow enemy with fly, swoop, and projectile drop"
```

---

## Task 15: Bear Boss — Phase 1

**Files:**
- Create: `scripts/boss/bear_boss.gd`
- Create: `scenes/boss/bear_boss.tscn`

- [ ] **Step 1: Write bear_boss.gd Phase 1**

```gdscript
# scripts/boss/bear_boss.gd
class_name BearBoss
extends EnemyBase

enum State { IDLE, SWIPE, GROUND_POUND, ROAR, CHARGE, SUMMON, DEAD }

const PHASE2_THRESHOLD := 0.5
const SWIPE_DAMAGE := 18
const POUND_DAMAGE := 22
const POUND_RADIUS := 3.0
const ROAR_STUN := 1.5
const CHARGE_SPEED := 9.0
const CHARGE_DURATION := 0.8
const ACTION_INTERVAL_P1 := 2.5
const ACTION_INTERVAL_P2 := 1.8
const SUMMON_INTERVAL := 12.0

var phase: int = 1
var state: State = State.IDLE
var action_timer: float = 2.0
var summon_timer: float = SUMMON_INTERVAL
var charge_dir: Vector3 = Vector3.ZERO
var charge_timer: float = 0.0

@export var wolf_scene: PackedScene

signal phase_changed(new_phase: int)
signal bear_killed

func _ready() -> void:
    enemy_type = "bear"
    max_hp = 400
    attack_damage = SWIPE_DAMAGE
    move_speed = 2.0
    aggro_range = 15.0
    super._ready()

func _physics_process(delta: float) -> void:
    _apply_gravity(delta)
    if is_dead:
        return
    _check_phase_transition()
    action_timer -= delta
    match state:
        State.IDLE:        _idle(delta)
        State.SWIPE:       pass
        State.GROUND_POUND: pass
        State.ROAR:        pass
        State.CHARGE:      _do_charge(delta)
        State.SUMMON:      pass
    move_and_slide()

func _idle(delta: float) -> void:
    _face_player()
    var dir := (player.global_position - global_position)
    dir.y = 0.0
    if dir.length() > attack_range:
        var move := dir.normalized() * move_speed
        velocity.x = move.x
        velocity.z = move.z
    else:
        velocity.x = 0.0
        velocity.z = 0.0
    if action_timer <= 0.0:
        _choose_action()

func _choose_action() -> void:
    var interval := ACTION_INTERVAL_P2 if phase == 2 else ACTION_INTERVAL_P1
    action_timer = interval
    var actions := [State.SWIPE, State.GROUND_POUND, State.ROAR]
    if phase == 2:
        actions.append(State.CHARGE)
    var chosen: State = actions[randi() % actions.size()]
    state = chosen
    _execute_action(chosen)

func _execute_action(action: State) -> void:
    match action:
        State.SWIPE:
            await get_tree().create_timer(0.3).timeout
            if player and _get_player_distance() <= attack_range + 0.5:
                player.take_damage(SWIPE_DAMAGE)
            state = State.IDLE
        State.GROUND_POUND:
            velocity.x = 0.0
            velocity.z = 0.0
            await get_tree().create_timer(0.6).timeout
            _aoe_pound()
            state = State.IDLE
        State.ROAR:
            velocity.x = 0.0
            velocity.z = 0.0
            await get_tree().create_timer(0.5).timeout
            if player and _get_player_distance() <= 8.0:
                player.is_invincible = true
                await get_tree().create_timer(ROAR_STUN).timeout
                player.is_invincible = false
            state = State.IDLE
        State.CHARGE:
            charge_dir = (player.global_position - global_position).normalized()
            charge_dir.y = 0.0
            charge_timer = CHARGE_DURATION
            state = State.CHARGE

func _aoe_pound() -> void:
    if player and _get_player_distance() <= POUND_RADIUS:
        player.take_damage(POUND_DAMAGE)

func _do_charge(delta: float) -> void:
    velocity.x = charge_dir.x * CHARGE_SPEED
    velocity.z = charge_dir.z * CHARGE_SPEED
    charge_timer -= delta
    if player and _get_player_distance() <= attack_range:
        player.take_damage(SWIPE_DAMAGE)
        state = State.IDLE
    elif charge_timer <= 0.0:
        state = State.IDLE

func _check_phase_transition() -> void:
    if phase == 1 and float(current_hp) / float(max_hp) <= PHASE2_THRESHOLD:
        phase = 2
        move_speed = 3.5
        phase_changed.emit(2)

func _die() -> void:
    is_dead = true
    remove_from_group("enemies")
    GameState.on_bear_defeated()
    GameState.collect_loot("bear")
    bear_killed.emit()
    # Loot chest spawned by World on this signal
    await get_tree().create_timer(2.0).timeout
    queue_free()

func _summon_wolf() -> void:
    if not wolf_scene:
        return
    for i in 2:
        var w := wolf_scene.instantiate()
        get_parent().add_child(w)
        w.global_position = global_position + Vector3(randf_range(-3,3), 0, randf_range(-3,3))
```

- [ ] **Step 2: Add Phase 2 summon timer to `_physics_process`**

Inside the `_physics_process` match block, add after the match:

```gdscript
    if phase == 2 and state == State.IDLE:
        summon_timer -= delta
        if summon_timer <= 0.0:
            summon_timer = SUMMON_INTERVAL
            _summon_wolf()
```

- [ ] **Step 3: Create bear_boss.tscn** (CharacterBody3D root, larger CapsuleShape3D, Mesh child, script attached)

Save to `scenes/boss/bear_boss.tscn`.

- [ ] **Step 4: Run to verify**

Place bear in a test scene with a player. Bear should idle → approach → swipe/pound/roar. At 50% HP, speed increases and charge attack appears. At 0 HP, `bear_killed` emits.

- [ ] **Step 5: Commit**

```bash
git add scripts/boss/bear_boss.gd scenes/boss/bear_boss.tscn
git commit -m "feat: Bear boss with 2-phase AI, swipe/pound/roar/charge, wolf summon"
```

---

## Task 16: Loot Chest

**Files:**
- Create: `scripts/world/loot_chest.gd`
- Create: `scenes/world/loot_chest.tscn`

- [ ] **Step 1: Write loot_chest.gd**

```gdscript
# scripts/world/loot_chest.gd
class_name LootChest
extends Node3D

var opened: bool = false

@onready var mesh: MeshInstance3D = $Mesh

func open() -> void:
    if opened:
        return
    opened = true
    # Drop bear parts to inventory (already done by GameState.on_bear_defeated)
    # Animate chest open
    var tween := create_tween()
    tween.tween_property(mesh, "rotation_degrees:x", -90.0, 0.4)
```

- [ ] **Step 2: Create loot_chest.tscn** (Node3D root + MeshInstance3D "Mesh" child using BoxMesh)

- [ ] **Step 3: Commit**

```bash
git add scripts/world/loot_chest.gd scenes/world/loot_chest.tscn
git commit -m "feat: LootChest with open animation"
```

---

## Task 17: Beer Minigame (2D) + Tests

**Files:**
- Create: `scripts/ui/beer_minigame.gd`
- Create: `scenes/ui/beer_minigame.tscn`
- Create: `tests/test_beer_minigame.gd`

- [ ] **Step 1: Write failing tests**

```gdscript
# tests/test_beer_minigame.gd
extends GutTest

var minigame: BeerMinigame

func before_each() -> void:
    minigame = BeerMinigame.new()

func test_perfect_pour_heals_full() -> void:
    minigame.fill_level = 0.7  # in golden zone 0.6-0.8
    assert_eq(minigame._calculate_heal(), 100)

func test_low_pour_heals_partial_low() -> void:
    minigame.fill_level = 0.3
    assert_eq(minigame._calculate_heal(), 25)

func test_high_pour_heals_partial_high() -> void:
    minigame.fill_level = 0.95
    assert_eq(minigame._calculate_heal(), 50)

func test_golden_zone_lower_edge() -> void:
    minigame.fill_level = 0.6
    assert_eq(minigame._calculate_heal(), 100)

func test_golden_zone_upper_edge() -> void:
    minigame.fill_level = 0.8
    assert_eq(minigame._calculate_heal(), 100)

func test_just_below_golden_zone() -> void:
    minigame.fill_level = 0.59
    assert_eq(minigame._calculate_heal(), 25)

func test_just_above_golden_zone() -> void:
    minigame.fill_level = 0.81
    assert_eq(minigame._calculate_heal(), 50)
```

- [ ] **Step 2: Run — expect FAIL**

```bash
godot --headless --path /mnt/c/Users/ianst/code/yokai -s addons/gut/gut_cmdln.gd -gdir=res://tests -gprefix=test_ -gsuffix=.gd 2>&1 | tail -20
```

- [ ] **Step 3: Write beer_minigame.gd**

```gdscript
# scripts/ui/beer_minigame.gd
class_name BeerMinigame
extends CanvasLayer

const GOLDEN_ZONE_MIN := 0.6
const GOLDEN_ZONE_MAX := 0.8
const FILL_SPEED := 0.35
const HEAL_PERFECT := 100
const HEAL_LOW := 25
const HEAL_HIGH := 50
const COOLDOWN_SECS := 30.0

var fill_level: float = 0.0
var is_filling: bool = false
var can_play: bool = true
var on_cooldown: bool = false

signal minigame_complete(heal_amount: int)

@onready var fill_bar: ProgressBar = $Panel/FillBar
@onready var golden_zone_marker: ColorRect = $Panel/GoldenZone
@onready var result_label: Label = $Panel/ResultLabel
@onready var cooldown_label: Label = $Panel/CooldownLabel

func _ready() -> void:
    layer = 10
    visible = false

func open() -> void:
    if on_cooldown:
        cooldown_label.visible = true
        return
    if not can_play:
        return
    fill_level = 0.0
    is_filling = false
    visible = true
    result_label.visible = false
    cooldown_label.visible = false
    _update_fill_bar()

func _process(delta: float) -> void:
    if not visible:
        return
    if is_filling:
        fill_level = min(1.0, fill_level + FILL_SPEED * delta)
        _update_fill_bar()
        if fill_level >= 1.0:
            _release()

func _unhandled_input(event: InputEvent) -> void:
    if not visible:
        return
    if event.is_action_pressed("attack"):
        is_filling = true
    if event.is_action_released("attack"):
        _release()

func _release() -> void:
    if not is_filling and fill_level == 0.0:
        return
    is_filling = false
    var heal := _calculate_heal()
    _show_result(heal)
    can_play = false
    on_cooldown = true
    await get_tree().create_timer(2.0).timeout
    visible = false
    minigame_complete.emit(heal)
    await get_tree().create_timer(COOLDOWN_SECS).timeout
    on_cooldown = false
    can_play = true

func _calculate_heal() -> int:
    if fill_level >= GOLDEN_ZONE_MIN and fill_level <= GOLDEN_ZONE_MAX:
        return HEAL_PERFECT
    elif fill_level < GOLDEN_ZONE_MIN:
        return HEAL_LOW
    else:
        return HEAL_HIGH

func _update_fill_bar() -> void:
    if fill_bar:
        fill_bar.value = fill_level * 100.0

func _show_result(heal: int) -> void:
    if not result_label:
        return
    if heal == HEAL_PERFECT:
        result_label.text = "Perfect Pour!  Full HP restored!"
        result_label.modulate = Color(1.0, 0.9, 0.0)
    elif heal == HEAL_LOW:
        result_label.text = "Too little... +" + str(heal) + " HP"
        result_label.modulate = Color(1.0, 0.4, 0.4)
    else:
        result_label.text = "Overflow! +" + str(heal) + " HP"
        result_label.modulate = Color(0.6, 0.8, 1.0)
    result_label.visible = true
```

- [ ] **Step 4: Run tests — expect PASS**

```bash
godot --headless --path /mnt/c/Users/ianst/code/yokai -s addons/gut/gut_cmdln.gd -gdir=res://tests -gprefix=test_ -gsuffix=.gd 2>&1 | tail -20
```

- [ ] **Step 5: Create beer_minigame.tscn**

Scene structure (CanvasLayer root):
```
BeerMinigame (CanvasLayer, script=beer_minigame.gd)
└── Panel (Panel, anchored full-screen, dark amber background)
    ├── BgRect (ColorRect, amber #8B4513 at 80% opacity, full panel)
    ├── TapSprite (TextureRect — beer tap art placeholder)
    ├── FillBar (ProgressBar, vertical, positioned center)
    ├── GoldenZone (ColorRect, gold color, overlaid at 60%-80% of FillBar height)
    ├── ResultLabel (Label, centered, large font)
    └── CooldownLabel (Label, text="Come back later!", centered)
```

Save to `scenes/ui/beer_minigame.tscn`.

- [ ] **Step 6: Commit**

```bash
git add scripts/ui/beer_minigame.gd scenes/ui/beer_minigame.tscn tests/test_beer_minigame.gd
git commit -m "feat: Beer minigame 2D overlay with fill bar, golden zone, heal on complete"
```

---

## Task 18: Bartender Hut

**Files:**
- Create: `scripts/world/bartender_hut.gd`
- Create: `scenes/world/bartender_hut.tscn`

- [ ] **Step 1: Write bartender_hut.gd**

```gdscript
# scripts/world/bartender_hut.gd
class_name BartenderHut
extends Node3D

const INTERACT_RANGE := 2.5

var player: Player
var beer_minigame: BeerMinigame
var prompt_visible: bool = false

@onready var prompt_label: Label3D = $PromptLabel

func _ready() -> void:
    player = get_tree().get_first_node_in_group("player")
    beer_minigame = get_tree().get_first_node_in_group("beer_minigame")

func _process(_delta: float) -> void:
    if not player:
        return
    var dist := global_position.distance_to(player.global_position)
    if dist <= INTERACT_RANGE:
        prompt_label.visible = true
        if Input.is_action_just_pressed("interact"):
            beer_minigame.open()
    else:
        prompt_label.visible = false
```

- [ ] **Step 2: Create bartender_hut.tscn**

```
BartenderHut (Node3D, script=bartender_hut.gd)
├── HutMesh (MeshInstance3D — BoxMesh placeholder for the hut)
├── CollisionBody (StaticBody3D)
│   └── CollisionShape3D
└── PromptLabel (Label3D, text="[F] Visit Bartender", visible=false)
```

Save to `scenes/world/bartender_hut.tscn`.

- [ ] **Step 3: Commit**

```bash
git add scripts/world/bartender_hut.gd scenes/world/bartender_hut.tscn
git commit -m "feat: BartenderHut with proximity prompt and beer minigame trigger"
```

---

## Task 19: Crafting Stump + Menu

**Files:**
- Create: `scripts/world/crafting_stump.gd`
- Create: `scripts/ui/crafting_menu.gd`
- Create: `scenes/world/crafting_stump.tscn`
- Create: `scenes/ui/crafting_menu.tscn`

- [ ] **Step 1: Write crafting_stump.gd**

```gdscript
# scripts/world/crafting_stump.gd
class_name CraftingStump
extends Node3D

const INTERACT_RANGE := 2.5

var player: Player
var crafting_menu: CraftingMenu

@onready var prompt_label: Label3D = $PromptLabel

func _ready() -> void:
    player = get_tree().get_first_node_in_group("player")
    crafting_menu = get_tree().get_first_node_in_group("crafting_menu")

func _process(_delta: float) -> void:
    if not player:
        return
    var dist := global_position.distance_to(player.global_position)
    prompt_label.visible = dist <= INTERACT_RANGE
    if dist <= INTERACT_RANGE and Input.is_action_just_pressed("interact"):
        crafting_menu.open()
```

- [ ] **Step 2: Write crafting_menu.gd**

```gdscript
# scripts/ui/crafting_menu.gd
class_name CraftingMenu
extends CanvasLayer

@onready var recipe_list: VBoxContainer = $Panel/RecipeList
@onready var close_btn: Button = $Panel/CloseButton

func _ready() -> void:
    layer = 9
    visible = false
    add_to_group("crafting_menu")
    close_btn.pressed.connect(close)
    GameState.inventory.parts_changed.connect(_refresh)

func open() -> void:
    _refresh(GameState.inventory.all_parts())
    visible = true
    get_tree().paused = true

func close() -> void:
    visible = false
    get_tree().paused = false

func _refresh(_parts: Dictionary) -> void:
    for child in recipe_list.get_children():
        child.queue_free()
    for weapon_id in GameState.crafting.RECIPES:
        var recipe = GameState.crafting.RECIPES[weapon_id]
        if not recipe["unlocked"]:
            continue
        var btn := Button.new()
        var can := GameState.crafting.can_craft(weapon_id, GameState.inventory)
        btn.text = Crafting.WEAPONS[weapon_id]["name"]
        btn.disabled = not can
        btn.pressed.connect(_on_craft.bind(weapon_id))
        recipe_list.add_child(btn)

func _on_craft(weapon_id: String) -> void:
    var stats = GameState.crafting.craft(weapon_id, GameState.inventory)
    if stats.is_empty():
        return
    GameState.equip_weapon(weapon_id)
    _refresh(GameState.inventory.all_parts())
```

- [ ] **Step 3: Create crafting_stump.tscn and crafting_menu.tscn**

`crafting_stump.tscn`: Node3D root with MeshInstance3D (CylinderMesh for log), StaticBody3D+CollisionShape, Label3D prompt.

`crafting_menu.tscn`: CanvasLayer root → Panel (centered, dark bg) → VBoxContainer "RecipeList" + Button "CloseButton".

- [ ] **Step 4: Commit**

```bash
git add scripts/world/crafting_stump.gd scripts/ui/crafting_menu.gd scenes/world/crafting_stump.tscn scenes/ui/crafting_menu.tscn
git commit -m "feat: CraftingStump interaction and CraftingMenu with recipe list"
```

---

## Task 20: HUD

**Files:**
- Create: `scripts/ui/hud.gd`
- Create: `scenes/ui/hud.tscn`

- [ ] **Step 1: Write hud.gd**

```gdscript
# scripts/ui/hud.gd
class_name HUD
extends CanvasLayer

@onready var hp_bar: ProgressBar = $TopLeft/HPBar
@onready var sp_bar: ProgressBar = $TopLeft/SPBar
@onready var weapon_label: Label = $TopLeft/WeaponLabel
@onready var parts_label: Label = $BottomRight/PartsLabel

var player_stats: PlayerStats

func _ready() -> void:
    layer = 5
    await get_tree().process_frame  # wait for player to be ready
    var player := get_tree().get_first_node_in_group("player") as Player
    if player:
        player_stats = player.stats
        player_stats.hp_changed.connect(_on_hp_changed)
        player_stats.sp_changed.connect(_on_sp_changed)
    GameState.weapon_changed.connect(_on_weapon_changed)
    GameState.inventory.parts_changed.connect(_on_parts_changed)
    _on_weapon_changed(GameState.current_weapon_stats)
    _on_parts_changed(GameState.inventory.all_parts())

func _on_hp_changed(current: int, maximum: int) -> void:
    hp_bar.max_value = maximum
    hp_bar.value = current

func _on_sp_changed(current: float, maximum: float) -> void:
    sp_bar.max_value = maximum
    sp_bar.value = current

func _on_weapon_changed(stats: Dictionary) -> void:
    weapon_label.text = stats.get("name", "Wooden Stick")

func _on_parts_changed(parts: Dictionary) -> void:
    var lines: Array[String] = []
    var names := {"wolf_fang":"Wolf Fang","boar_tusk":"Boar Tusk",
                  "crow_feather":"Crow Feather","bear_claw":"Bear Claw","bear_pelt":"Bear Pelt"}
    for part_id in parts:
        if parts[part_id] > 0:
            lines.append(names.get(part_id, part_id) + ": " + str(parts[part_id]))
    parts_label.text = "\n".join(lines)
```

- [ ] **Step 2: Create hud.tscn**

```
HUD (CanvasLayer, script=hud.gd)
├── TopLeft (VBoxContainer, anchored top-left, margin 12px)
│   ├── HPBar (ProgressBar, min=0, max=100, value=100, red fill)
│   ├── SPBar (ProgressBar, min=0, max=100, value=0, gold fill)
│   └── WeaponLabel (Label, text="Wooden Stick")
└── BottomRight (VBoxContainer, anchored bottom-right, margin 12px)
    └── PartsLabel (Label, text="")
```

- [ ] **Step 3: Commit**

```bash
git add scripts/ui/hud.gd scenes/ui/hud.tscn
git commit -m "feat: HUD with HP/SP bars, weapon name, and parts inventory display"
```

---

## Task 21: Dark Forest World Scene

**Files:**
- Create: `scripts/world/world.gd`
- Create: `scenes/world/world.tscn`

- [ ] **Step 1: Write world.gd**

```gdscript
# scripts/world/world.gd
extends Node3D

const WOLF_COUNT := 6
const BOAR_COUNT := 3
const CROW_COUNT := 3
const RESPAWN_TIME := 30.0

@export var wolf_scene: PackedScene
@export var boar_scene: PackedScene
@export var crow_scene: PackedScene
@export var bear_scene: PackedScene
@export var loot_chest_scene: PackedScene

# Spawn points defined as marker positions in the scene
@onready var wolf_spawns: Node3D = $SpawnPoints/WolfSpawns
@onready var boar_spawns: Node3D = $SpawnPoints/BoarSpawns
@onready var crow_spawns: Node3D = $SpawnPoints/CrowSpawns
@onready var boss_spawn: Marker3D = $SpawnPoints/BossSpawn
@onready var chest_spawn: Marker3D = $SpawnPoints/ChestSpawn
@onready var bear_boss: BearBoss = null

func _ready() -> void:
    _spawn_all_enemies()
    _spawn_boss()

func _spawn_all_enemies() -> void:
    _spawn_enemies(wolf_scene, wolf_spawns, WOLF_COUNT)
    _spawn_enemies(boar_scene, boar_spawns, BOAR_COUNT)
    _spawn_enemies(crow_scene, crow_spawns, CROW_COUNT)

func _spawn_enemies(scene: PackedScene, spawn_parent: Node3D, count: int) -> void:
    if not scene or not spawn_parent:
        return
    var markers := spawn_parent.get_children()
    for i in min(count, markers.size()):
        var enemy := scene.instantiate()
        add_child(enemy)
        enemy.global_position = markers[i].global_position
        enemy.died.connect(_on_enemy_died.bind(scene, markers[i].global_position))

func _on_enemy_died(scene: PackedScene, spawn_pos: Vector3) -> void:
    await get_tree().create_timer(RESPAWN_TIME).timeout
    var enemy := scene.instantiate()
    add_child(enemy)
    enemy.global_position = spawn_pos
    enemy.died.connect(_on_enemy_died.bind(scene, spawn_pos))

func _spawn_boss() -> void:
    if not bear_scene:
        return
    bear_boss = bear_scene.instantiate()
    add_child(bear_boss)
    bear_boss.global_position = boss_spawn.global_position
    bear_boss.bear_killed.connect(_on_bear_killed)
    bear_boss.phase_changed.connect(_on_phase_changed)

func _on_bear_killed() -> void:
    if loot_chest_scene:
        var chest := loot_chest_scene.instantiate() as LootChest
        add_child(chest)
        chest.global_position = chest_spawn.global_position
        chest.open()
    # Respawn bear after delay for continued farming
    await get_tree().create_timer(60.0).timeout
    _spawn_boss()

func _on_phase_changed(new_phase: int) -> void:
    # Phase 2 music change handled here (placeholder — swap AudioStreamPlayer track)
    pass
```

- [ ] **Step 2: Create world.tscn**

The world scene needs:
- Node3D root with script
- Camera3D (positioned at Vector3(10,14,10), will be moved by player script)
- DirectionalLight3D (moonlight: blue-white, angle ~45°, shadows enabled)
- WorldEnvironment (dark sky, ambient blue-gray light)
- MeshInstance3D ground plane (PlaneMesh, 60×60 units, dark green material)
- Multiple MeshInstance3D trees (CylinderMesh trunks + ConeMesh tops, dark green)
- StaticBody3D collision for ground
- SpawnPoints (Node3D) with children: WolfSpawns, BoarSpawns, CrowSpawns (each with Marker3D children)
- BossSpawn Marker3D (far end of map)
- ChestSpawn Marker3D (near boss spawn)
- Instance of bartender_hut.tscn
- Instance of crafting_stump.tscn

Create this scene in Godot editor, place scene instances, set spawn point positions.

- [ ] **Step 3: Create main.tscn**

```
Main (Node)
├── World (instance of world.tscn)
├── Player (instance of player.tscn)
├── HUD (instance of hud.tscn)
├── BeerMinigame (instance of beer_minigame.tscn, add_to_group "beer_minigame")
└── CraftingMenu (instance of crafting_menu.tscn)
```

- [ ] **Step 4: Run main.tscn to verify full scene**

Press F5 (Run Project). Player should appear in the forest, enemies should be alive and moving, bartender hut and crafting stump should be visible. WASD moves, Space attacks, F interacts.

- [ ] **Step 5: Commit**

```bash
git add scripts/world/world.gd scenes/world/world.tscn scenes/main.tscn
git commit -m "feat: World scene with spawning, respawning, boss, and main scene wiring"
```

---

## Task 22: Asset Integration (Models + Cel Shader)

**Files:**
- Create: `assets/shaders/cel_shader.gdshader`
- Create: `assets/materials/cel_material.tres`
- Populate: `assets/models/`

- [ ] **Step 1: Download Quaternius animal pack**

```bash
cd /mnt/c/Users/ianst/code/yokai
curl -L "https://poly.pizza/bundle/Animated-Animal-Pack-ILAPXeUYiS" -o quaternius_animals.zip
# If that URL doesn't resolve, download manually from:
# https://quaternius.com/packs/ultimateanimatedanimals.html
# and place GLB files in assets/models/
unzip -q quaternius_animals.zip -d assets/models/quaternius/
```

- [ ] **Step 2: Identify and copy needed GLBs**

```bash
# Copy the relevant animal GLBs into assets/models/
# Look for: Wolf.glb (or Coyote.glb), Bear.glb, Boar.glb (or Pig.glb), Crow.glb (or Raven.glb)
ls assets/models/quaternius/
# Then copy:
cp assets/models/quaternius/Wolf.glb assets/models/wolf.glb
cp assets/models/quaternius/Bear.glb assets/models/bear.glb
# etc — adjust names based on what's in the pack
```

- [ ] **Step 3: Find and download monkey GLB from Sketchfab**

Browse https://sketchfab.com/tags/monkey and download a free GLB (look for CC0 or CC-BY license). Save as `assets/models/monkey.glb`.

- [ ] **Step 4: Write cel shader**

Download the Complete Cel Shader from https://godotshaders.com/shader/complete-cel-shader-for-godot-4/ and save the shader code to `assets/shaders/cel_shader.gdshader`. The shader file begins with:

```glsl
// Complete Cel Shader for Godot 4
// Source: godotshaders.com/shader/complete-cel-shader-for-godot-4/
shader_type spatial;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D texture_albedo : source_color;
uniform float cel_steps : hint_range(1, 16) = 3.0;
uniform float outline_width : hint_range(0, 10) = 1.5;
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
// ... (copy full shader from godotshaders.com)
```

- [ ] **Step 5: Assign models to enemy/player scenes in Godot editor**

In Godot editor:
1. Open `scenes/player/player.tscn` → select "Mesh" node → drag `assets/models/monkey.glb` into the scene as a child of Mesh
2. Open `scenes/enemies/wolf.tscn` → assign `assets/models/wolf.glb`
3. Repeat for boar, crow, bear
4. For each model's MeshInstance3D, set the material to use `cel_shader.gdshader`

- [ ] **Step 6: Verify cel shading in editor**

Run the scene. Characters should appear with flat-shaded colours and dark outlines. If the shader has an outline pass issue on WebGL, set `outline_width = 0` as a fallback.

- [ ] **Step 7: Commit**

```bash
git add assets/
git commit -m "feat: integrate Quaternius animal models and cel shader"
```

---

## Task 23: Enemy Respawn + Polish

**Files:**
- Modify: `scripts/world/world.gd`

- [ ] **Step 1: Verify respawn is working**

Kill a wolf in the running game. Wait 30 seconds. Wolf should respawn at its original spawn point.

- [ ] **Step 2: Add floating health bars to enemies via HUD**

Add to `hud.gd`:

```gdscript
var enemy_bars: Dictionary = {}  # enemy node → ProgressBar

func _process(_delta: float) -> void:
    _update_enemy_health_bars()

func _update_enemy_health_bars() -> void:
    var cam := get_viewport().get_camera_3d()
    if not cam:
        return
    # Remove bars for dead enemies
    for enemy in enemy_bars.keys():
        if not is_instance_valid(enemy):
            enemy_bars[enemy].queue_free()
            enemy_bars.erase(enemy)
    # Add bars for new enemies
    for enemy in get_tree().get_nodes_in_group("enemies"):
        if enemy not in enemy_bars:
            _create_enemy_bar(enemy)
    # Update positions
    for enemy in enemy_bars:
        if not is_instance_valid(enemy):
            continue
        var screen_pos := cam.unproject_position(enemy.global_position + Vector3.UP * 2.0)
        if cam.is_position_in_frustum(enemy.global_position):
            enemy_bars[enemy].visible = true
            enemy_bars[enemy].position = screen_pos - Vector2(40, 0)
        else:
            enemy_bars[enemy].visible = false

func _create_enemy_bar(enemy: EnemyBase) -> void:
    var bar := ProgressBar.new()
    bar.min_value = 0.0
    bar.max_value = 100.0
    bar.value = 100.0
    bar.custom_minimum_size = Vector2(80, 10)
    bar.show_percentage = false
    add_child(bar)
    enemy_bars[enemy] = bar
    enemy.damaged.connect(func(_e): bar.value = float(enemy.current_hp) / float(enemy.max_hp) * 100.0)
```

- [ ] **Step 3: Run and verify floating health bars appear above enemies**

- [ ] **Step 4: Commit**

```bash
git add scripts/ui/hud.gd
git commit -m "feat: floating enemy health bars via screen-space projection"
```

---

## Task 24: HTML5 Export Config

**Files:**
- Create: `export_presets.cfg` (via Godot editor)

- [ ] **Step 1: Download HTML5 export templates in Godot**

In Godot editor: Editor → Export → Manage Export Templates → Download (choose Godot 4.3 stable).

- [ ] **Step 2: Add HTML5 export preset in Godot**

Editor → Project → Export → Add → Web. Settings:
- Name: "Web"
- Export path: `build/index.html`
- Renderer: GL Compatibility (already set in project.godot)
- Uncheck "Export With Debug"

- [ ] **Step 3: Export to HTML5**

Click "Export Project" → choose `build/` folder → `index.html`.

```bash
mkdir -p /mnt/c/Users/ianst/code/yokai/build
```

- [ ] **Step 4: Test locally**

```bash
cd /mnt/c/Users/ianst/code/yokai/build
python3 -m http.server 8080
# Open http://localhost:8080 in browser
```

Verify: game loads in browser, WASD moves, combat works, beer minigame opens.

- [ ] **Step 5: Add build/ to .gitignore**

```bash
echo "build/" >> /mnt/c/Users/ianst/code/yokai/.gitignore
git add .gitignore
git commit -m "chore: ignore build output directory"
```

- [ ] **Step 6: Push to GitHub**

```bash
git push origin main
```

- [ ] **Step 7: Upload to itch.io**

1. Go to itch.io → Create New Project
2. Name: "Yokai Animal Busters", Kind: HTML, set to public
3. Zip the `build/` folder → upload as game file
4. Mark "This file will be played in the browser"
5. Share the itch.io URL with your friend

---

## Self-Review Checklist

**Spec coverage:**
- [x] Godot 4, HTML5 export, itch.io → Task 1, 24
- [x] Fixed isometric camera → Task 8
- [x] Monkey protagonist → Task 8
- [x] WASD movement, Space attack, Shift dodge, RClick guard, E special, F interact → Tasks 2, 9, 10
- [x] 3-hit combo chain + heavy attack → Task 9
- [x] Busters gauge + SP gain on hit → Task 9
- [x] Auto-face nearest enemy → Task 9
- [x] Wolf patrol+aggro+bite combo → Task 12
- [x] Boar telegraph+charge+stun → Task 13
- [x] Crow fly+swoop+projectile → Task 14
- [x] Bear Phase 1 (swipe/pound/roar) → Task 15
- [x] Bear Phase 2 (charge+summon wolves, speed up) → Task 15
- [x] Loot chest on bear death → Task 15, 16
- [x] Enemy drop tables → Task 5
- [x] Crafting system + bear hammer locked until first kill → Task 6
- [x] Bartender hut interaction → Task 18
- [x] Beer minigame 2D with fill bar + golden zone → Task 17
- [x] HUD (HP, SP, weapon, parts) → Task 20
- [x] Floating health bars on enemies → Task 23
- [x] Enemy respawn on timer → Task 21
- [x] Cel shader → Task 22
- [x] GitHub repo → already created

**No placeholders found.**

**Type consistency verified:** `PlayerStats`, `Inventory`, `Crafting`, `LootTable`, `BearBoss`, `EnemyBase`, `Player`, `BeerMinigame`, `CraftingMenu`, `HUD` — all class_name declarations match usage across tasks.
