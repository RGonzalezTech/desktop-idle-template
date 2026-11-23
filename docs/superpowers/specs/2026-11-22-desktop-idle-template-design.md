# Design Doc: Desktop Idle Template

## Intent

A Godot 4.4 template for idle/incremental games that run as desktop companion windows, genre-agnostic — the same way friendslop-template is genre-agnostic for multiplayer. It provides the full idle engine (resources, producers, events, upgrades, clicker base) so a game built on it only adds theme, assets, and genre-specific behavior. Systems follow SOLID principles and are designed for extension.

## Goals

- **Full idle engine**: resources, producers, upgrades, events, shop — all in the template, all extendable. Click API via `ClickProducer.on_click()` — the UI layer decides how to invoke it.
- **Desktop-first**: runs as a window (not fullscreen), always-on-top toggle, remembers position/size
- **Data-driven simulation**: pure Resource objects drive state, UI subscribes to signals (same data/view split as Colony in Your Pocket)
- **Offline progress**: clock catches up on resume, distributes elapsed time to producers
- **Save/load**: full GameState serialization with versioning
- **SOLID**: abstract bases for Producer, Upgrade, Event, ClickBehavior; strategy pattern for pluggable behavior; dependency injection via exports
- **TDD**: GUT test suite for all simulation logic, smoke tests for UI scenes
- **Simple over complex**: no monolithic managers, focused components

## Non-Goals

- No AI, no characters, no behavior trees (genre layer)
- No multiplayer/networking
- No mobile support (desktop-only)
- No visual theme or art beyond placeholder rectangles
- No genre-specific mechanics (combat, crafting, dialog, colony management)

## Anti-Goals

- A game you can ship as-is — this is a template, not a product
- A Godot addon/plugin that patches into existing projects — this is a project template you clone
- Over-abstraction — if a system has only one sensible implementation in idle games, don't add an interface for it

## Constraints

- Godot 4.4, GDScript (tab-indented, typed, warnings as errors)
- GUT for testing
- MIT license — open-source, same as friendslop-template
- Desktop platforms only (Windows primary, Linux/Mac secondary)
- Windowed mode; window size configurable, default ~400x600 or similar compact size

## Approaches Considered

1. **Minimal: clock + resources + save/load only.** Too thin — every game rebuilds producers from scratch.
2. **Mid: clock + resources + producers, events/upgrades as genre layer.** Producers are universal, but events and upgrades are where idle games get their depth. Pushing those to every project means duplicated work.
3. **Full: resources + producers + events + upgrades + shop.** *(chosen)* Covers the 80% case for idle games. Abstract bases keep it genre-agnostic; concrete defaults cover the common patterns. Click API is a method, not a node — the UI layer owns input handling.

## Architecture

### Data Model

All simulation state lives in `Resource` subclasses. Godot's `.tres` serialization handles save/load natively.

```
GameState (Resource)
├── resources: ResourcePool (RefCounted)
├── producers: Array[BaseProducer] (Resource)
├── upgrades: Array[BaseUpgrade] (Resource)
├── events: Array[BaseEvent] (Resource)
├── shop_inventory: ShopInventory (Resource)
├── clock: GameClock (Resource)
└── config: GameConfig (Resource)
```

### Core Systems

#### GameClock
Tracks elapsed time. On resume from suspend/minimize, calculates `offline_delta` and emits `offline_time_elapsed(seconds)` so producers can catch up. Ticks at configurable rate (default 1Hz for idle — 24Hz is overkill when nothing changes second-to-second).

Offline catch-up is uncapped by default — the developer sets any cap they want in the genre layer. On resume, the template shows a modal ("Running Offline Catchup…") with a progress bar and current ticks-per-second display so the player sees what's happening rather than staring at a frozen window. The modal closes when catch-up completes.

```
GameClock
  - elapsed: float (total seconds since game start)
  - tick_rate: float (Hz, default 1.0)
  - is_paused: bool
  - last_save_epoch: int (for offline calc)
  - ticks_per_second_during_catchup: float (configurable, default 60 — runs simulation faster until caught up)
  Signals: tick(delta), offline_time_elapsed(seconds), catchup_started(total_seconds), catchup_progress(remaining, total), catchup_finished()
```

