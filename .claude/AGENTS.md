# Project Memory

Instructions here apply to this project and are shared with team members.

## Context

## Project Guidelines

### Project Overview

- Engine: Godot 4.6.1, GDScript only, GL Compatibility renderer
- Viewport: `1280x720`, `canvas_items` stretch mode, `keep` aspect
- Game shape: 2D top-down space trucking game with physics-driven flight, cargo management (Tetris-like grid), and ship customization
- Visual style: 1-bit graphics via post-processing shader with configurable primary/secondary color uniforms and Bayer dithering. No pixel snapping, no anti-aliasing.
- Game name: "machines"

### Run, build, test, and lint commands

- Open/run in the editor with Godot 4.6.x by opening this repository root.
- CLI run (when Godot is installed): `godot --path .`
- Headless validation (useful after script/scene changes): `godot --headless --path . --quit`
- There is currently no repo-managed automated test suite and no lint configuration checked in. Do not invent `gut`, `gdUnit`, `gdlint`, or custom single-test commands for this project.

### Godot editor logs

Runtime logs are written to:

```bash
~/Library/Application Support/Godot/app_userdata/machines/logs/godot.log
```

Previous sessions are saved as `godot_1.log`, `godot_2.log`, etc. (higher numbers are older). Use these to investigate runtime errors, resource loading failures, and script parse problems without requiring the user to copy-paste output.

### High-level architecture

#### Entry flow

- `project.godot` boots `scenes/main.tscn`.
- `scenes/main.gd` orchestrates game state transitions (flight, cargo, customize) and manages visibility of UI overlays.
- `autoload/game_state.gd` is the singleton managing game mode, money, cargo placement, equipped parts, and mass calculation.

#### Game modes (State pattern)

- **FLIGHT**: Player pilots the truck cab through space. Physics simulation active, HUD visible.
- **CARGO**: Docked at a station. Tree paused. Tetris-like grid UI for loading/unloading cargo.
- **CUSTOMIZE**: Docked at a station. Tree paused. Ship part upgrade UI.

Transitions are managed via `GameState.set_mode()` which emits `mode_changed`. `main.gd` is the sole listener that toggles pause state and UI visibility.

#### Ship system

- `scenes/ship/truck_cab.gd` — RigidBody2D player cab with thrusters, lateral friction, camera control. Mass is dynamic based on cargo.
- `scenes/ship/trailer.gd` — RigidBody2D towable trailer connected via PinJoint2D. Has its own cargo grid.
- `scenes/ship/ship_part_slot.gd` — Node2D attachment point for upgradeable parts. Placed as children of cab/trailer scenes in the editor.

#### World objects

- `scenes/world/asteroid.gd` — Destructible RigidBody2D, breaks into fragments on impact.
- `scenes/world/asteroid_spawner.gd` — Timer-driven spawner creating asteroids in a ring around the player.
- `scenes/world/station.gd` — StaticBody2D + Area2D dock zone. Triggers cargo/customize mode on interact.
- `scenes/world/salvage.gd` — Area2D pickup containing a PackageData resource.
- `scenes/world/enemy_ship.gd` — RigidBody2D hostile NPC.

#### UI

- `scenes/ui/hud.gd` — Flight-mode HUD (speed, cargo mass, money).
- `scenes/ui/cargo_screen.gd` — Orchestrates cargo grid instances for cab, trailers, and station inventory.
- `scenes/ui/cargo_grid.gd` — Reusable inventory grid Control. Handles cell occupancy, placement validation, `_draw()` rendering.
- `scenes/ui/cargo_item_ghost.gd` — Dragged item preview following the mouse with rotation and validity tinting.
- `scenes/ui/customize_screen.gd` — Ship part slot picker and stat comparison panel.

#### Effects

- `scenes/effects/starfield.gd` — Feeds truck position/velocity to the starfield shader.
- `scenes/effects/onebit_post.gd` — Applies the 1-bit post-processing shader. Exposes primary/secondary color uniforms.

#### Data resources (Type Object pattern)

