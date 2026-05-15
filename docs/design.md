# Machines — Game Design Document

## Concept

Top-down 2D space trucking game. You pilot a truck cab through space, hauling trailers full of cargo between stations. The core loop is: **fly → find salvage / dock at station → load cargo (Tetris grid) → deliver → upgrade ship → repeat**.

Built for a 1-bit graphics game jam. All visuals are rendered through a post-processing shader that reduces the frame to two colors with dithered shading.

## Core Loop

1. **Flying the Ship**
    * Fly through space with physics-driven controls. Your ship's mass matters (Ex. heavier loads slow, less nimble flight).
    * Navigate this treaterous space wasteland avoiding asteroids and debris.
    * Engage in combat if nessessary to protect your ship or the cargo you are transporting.
    * Collect salvage from destroyed asteroids, debris, or enemies.

2. **Dock with Space Stations**
    * Entering a staton docking zone will allow you to:
        * Refuel your ship (Automatically, not paid)
        * Buy and sell from local vendors to upgrade your ship.
        * Upgrade your ship - Improve your ships resiliance, damage output, and even cargo capacity.
        * Complete a Delivery Job if you have one.
        * Store excess cargo


3. **Accept Jobs**
    * Accepting a job will release you from the station, and a new map will be available to explore depending on the Job accepted.
    * Fail a job, and you will lose out on money to spend on upgrading your ship.

4. **Repeat**
    * If your ship is destroyed in flight, you will respawn at the most recent station and we will give you a basic ship.

## Game Views

### Flight View

Top-down space with the truck cab at center. Camera follows the truck with rotation smoothing and speed-dependent zoom (pulls out at high speed). Starfield parallax background.

The truck is driven by physics (RigidBody2D). Thrusters apply forces at specific points on the hull. Lateral friction provides "road-like" grip so the truck doesn't slide sideways. Trailers are connected via pin joints and have stabilization thrusters to follow the cab.

Mass directly affects handling: `thrust / (cab_mass + cargo_mass)` determines acceleration. A fully loaded truck is sluggish; an empty one is nimble.

### Cargo Management View

Full-screen overlay when docked. The game world pauses.

**Grid system**: Each vehicle (cab, each trailer) has an inventory grid. Items are Tetris-like shapes (L-pieces, T-pieces, rectangles, etc.) that must fit into the grid cells. Drag items from the station inventory into your vehicle grids, or vice versa.

**Item properties**:
- **Grid shape**: defined as cell offsets (e.g., an L-shape is `[(0,0), (0,1), (0,2), (1,2)]`)
- **Mass**: contributes to total vehicle mass, affecting flight handling
- **Base value**: how much the item is worth at full condition
- **Radiation rate**: how fast the item's condition degrades over time (0 for stable items)
- **Condition**: float 0.0–1.0, starts at 1.0. Sell price = `base_value × condition`

**Value degradation**:
- Radiation: items with `radiation_rate > 0` lose condition continuously while in your cargo
- Collisions: when your truck or trailer takes a hit above a force threshold, all items in that vehicle's grid lose condition
- Enemy attacks: same as collisions

**Interactions**: click to pick up an item, R to rotate, click to place. Green/red ghost preview shows placement validity.

### Ship Customization View

Full-screen overlay when docked. Shows a top-down schematic of your ship (cab + trailers).

Each vehicle has **part slots** — fixed attachment points for upgradeable components:
- **Thrusters**: increase thrust multiplier, turn speed
- **Shields**: absorb collision damage before it reaches cargo
- **Weapons**: timer-based projectile spawners (lasers, etc.)
- **Utility**: magnets (attract salvage pickups), scanners, etc.

Click a slot to see available parts from the station's inventory. Buy/swap parts. A stats summary panel shows total mass, thrust, shield HP, and special abilities.

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

### Stations
- Fixed locations in the world (hand-placed, 2–3 for jam scope)
- Dock zone triggers cargo/customize views
- Each station has its own inventory, price modifiers, and parts for sale

## Visual Style

### 1-Bit Post-Processing

A full-screen shader on the topmost CanvasLayer converts the entire rendered frame to two colors:

1. Sample screen texture
2. Convert pixel to luminance
3. Compare against Bayer 4x4 dither threshold (indexed by `floor(FRAGCOORD.xy) % 4`)
4. Output `color_primary` (default white) or `color_secondary` (default black)

Primary and secondary colors are exposed as shader uniforms for easy theme swapping (amber/black CRT, green/black terminal, etc.).

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
- No procedural station placement — hand-place 2–3 stations
- No pathfinding for enemies — "steer toward player + shoot" is enough
- No multiplayer
- No settings menu (beyond possibly a palette color picker)
- No minimap — use simple directional arrows on the HUD
- No quest/mission system — the loop is emergent from buy/sell/survive
- Cap trailers at 2–3 for physics stability (PinJoint2D chains get wobbly beyond that)