#### ResourcePool
A dictionary-backed collection of named resources. Not a Godot `Resource` itself — it's a RefCounted object that lives inside GameState. Each entry is a `GameResource` (Resource subclass).

```
GameResource (Resource)
  - resource_id: StringName
  - amount: float
  - min_value: float (default 0)
  - max_value: float (default INF)
  - display_name: String
  Signals: changed(new_amount, delta)

ResourcePool (RefCounted)
  - add_resource(id, initial, min, max) -> GameResource
  - get_resource(id) -> GameResource
  - modify(id, delta) -> float (returns new amount)
  - has_resource(id) -> bool
  - all_resources() -> Array[GameResource]
  Signals: resource_added, resource_removed, resource_changed
```

#### BaseProducer (abstract)
Generates resources over time. Concrete subclasses define *how* it produces. The template ships with:

- `PassiveProducer`: generates `rate` units of `target_resource` per second while active
- `ClickProducer`: extends PassiveProducer, adds `on_click()` that generates `click_amount` units immediately (with optional cooldown)

Both are concrete but designed for extension — override `_calculate_output(delta)` to change production math.

```
BaseProducer (Resource, abstract)
  - producer_id: StringName
  - target_resource: StringName (resource to generate)
  - is_active: bool
  - count: int (how many instances of this producer exist)
  - _calculate_output(delta: float) -> float (virtual)
  - tick(delta: float) -> float (calls _calculate_output, applies to pool)
  Signals: produced(resource_id, amount)

PassiveProducer extends BaseProducer
  - rate: float (per second, per instance)
  - _calculate_output(delta) -> rate * count * delta

ClickProducer extends PassiveProducer
  - click_amount: float (per click, per instance)
  - cooldown: float (seconds between clicks, 0 = none)
  - on_click() -> float (returns amount produced)
```

#### BaseUpgrade (abstract)
Modifies producer behavior. Applied to a producer by ID. Concrete subclasses define the modification.

```
BaseUpgrade (Resource, abstract)
  - upgrade_id: StringName
  - target_producer_id: StringName
  - is_purchased: bool
  - apply(producer: BaseProducer) -> void (virtual)
  Signals: purchased(upgrade_id)

MultiplyRateUpgrade extends BaseUpgrade
  - multiplier: float
  - apply(producer): producer.rate *= multiplier

UnlockProducerUpgrade extends BaseUpgrade
  - unlocks_producer_id: StringName
```

#### Shop (progression layer)

Separates *what's buyable and when* from *what produces what*. Producers and upgrades are pure simulation objects — they carry no cost or unlock data. Shop entries bridge the simulation to the UI: they define costs, unlock conditions, and what happens on purchase.

```
ShopEntry (Resource, abstract)
  - entry_id: StringName
  - display_name: String
  - cost_resource: StringName
  - cost_amount: float
  - unlock_condition: BaseEvent? (null = always visible)
  - is_visible(state: GameState) -> bool
  - can_afford(state: GameState) -> bool
  - purchase(state: GameState) -> bool (virtual)

ProducerShopEntry extends ShopEntry
  - producer_id: StringName
  - purchase(state): deduct cost, increment producer.count

UpgradeShopEntry extends ShopEntry
  - upgrade_id: StringName
  - purchase(state): deduct cost, mark upgrade purchased, apply it

ShopInventory (Resource)
  - entries: Array[ShopEntry]
  - get_visible_entries(state: GameState) -> Array[ShopEntry]
  - purchase(entry_id: StringName, state: GameState) -> bool
```

An event that grants a free upgrade calls `upgrade.purchase()` directly — no shop involved. An event that unlocks a shop entry sets the entry's unlock condition to satisfied. The shop layer never touches simulation math; the simulation layer never touches costs or visibility.

#### BaseEvent (abstract)
A condition → action pair. Evaluated each tick. Concrete subclasses define the trigger and effect.

