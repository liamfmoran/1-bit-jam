# Machines — Technical Structure

## Folder Structure

```
res://
├── project.godot
├── icon.svg
├── .editorconfig
├── .gitignore
├── .gitattributes
│
├── .claude/
│   └── AGENTS.md                          # Agent instructions for this project
│
├── docs/
│   ├── design.md                          # Game design document
│   └── structure.md                       # This file
│
├── autoload/
│   └── game_state.gd                      # Singleton: game mode, money, cargo, parts, mass
│
├── scenes/
│   ├── main.tscn                          # Root scene: world + UI layers + post-process
│   ├── main.gd                            # State machine dispatch, pause control
│   │
│   ├── ship/
│   │   ├── truck_cab.gd                   # RigidBody2D: player cab, thrusters, camera
│   │   ├── trailer.gd                     # RigidBody2D: towable trailer, stabilization
│   │   └── ship_part_slot.gd              # Node2D: attachment point for upgradeable parts
│   │
│   ├── world/
│   │   ├── asteroid.gd                    # RigidBody2D: destructible, breaks on impact
│   │   ├── asteroid_spawner.gd            # Node2D: timer-driven ring spawner
│   │   ├── salvage.gd                     # Area2D: drifting cargo pickup
│   │   ├── station.gd                     # StaticBody2D: dockable trading station
│   │   └── enemy_ship.gd                  # RigidBody2D: hostile NPC
│   │
│   ├── ui/
│   │   ├── hud.gd                         # Control: flight-mode HUD
│   │   ├── cargo_screen.gd                # Control: cargo management overlay
│   │   ├── cargo_grid.gd                  # Control: reusable Tetris-like inventory grid
│   │   ├── cargo_item_ghost.gd            # Control: dragged item preview
│   │   ├── customize_screen.gd            # Control: ship customization overlay
│   │   └── pause_menu.gd                  # Control: pause overlay
│   │
│   └── effects/
│       ├── starfield.gd                   # ColorRect: feeds data to starfield shader
│       └── onebit_post.gd                 # ColorRect: applies 1-bit post-process shader
│
├── resources/
│   ├── packages/
│   │   └── package_data.gd                # PackageData Resource: grid_shape, mass, value, radiation
│   ├── parts/
│   │   └── ship_part_data.gd              # ShipPartData Resource: slot_type, stats, mass, cost
│   └── stations/
│       └── station_data.gd                # StationData Resource: name, inventories, price mods
│
├── shaders/
│   ├── onebit.gdshader                    # 1-bit post-process (Bayer dither, 2-color output)
│   ├── starfield.gdshader                 # Parallax star layers
│   └── radiation_overlay.gdshader         # Pulsing glow for irradiated items
│
└── assets/
    ├── textures/
    │   ├── packages/                          # Package shape sprites (white on transparent)
    │   └── parts/                          # Part icons for customize screen
    ├── fonts/                              # Pixel font for UI
    └── audio/                              # SFX
```

## Runtime Scene Tree (Flight Mode)

```
Main (Node2D)
├── StarfieldLayer (CanvasLayer, layer=-2)
│   └── StarfieldRect (ColorRect, shader: starfield.gdshader)
├── World (Node2D)
│   ├── TruckCab (RigidBody2D)
│   │   ├── TruckBody (ColorRect)
│   │   ├── CollisionShape2D
│   │   ├── Flames/ (ColorRect children)
│   │   ├── SlotThruster (ShipPartSlot)
│   │   ├── SlotWeaponFront (ShipPartSlot)
│   │   ├── SlotShield (ShipPartSlot)
│   │   └── SlotUtility (ShipPartSlot)
│   ├── Trailer_1 (RigidBody2D, instantiated)
│   ├── TrailerJoint_1 (PinJoint2D, created in code)
│   ├── AsteroidSpawner (Node2D)
│   │   └── [spawned asteroids...]
│   ├── StationAlpha (StaticBody2D)
│   └── StationBeta (StaticBody2D)
├── UILayer (CanvasLayer, layer=1)
│   ├── HUD (Control, visible during flight)
│   ├── CargoScreen (Control, visible when docked, process_mode=ALWAYS)
│   ├── CustomizeScreen (Control, visible when customizing, process_mode=ALWAYS)
│   └── PauseMenu (Control, process_mode=ALWAYS)
└── PostProcessLayer (CanvasLayer, layer=10)
    └── OneBitRect (ColorRect, shader: onebit.gdshader)
```

