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
│   └── game_state.gd                      # Singleton: jobs, money, dock/undock signals
│
├── scenes/
│   ├── main.tscn                          # Root scene: starfield + world + HUD
│   ├── main.gd                            # Root scene script
│   │
│   ├── ship/
│   │   ├── ship.gd                        # RigidBody2D: player ship thrust / turning / braking
│   │   ├── trailer.gd                     # RigidBody2D: towable trailer, stabilization
│   │   └── ship_part_slot.gd              # Node2D: attachment point for upgradeable parts
│   │
│   ├── world/
│   │   ├── camera_manager.gd              # Camera2D: ship follow, smoothed rotation, blended zoom
│   │   ├── dock.gd                        # Node2D: dock trigger, delivery completion, dock UI host
│   │   ├── asteroid.gd                    # RigidBody2D: destructible, breaks on impact
│   │   ├── asteroid_spawner.gd            # Node2D: timer-driven ring spawner
│   │   ├── salvage.gd                     # Area2D: drifting cargo pickup
│   │   ├── station.gd                     # Legacy station script / world object
│   │   ├── enemy_ship.gd                  # RigidBody2D: hostile NPC
│   │   └── world.tscn                     # Flight scene: ship, docks, camera
│   │
│   ├── ui/
│   │   ├── hud.gd                         # Flight HUD controller
│   │   ├── minimap.gd                     # HUD minimap showing docks and player heading
│   │   ├── jobs_menu.gd                   # Dock-side job list
│   │   ├── inventory_menu.gd              # Dock-side parts shop
│   │   ├── job_item.gd                    # Reusable dock job row
│   │   ├── ship_part_item.gd              # Reusable dock inventory row
│   │   ├── cargo_screen.gd                # Legacy cargo UI
│   │   ├── cargo_grid.gd                  # Reusable Tetris-like inventory grid
│   │   ├── cargo_item_ghost.gd            # Dragged item preview
│   │   ├── customize_screen.gd            # Legacy ship customization overlay
│   │   └── pause_menu.gd                  # Pause overlay
│   │
│   └── effects/
│       ├── starfield.gd                   # ColorRect: feeds data to starfield shader
│       └── onebit_post.gd                 # ColorRect: applies 1-bit post-process shader
│
├── resources/
│   ├── jobs/
│   │   └── job_data.gd                    # JobData Resource: source/destination/value
│   └── parts/
│       └── ship_part_data.gd              # ShipPartData Resource: part shop inventory entry
│
├── shaders/
│   ├── onebit.gdshader                    # 1-bit post-process (Bayer dither, 2-color output)
│   ├── starfield.gdshader                 # Parallax star layers rotated by camera heading
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
├── StarfieldLayer (CanvasLayer, layer=-1)
│   └── Starfield (ColorRect, shader: starfield.gdshader)
├── World (Node2D)
│   ├── Ship (RigidBody2D)
│   │   ├── Hull (ColorRect)
│   │   ├── CollisionShape2D
│   │   ├── Flames/ (ColorRect children)
│   ├── DockA (Node2D)
│   ├── DockB (Node2D)
│   └── Camera2D (Camera2D)
└── HUD (CanvasLayer, layer=1)
    └── Minimap (Control)
```

## Runtime Responsibilities

- `camera_manager.gd` follows the player ship, rotates with smoothed heading, and computes zoom from ship speed multiplied by a dock-weighted zoom factor.
- `dock.gd` owns the dock detection zone, emits dock/undock events through `GameState`, completes deliveries, and mounts the jobs/inventory menus into the dock panels.
- `starfield.gd` feeds ship position, ship velocity, and active camera rotation into `starfield.gdshader`.
- `minimap.gd` renders dock positions relative to the player and rotates the player marker from ship heading.

## Collision Layers

| Bit | Name | Used By |
|-----|------|---------|
| 1 | Player | ship, trailers |
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
dock.gd body_entered(player)    → GameState.complete_delivery(dock_name)
dock.gd body_entered(player)    → GameState.docked
dock.gd body_exited(player)     → GameState.undocked
GameState.docked                → camera_manager.gd → tween dock zoom weight in
GameState.undocked              → camera_manager.gd → tween dock zoom weight out
camera_manager.gd               → active Camera2D rotation/zoom
starfield.gd                    → starfield.gdshader uniforms
minimap.gd                      → reads nodes in group("dock") + player transform
```

## Design Patterns Applied

| Pattern | Application | Reference |
|---------|-------------|-----------|
| **Component** | Camera, docks, minimap, and starfield split into focused scene scripts | [gameprogrammingpatterns.com/component.html](https://gameprogrammingpatterns.com/component.html) |
| **Type Object** | `JobData` and `ShipPartData` resources define dock content | [gameprogrammingpatterns.com/type-object.html](https://gameprogrammingpatterns.com/type-object.html) |
| **Observer** | Godot signals (`GameState.docked`, `GameState.undocked`) coordinate camera and dock flow | [gameprogrammingpatterns.com/observer.html](https://gameprogrammingpatterns.com/observer.html) |
| **Data-driven** | Jobs and parts are authored as `.tres` resources and assigned to docks in `world.tscn` | — |

## Pre-built vs. Dynamic Instantiation

### Pre-built in editor (placed in .tscn files)

| What | Where | Why |
|------|-------|-----|
| Ship | child of `world.tscn` | Always exists, only one |
| Docks | children of `world.tscn` | Hand-placed job / shop destinations |
| Camera2D | child of `world.tscn` | Always follows the ship |
| Starfield | `CanvasLayer` child of `main.tscn` | Background, always visible |
| Minimap | `HUD` child of `main.tscn` | Always visible flight UI |

### Dynamically instantiated at runtime

| What | Spawned by | Why |
|------|-----------|-----|
| Jobs menu | `dock.gd` on dock enter | Built only while docked |
| Inventory menu | `dock.gd` on dock enter | Built only while docked |
| Asteroids | `asteroid_spawner.gd` on timer | Continuous stream |
| Salvage | `asteroid.gd` / `enemy_ship.gd` on death | Drops from destroyed objects |
| Enemy ships | Future encounter spawner | Per encounter |