```
BaseEvent (Resource, abstract)
  - event_id: StringName
  - has_fired: bool
  - one_shot: bool (fire once and remove)
  - check_condition(state: GameState) -> bool (virtual)
  - execute(state: GameState) -> void (virtual)

ResourceThresholdEvent extends BaseEvent
  - resource_id: StringName
  - threshold: float
  - comparison: enum (GREATER_THAN, LESS_THAN, EQUAL)
  - action_type: enum (UNLOCK_UPGRADE, MODIFY_RESOURCE, ACTIVATE_PRODUCER)
  - action_target: StringName
  - action_value: float
```

#### Click API

Clicking is a simulation concern, not an input concern. `ClickProducer.on_click()` is the sole API — the UI layer (a button, a `_gui_input` handler, a keyboard shortcut) calls it directly. The producer enforces its own cooldown internally and returns the amount produced (0 if on cooldown). No `BaseClickBehavior` node wrapper needed — the template doesn't dictate how clicks are triggered.

```
ClickProducer extends PassiveProducer
  - click_amount: float (per click, per instance)
  - cooldown: float (seconds between clicks, 0 = none)
  - on_click() -> float (returns amount produced, 0 if on cooldown)
```

### Simulation Runner

`IdleRunner` (Node) owns the GameState and drives the tick loop. It's the single coordinator — everything else subscribes to its signals.

```
IdleRunner (Node)
  - game_state: GameState
  - _ready(): load or create GameState, start clock timer
  - _on_tick(delta): tick clock, tick all producers, evaluate all events
  - save(), load()
  Signals: state_loaded, state_saved
```

### Window Management

`WindowManager` (Node, autoload candidate) handles desktop window behavior: always-on-top toggle, remember position/size between sessions via a config file, minimize-to-tray (stretch goal, platform-dependent).

### Project Structure

```
desktop-idle-template/
├── project.godot
├── AGENTS.md
├── README.md
├── CONTRIBUTING.md
├── gutconfig.json
├── docs/
│   └── superpowers/specs/
├── scripts/
│   ├── core/
│   │   ├── game_clock.gd
│   │   ├── game_resource.gd
│   │   ├── resource_pool.gd
│   │   ├── game_state.gd
│   │   ├── game_config.gd
│   │   ├── idle_runner.gd
│   │   └── save_system.gd
│   ├── producers/
│   │   ├── base_producer.gd
│   │   ├── passive_producer.gd
│   │   └── click_producer.gd
│   ├── upgrades/
│   │   ├── base_upgrade.gd
│   │   ├── multiply_rate_upgrade.gd
│   │   └── unlock_producer_upgrade.gd
│   ├── events/
│   │   ├── base_event.gd
│   │   └── resource_threshold_event.gd
│   ├── shop/
│   │   ├── shop_entry.gd
│   │   ├── producer_shop_entry.gd
│   │   ├── upgrade_shop_entry.gd
│   │   └── shop_inventory.gd
│   └── ui/
│       ├── window_manager.gd
│       └── (minimal UI scenes)
├── scenes/
│   ├── main.tscn
│   └── ui/
│       ├── main_view.tscn
│       ├── resource_display.tscn
│       └── producer_button.tscn
├── test/
│   ├── core/
│   │   ├── test_game_clock.gd
│   │   ├── test_resource_pool.gd
│   │   ├── test_game_state.gd
│   │   └── test_save_system.gd
│   ├── producers/
│   │   ├── test_passive_producer.gd
│   │   └── test_click_producer.gd
│   ├── upgrades/
│   │   └── test_upgrades.gd
│   ├── events/
│   │   └── test_events.gd
│   ├── shop/
│   │   └── test_shop_inventory.gd
│   └── ui/
│       └── (smoke tests)
├── assets/
│   └── (placeholder graphics)
└── addons/
    └── gut/
```

## Architectural Decisions

1. **Resources as Godot Resource subclasses** — *settled*
   - Rationale: native `.tres` serialization, editor visibility, matches Colony's pattern
   - Alternative: plain RefCounted objects with custom JSON serialization — more portable but loses editor integration