## Game State Machine

```
                    ┌─────────────────────────┐
                    │         FLIGHT           │
                    │  (tree running, HUD on)  │
                    └────┬──────────────┬──────┘
                         │              │
              dock + E   │              │  C at station
                         ▼              ▼
                    ┌──────────┐  ┌──────────────┐
                    │  CARGO   │──│  CUSTOMIZE   │
                    │ (paused) │  │   (paused)   │
                    └──────────┘  └──────────────┘
                         │              │
                    Esc  │         Esc  │
                         ▼              ▼
                    ┌─────────────────────────┐
                    │         FLIGHT           │
                    └─────────────────────────┘
```

Transitions go through `GameState.set_mode()` → emits `mode_changed(old, new)` → `main.gd` toggles tree pause and UI visibility.

## Collision Layers

| Bit | Name | Used By |
|-----|------|---------|
| 1 | Player | truck_cab, trailers |
| 2 | Stations | station dock Area2D |
| 3 | Asteroids | asteroids, debris fragments |
| 4 | Enemies | enemy ships, enemy projectiles |
| 5 | Salvage | salvageable pickups |
| 6 | PlayerBullets | player weapon projectiles |

**Masks** (what each layer detects):
- Player → Stations, Asteroids, Enemies, Salvage
- Asteroids → Player, Enemies, Asteroids
- Enemies → Player, Asteroids, PlayerBullets
- Salvage → Player
- PlayerBullets → Enemies, Asteroids

## Signal Flow

```
station.docked(station_data)    → main.gd → GameState.set_mode(CARGO)
station.undocked()              → main.gd → GameState.set_mode(FLIGHT)
GameState.mode_changed(old,new) → main.gd → show/hide UI, pause/unpause
GameState.cargo_changed()       → truck_cab.gd → recalculate mass
GameState.cargo_changed()       → hud.gd → update cargo weight display
GameState.money_changed(amount) → hud.gd → update money display
cargo_grid.item_placed(item,..) → cargo_screen.gd → write to GameState
cargo_grid.item_removed(item)   → cargo_screen.gd → write to GameState
```

## Design Patterns Applied

| Pattern | Application | Reference |
|---------|-------------|-----------|
| **State** | `GameState.GameMode` enum with `set_mode()` and `mode_changed` signal | [gameprogrammingpatterns.com/state.html](https://gameprogrammingpatterns.com/state.html) |
| **Component** | `ShipPartSlot` nodes as composable children of vehicle scenes | [gameprogrammingpatterns.com/component.html](https://gameprogrammingpatterns.com/component.html) |
| **Type Object** | `PackageData`, `ShipPartData`, `StationData` as Godot Resources | [gameprogrammingpatterns.com/type-object.html](https://gameprogrammingpatterns.com/type-object.html) |
| **Observer** | Godot signals (`mode_changed`, `cargo_changed`, `money_changed`) | [gameprogrammingpatterns.com/observer.html](https://gameprogrammingpatterns.com/observer.html) |
| **Data-driven** | All game content defined as `.tres` files, no hardcoded item/part/station data | — |

## Pre-built vs. Dynamic Instantiation

### Pre-built in editor (placed in .tscn files)

| What | Where | Why |
|------|-------|-----|
| TruckCab | child of main.tscn World | Always exists, only one |
| Starfield | CanvasLayer child of main.tscn | Background, always visible |
| 1-bit post-process | top CanvasLayer child of main.tscn | Always active |
| HUD, CargoScreen, CustomizeScreen | UI CanvasLayer children | Always present, toggled |
| AsteroidSpawner | child of main.tscn World | Always running in flight |
| Stations (2–3) | children of main.tscn World | Hand-placed for jam scope |
| ShipPartSlot nodes | children of truck_cab and trailer scenes | Fixed attachment points |

### Dynamically instantiated at runtime

| What | Spawned by | Why |
|------|-----------|-----|
| Trailers | truck_cab.gd `_spawn_trailers()` | Count varies |
| PinJoint2D | truck_cab.gd `_spawn_trailers()` | Physics joints created in code |
| Asteroids | asteroid_spawner.gd on timer | Continuous stream |
| Salvage | asteroid.gd / enemy_ship.gd on death | Drops from destroyed objects |
| Enemy ships | Future encounter spawner | Per encounter |
| Cargo grid instances | cargo_screen.gd on mode enter | One per vehicle grid + station |