- `resources/packages/package_data.gd` — `PackageData` Resource: grid_shape, mass, base_value, radiation_rate, icon. New packages are `.tres` files.
- `resources/parts/ship_part_data.gd` — `ShipPartData` Resource: slot_type, stats dictionary, mass, cost, icon. New parts are `.tres` files.
- `resources/stations/station_data.gd` — `StationData` Resource: station name, buy/sell item lists, price modifiers.

### Key conventions

- Co-locate scripts with their scenes (e.g., `scenes/ship/truck_cab.gd` alongside its `.tscn`).
- Prefer scene composition over dynamic instantiation. Add nodes in the editor where possible.
- Use Godot Resources (`.tres`) for data-driven content (items, parts, stations). New content = new `.tres` file, no code changes.
- Ship parts use a freeform `stats: Dictionary` on the Resource. New stats are added by inserting a key in the `.tres` and reading it with `GameState.get_part_stat()`.
- GameState is the single autoload singleton. It owns mode state, money, cargo, and equipped parts.

### Editing `.tscn` and `.tres` files

Godot scene (`.tscn`) and resource (`.tres`) files are text-based and safe to edit directly, but contain several types of generated identifiers that must be handled correctly.

#### ID types and how to generate them

Resource UIDs (`uid://...` in file headers and `ext_resource` entries):

- Do not hand-craft UIDs. Godot generates UIDs internally and stores them in `.uid` sidecar files. Hand-crafted UIDs will not match the sidecar/cache and cause `invalid UID` warnings on every load. Instead, omit the `uid=` attribute from new `ext_resource` lines and scene headers. Godot will resolve resources by `path=` and assign correct UIDs on next editor save.
- If you need to reference an existing resource's UID, look it up from its `.uid` sidecar file or from another `.tscn`/`.tres` that already references it. Never invent one.
- For new `.tscn`/`.tres` file headers, omit the `uid=` or use the headless helper script below to generate a valid one.

`ext_resource` local IDs (`id="1_7bt6s"`, etc.):

- File-scoped. Format: `{incrementing_counter}_{5 random chars from a-z0-9}`.
- Only need to be unique within the file. Counter starts at 1 and increments per `ext_resource`.

`sub_resource` local IDs (`id="CapsuleShape2D_5c8dj"`, etc.):

- File-scoped. Format: `{TypeName}_{5 random chars from a-z0-9}`.
- Only need to be unique within the file.

Node `unique_id` values (`unique_id=1676358029`):

- Random positive 32-bit integer, assigned by the editor when a node is marked Access as Unique Name (`%NodeName`).
- Only present on nodes that use this feature.

When creating or modifying `.tscn`/`.tres` files, generate these IDs using the algorithms above. As an alternative when Godot is available on the system, use headless mode:

```bash
godot --headless --path . --script res://path/to/helper.gd
```

With a helper like:

```gdscript
extends SceneTree
func _init():
	var id = ResourceUID.create_id()
	print(ResourceUID.id_to_text(id))
	quit()
```

#### Rules for editing scene and resource files

- Never modify an existing ID. Preserve all `uid=`, `id=`, and `unique_id=` values exactly as they appear in the file.
- When adding a new `ext_resource`, generate a valid local `id=` (unique within the file) and include `path=` for the referenced resource. Only include `uid=` if you can look it up from the resource's existing `.uid` sidecar file or from another scene that already references it. If the UID is unknown, such as for a brand-new resource, omit `uid=` entirely. Godot will resolve by path.
- When adding a new `sub_resource`, generate a valid local `id=` in `TypeName_xxxxx` format.
- When adding a new node, only include `unique_id=` if the node needs `%Name` access. Generate a random positive int32 if so.
- When creating a brand-new `.tscn` or `.tres` file, generate a `uid=` for the file header. Use `format=3` for Godot 4.x.
- Safe to change without ID concerns: property values, `@export` defaults, node `name=`, `parent=`, `node_paths=`, signal `[connection]` entries, and `script` references (by path or existing uid).
- Update `load_steps` in the `[gd_scene]` or `[gd_resource]` header when adding or removing resources. The value equals total `ext_resource` + `sub_resource` + 1.