2. **ResourcePool as RefCounted, not Resource** — *settled*
   - Rationale: a dictionary of Resources doesn't need to be a Resource itself. Keeps the pool lightweight and avoids double-serialization. GameState owns it and handles serialization.

3. **Producers, Upgrades, Events as Resource subclasses** — *settled*
   - Rationale: each is individually serializable, can be composed in GameState. Matches SOLID — each is a single-responsibility object.
   - Alternative: store config as JSON/Dictionary on GameState — less type-safe, harder to test

4. **Tick rate default 1Hz** — *settled*
   - Rationale: idle games don't need per-frame updates. 1Hz is enough for "numbers go up" and keeps CPU near zero when idle. Configurable for games that need faster ticks.
   - Alternative: 24Hz like Colony — Colony has spatial simulation and AI; idle games don't benefit

5. **Signal-driven UI, not polling** — *settled*
   - Rationale: resources emit `changed` on every modification. UI labels connect once. No `_process` polling labels every frame. Same pattern as Colony's world renderer subscribing to WorldState signals.

6. **ClickProducer enforces its own cooldown** — *settled*
   - `on_click()` checks internal cooldown, returns 0 if still cooling down, returns `click_amount * count` and modifies the resource pool if ready. The UI calls this method directly (button press, keyboard shortcut, whatever) — no input-capturing middleware.
   - Rationale: click cooldown is game mechanics, not input handling. Putting it in the producer keeps the simulation self-contained and testable. The UI layer decides how to trigger clicks without the template dictating an input pattern.

7. **WindowManager as an autoload** — *settled*
   - Window state (position, always-on-top) is global and needed before any scene loads. Autoload ensures it's available at startup. No minimize-to-tray — that's platform-specific complexity the genre layer can add if needed.

8. **Save format: Godot .tres (ResourceSaver)** — *settled*
   - Rationale: simple, built-in, versionable via Godot's resource format. GameState is a Resource with sub-resources; `ResourceSaver.save("user://save.tres", game_state)` just works.
   - Alternative: JSON — human-readable but loses type information, requires manual serialization of every field

9. **Save versioning: integer version field + migration callbacks** — *builder's call*
   - `GameState` carries a `save_version: int` field (starts at 1). `SaveSystem` loads the `.tres`, checks the version, and runs registered migration functions in order (`_migrate_v1_to_v2()`, etc.) until the save matches the current version. Each migration transforms the loaded Resource tree in place before it enters the simulation. New template releases bump the version and ship a migration for any changed fields.
   - Rationale: Godot's `.tres` format has no native schema migration. A version integer + ordered callbacks is the simplest approach that doesn't require a separate serialization layer. It also means old saves never silently corrupt — a missing migration for a version gap produces a clear error.

10. **on_click() as the click API, no input middleware** — *settled*
   - The template provides `ClickProducer.on_click()` as the function the UI calls. It handles cooldown, resource modification, and returns the amount produced. The template ships no input-capturing nodes — the genre layer decides whether clicks come from a button, a keyboard shortcut, or a full-window tap area. This is the same pattern as friendslop-template's approach: provide the simulation method, let the game decide how to invoke it.

11. **Shop and simulation are separate layers** — *settled*
   - Producers and upgrades carry no cost, unlock, or visibility data — they are pure simulation objects. Shop entries own pricing, unlock conditions, and purchase logic. This means the same producer can have multiple shop entries at different progression tiers, an event can grant a free upgrade without touching shop code, and the simulation never needs to know about the UI's concept of "affordability."
   - Rationale: SOLID single-responsibility. Mixing cost data into producers would mean every producer instance carries shop concerns it doesn't use, and changing the shop model later would require touching every producer subclass.

## Open Questions

- [x] **WindowManager autoload vs scene node?** → Autoload.
- [x] **Minimize-to-tray?** → Omitted from template. Genre layer can add if needed.
- [x] **Offline progress cap?** → Uncapped by default, with catchup modal showing progress bar + ticks/sec. Developer sets their own cap.
- [x] **Project naming:** `desktop-idle-template`. MIT license, open-source — same as friendslop-template.
- [x] **Minimum viable UI:** one resource label, one click button, one shop entry. Bare bones.
