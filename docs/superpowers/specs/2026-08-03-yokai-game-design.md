# Yokai Watch Busters 2 — Animal Edition: Game Design Spec
**Date:** 2026-08-03

---

## Overview

A 3D action game directly based on Yokai Watch Busters 2, reskinned with animal characters. The player controls a monkey protagonist through a single dark forest area, fighting animal enemies, defeating a multi-phase boss, collecting loot parts, crafting better weapons, and healing via a unique 2D beer minigame at a bartender monkey's hut.

Built in **Godot 4**, exported to **HTML5**, hosted on **itch.io** with a **GitHub** repository. Friends can play directly in the browser with no download required.

---

## Protagonist

A monkey with a medium-length layered fringe / curtain-bangs / tousled messy-parted hairstyle. Stats: HP, Attack, Defense, Speed. Progression comes entirely from crafted weapons — no leveling up, faithful to YWB2.

---

## Architecture & Scene Structure

```
Main
├── World            — dark forest 3D environment (trees, ground, lighting, moonlight)
├── Player           — monkey character (collision, animation state machine, stats)
├── Enemies          — wolves, boars, crows (each own scene, spawned into World)
├── Boss             — giant bear (own scene, spawned in boss clearing)
├── BartenderHut     — small shack in forest, press F to trigger beer minigame
├── CraftingStump    — mossy log, press F to open crafting menu
├── HUD              — HP bar, Busters gauge, weapon icon, parts count (always visible)
├── BeerMinigame     — 2D fullscreen overlay scene, hides World while active
└── CraftingMenu     — 2D overlay, opens over World
```

**Camera:** Fixed isometric (45° angle), smoothly follows the player. Never rotates. One continuous forest map — no loading screens.

---

## Controls (keyboard + mouse, web)

| Input | Action |
|---|---|
| `WASD` | Move (free 360°) |
| `Space` / `Left Click` | Attack (tap for combo chain, hold for charged heavy) |
| `Shift` | Dodge roll (brief invincibility frames) |
| `Right Click` | Guard (reduces frontal damage) |
| `E` | Busters Move (special, empties SP gauge) |
| `F` | Interact (bartender hut / crafting stump) |

---

## Combat System (true to YWB2)

### Movement
Free 360° movement around the forest. Player auto-faces nearest enemy when attacking.

### Attack Chain
- Tap `Space` repeatedly → 3-hit melee combo chain (resets on pause)
- Hold `Space` → charged heavy attack, slower, knocks enemies back

### Busters Gauge (SP Bar)
Fills by landing hits. When full, press `E` for the monkey's Busters Move — a powerful area slam that hits all nearby enemies and empties the gauge.

### Guard & Dodge
- `Right Click` — guard stance, reduces damage from frontal hits
- `Shift` — dodge roll in current movement direction, i-frames during roll

### Healing
No mid-combat items. Player must disengage, run to the bartender monkey's hut, and complete the beer minigame. Intentional risk/reward decision — faithful to YWB2's resource management.

---

## Enemies

All enemies have floating health bars visible at all times. They respawn on a timer so the forest stays active.

| Enemy | Behaviour |
|---|---|
| **Wolf** | Fast, patrols in packs of 2–3. Rushes player on aggro, performs quick bite combos. Low HP, high speed. |
| **Boar** | Medium HP. Telegraphs a charge with a grunt animation, then lunges in a straight line. Briefly stunned if it misses — punish window. |
| **Crow** | Flies above melee range. Periodically swoops to peck or drops projectiles. Must be knocked out of the air with a timed hit. |

---

## Boss — Giant Bear

Located in a moonlit clearing at the far end of the forest. Significantly larger than the player.

### Phase 1 (100%–50% HP)
- Slow heavy swipes
- Ground pound → shockwave AoE
- Roar → briefly stuns player
- All moves clearly telegraphed via animation

### Phase 2 (50%–0% HP)
- All Phase 1 moves, increased speed
- Adds a long-range charge (like boar, much larger impact)
- Periodically summons wolves to assist
- Music intensifies

Defeating the bear triggers a victory animation and spawns a loot chest.

---

## Loot & Crafting Loop

### Enemy Drops (random on kill)
| Enemy | Drop |
|---|---|
| Wolf | Wolf Fang (common) |
| Boar | Boar Tusk (common) |
| Crow | Crow Feather (common) |

### Boss Drops (guaranteed from chest)
| Boss | Drops |
|---|---|
| Giant Bear | Bear Claw, Bear Pelt (rare) |

### Weapons (crafted at the Crafting Stump)
| Weapon | Parts Required | Stat Boost |
|---|---|---|
| Wooden Stick | Default (no crafting needed) | Baseline |
| Bone Club | 3× Wolf Fang | +Attack |
| Tusk Blade | 3× Boar Tusk + 1× Wolf Fang | +Attack, +Speed |
| Bear Claw Hammer | 2× Bear Claw + 1× Bear Pelt | ++ Attack, +Defense |
| Feather Blade | 5× Crow Feather + 1× Boar Tusk | +Speed, +Attack |

Bear Claw Hammer (strongest weapon) only becomes craftable after the bear is defeated at least once. Loop: clear enemies → farm scraps → craft → re-fight bear → rare parts → stronger weapon → repeat.

---

## Beer Minigame (original, 2D)

Triggered by pressing `F` at the bartender monkey's hut. World pauses, screen transitions to a flat **2D scene** — illustrated bar interior with the bartender monkey behind the counter.

**Mechanic:**
- A beer tap and a fill bar appear on screen
- Player holds `Space` — bar rises
- Release at the golden zone = perfect pour → full HP restored
- Too low or too high = bad pour → partial HP restored
- One attempt per visit, then a cooldown timer before returning

**Visual style:** Warm 2D illustration — wood panels, amber lighting, cosy. Deliberately different feel from the 3D forest world to make healing feel like a real break.

---

## HUD

| Element | Position | Notes |
|---|---|---|
| HP bar | Top-left | Red bar with monkey face icon |
| Busters gauge (SP) | Top-left below HP | Orange/gold fill bar |
| Weapon icon + name | Top-left below SP | Current equipped weapon |
| Parts inventory | Bottom-right | Count of each part held |

Minimal, always visible. Matches YWB2's clean HUD style.

---

## Technical Stack

| Layer | Choice |
|---|---|
| Engine | Godot 4 |
| Language | GDScript |
| 3D characters | Quaternius Animated Animal Pack (CC0) + free monkey GLB from Sketchfab |
| Cell shader | Complete Cel Shader for Godot 4 (godotshaders.com) |
| Export target | HTML5 (WebAssembly) |
| Hosting | itch.io |
| Version control | GitHub |

`.superpowers/` added to `.gitignore`.