#### UID files and cache consistency

Godot 4.6+ stores each resource's UID in a sidecar `.uid` file, such as `main.gd.uid` alongside `main.gd`. The editor also maintains a global cache at `.godot/uid_cache.bin`. These can fall out of sync when files are created or moved outside the editor.

- Always commit `.uid` files alongside their resources. They are the source of truth for resource identity.
- Never create `.uid` sidecar files by hand. Let Godot generate them by opening the project in the editor or running a headless import. Hand-crafted UIDs will mismatch the internal cache and cause warnings.
- Never invent UIDs by hand in `.tscn`/`.tres` files. Omit the `uid=` attribute from `ext_resource` lines for new resources. Godot resolves by `path=` and fills in the correct UID on next save.
- If `invalid UID` warnings appear after changes, the most common cause is a stale `uid://` value in a `.tscn` or `.tres` `ext_resource` line that doesn't match the resource's actual UID stored in its `.uid` sidecar file. Quick fix: remove the `uid="uid://..."` attribute from the offending `ext_resource` line entirely. Godot will resolve the resource by its `path=` attribute and re-cache the correct UID on next save.
- Alternatively, run a full reimport to rebuild the cache:

```bash
godot --headless --path . --import
```

- A simple `--quit` run is insufficient. It loads the main scene before the import pipeline finishes, so missing cache entries and textures cause cascading errors.
- Do not delete `.godot/uid_cache.bin` or `.godot/imported/` manually unless you follow up with `--import`. Deleting them and running `--quit` will break resource loading.

### GDScript naming and base class conflicts

- Avoid parameter names that shadow `CanvasItem` or `Node` properties. Common offenders: `material`, `position`, `scale`, `visible`, `name`, `modulate`. Use domain-specific names instead, such as `mat_id`, `cell_material`, or `terrain_material`.
- The warning `SHADOWED_VARIABLE_BASE_CLASS` is emitted when a function parameter or local variable matches a property inherited from the node's base class. Rename the parameter, not the base class property.

### Code / review / headless test loop

After making code changes, follow this loop to validate before reporting back to the user:

1. **Headless validation** — Run the Godot headless check to catch parse errors, compile failures, and missing class references:

   ```bash
   /Applications/Godot*.app/Contents/MacOS/Godot --headless --path . --quit 2>&1 | grep -iE 'ERROR|SCRIPT ERROR|Cannot'
   ```

   - If a new `class_name` was added (new `.gd` file), Godot may not discover it until an import is run. If you see `Identifier "ClassName" not declared`, run a full import first:

     ```bash
     /Applications/Godot*.app/Contents/MacOS/Godot --headless --path . --import 2>&1
     ```

     Then re-run the `--quit` validation.

   - `timeout` / `gtimeout` are not available on this system. To avoid hangs, run headless commands in the background with a kill timer:

     ```bash
     /Applications/Godot*.app/Contents/MacOS/Godot --headless --path . --quit 2>&1 &
     PID=$!; sleep 15; kill $PID 2>/dev/null; wait $PID 2>/dev/null
     ```

2. **Log review** — After the user playtests, check the runtime logs for errors:

   ```bash
   grep -iE 'ERROR|SCRIPT ERROR|Cannot|freed instance' ~/Library/Application\ Support/Godot/app_userdata/machines/logs/godot.log
   ```

3. **Fix and repeat** — If errors are found, fix them and re-run step 1. Do not report success to the user until headless validation passes clean (no output from the error grep).

#### Common pitfalls

- **Typed iterators on freed objects**: `for item: Node2D in items` crashes if any element was freed. Use `for item: Variant in items` with `is_instance_valid()` when the collection may contain freed references.
- **New scripts not found**: New `.gd` files with `class_name` declarations require a `--import` run before `--quit` will recognize them.
- **Cascading compile errors**: A single script failure (e.g. missing class) cascades to every script that depends on it. Fix the root cause first — the downstream errors resolve automatically.
- **Stale UID cache**: After creating new resources outside the editor, omit `uid=` from `ext_resource` lines and let Godot resolve by `path=`.
