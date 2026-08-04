# 3D Models

Place GLB model files here before opening the project in Godot.

## Required files

| File | Source | License |
|------|--------|---------|
| `wolf.glb` | Quaternius Animated Animal Pack — Wolf or Coyote | CC0 |
| `boar.glb` | Quaternius Animated Animal Pack — Boar or Pig | CC0 |
| `crow.glb` | Quaternius Animated Animal Pack — Crow or Raven | CC0 |
| `bear.glb` | Quaternius Animated Animal Pack — Bear | CC0 |
| `monkey.glb` | Sketchfab — search "monkey" filter CC0/CC-BY | CC0/CC-BY |

## Download steps

1. **Quaternius animals** — https://quaternius.com/packs/ultimateanimatedanimals.html
   - Download the pack, unzip, locate GLBs for the animals above
   - Copy/rename them into this folder

2. **Monkey** — https://sketchfab.com/tags/monkey
   - Filter by "Downloadable" + free
   - Download GLB, save as `monkey.glb`

## Assigning models in Godot editor

After placing files here, open each scene and drag the GLB onto the Mesh node:

- `scenes/player/player.tscn` → Mesh → drag `monkey.glb`
- `scenes/enemies/wolf.tscn` → Mesh → drag `wolf.glb`
- `scenes/enemies/boar.tscn` → Mesh → drag `boar.glb`
- `scenes/enemies/crow.tscn` → Mesh → drag `crow.glb`
- `scenes/boss/bear_boss.tscn` → Mesh → drag `bear.glb`

Apply `res://assets/materials/cel_material.tres` as the surface material on each MeshInstance3D.
