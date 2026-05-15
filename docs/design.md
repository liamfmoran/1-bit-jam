# Machines — Game Design Document

## Concept

Top-down 2D space trucking game. You pilot a player ship through space, traveling between docks, taking delivery jobs, and upgrading your ship. The current core loop is: **fly → dock → accept jobs / buy parts → deliver → undock → repeat**.

Built for a 1-bit graphics game jam. All visuals are rendered through a post-processing shader that reduces the frame to two colors with dithered shading.

## Core Loop

1. **Flying the Ship**
    * Fly through space with physics-driven controls. Your ship's mass matters (Ex. heavier loads slow, less nimble flight).
    * Navigate this treaterous space wasteland avoiding asteroids and debris.
    * Engage in combat if nessessary to protect your ship or the cargo you are transporting.
    * Collect salvage from destroyed asteroids, debris, or enemies.

2. **Dock with Space Docks**
    * Entering a dock zone opens animated side panels attached to the dock.
    * While docked you can:
        * Complete any delivery jobs for that dock automatically.
        * Accept new delivery jobs from the jobs panel.
        * Buy ship parts from the dock inventory panel.
        * Leave the dock while the camera smoothly blends back into flight zoom.


3. **Accept Jobs**
    * Jobs are point-to-point deliveries between named docks.
    * Each dock can provide its own authored jobs and ship parts.
    * Completing a job pays out as soon as you arrive at the destination dock.

4. **Repeat**
    * If your ship is destroyed in flight, you will respawn at the most recent station and we will give you a basic ship.

## Game Views

### Flight View

Top-down space with the player ship at center. The camera follows the ship with smoothed rotation and a velocity-based zoom target. Docking adds an animated zoom multiplier on top of that base zoom, so docked zoom and speed zoom overlap instead of handing off in steps. A starfield CanvasLayer reads the same camera rotation, so the background rotates with the view while preserving parallax and velocity streaks.

The ship is driven by physics (RigidBody2D). Thrusters apply forces at specific points on the hull. Lateral friction provides "road-like" grip so the ship doesn't slide sideways. Trailers are connected via pin joints and have stabilization thrusters to follow the cab.

Mass directly affects handling: `thrust / (cab_mass + cargo_mass)` determines acceleration. A fully loaded ship is sluggish; an empty one is nimble.

### Dock Interface

Dock interaction is currently in-world rather than a full-screen paused mode.

- **Jobs panel**: a left-side panel listing delivery jobs available at the current dock.
- **Inventory panel**: a right-side panel listing ship parts available for purchase.
- **Animated dock panels**: the dock itself visually opens and closes as the player enters or exits the docking zone.

## Controls (Planned Input Actions)

| Action | Keys | Context |
|---|---|---|
| `thrust_forward` | W / Up Arrow | Flight |
| `thrust_reverse` | S / Down Arrow | Flight |
| `turn_left` | A / Left Arrow | Flight |
| `turn_right` | D / Right Arrow | Flight |
| `interact` | E | Flight (dock at station) |
| `open_cargo` | Tab | Flight (quick cargo view, if applicable) |
| `open_customize` | C | Cargo view (switch to customize) |
| `rotate_item` | R | Cargo view (rotate held item) |
| `cancel` | Escape | Any (back / close overlay / pause) |

## Hazards & World Objects

### Asteroids
- Float through space, spawned in a ring around the player
- Break into smaller fragments on strong collision
- Damage cargo on impact

### Enemy Ships
- Hostile NPCs that steer toward the player and shoot
- Drop salvage on destruction
- Simple AI: approach + fire

### Salvage
- Floating pickups containing cargo items
- Dropped by destroyed asteroids, enemies, or found drifting
- Collected on overlap (or pulled in by magnet utility part)

### Docks
- Fixed locations in the world and currently hand-placed in `world.tscn`
- Dock zones trigger delivery completion plus the in-world jobs and inventory panels
- Each dock has its own authored jobs and parts for sale

## Visual Style

### 1-Bit Post-Processing

A full-screen shader on the topmost CanvasLayer converts the entire rendered frame to two colors:

1. Sample screen texture
2. Convert pixel to luminance
3. Compare against Bayer 4x4 dither threshold (indexed by `floor(FRAGCOORD.xy) % 4`)
4. Output `color_primary` (default white) or `color_secondary` (default black)

Primary and secondary colors are exposed as shader uniforms for easy theme swapping (amber/black CRT, green/black terminal, etc.).

### Camera and Starfield

- Camera rotation is enabled, so the world rotates with the smoothed camera heading.
- Docks and other world objects stay fixed in world space and correctly rotate in view as the camera turns.
- The starfield shader receives `camera_rotation`, `ship_position`, and `ship_velocity` so it can follow camera heading while still showing parallax drift.

### Resolution

- Internal viewport: 1280x720
- Stretch mode: `canvas_items` with `keep` aspect — scales up cleanly on larger displays
- Objects are not snapped to a pixel grid (smooth sub-pixel movement for fluid feel)
- Anti-aliasing is disabled

### Art Direction

All source art is simple geometric shapes (ColorRects, `_draw()` calls). The 1-bit shader does the heavy lifting for visual style. This keeps asset creation fast for the jam.

## Scope Guardrails

These are intentional limits to keep the project shippable for a game jam:

- No save/load system — a run is one play session
- No procedural dock placement — hand-place docks for jam scope
- No pathfinding for enemies — "steer toward player + shoot" is enough
- No multiplayer
- No settings menu (beyond possibly a palette color picker)
- Keep the minimap lightweight; it should stay a simple dock-and-heading reference rather than a full navigation screen
- No quest/mission system — the loop is emergent from buy/sell/survive
- Cap trailers at 2–3 for physics stability (PinJoint2D chains get wobbly beyond that)
