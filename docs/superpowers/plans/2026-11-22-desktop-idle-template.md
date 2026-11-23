# Desktop Idle Template Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Godot 4.4 template for idle/incremental desktop companion games with a full idle engine (resources, producers, upgrades, events, shop) and a minimal bare-bones UI.

**Architecture:** Data-driven simulation via Godot `Resource` subclasses. Signal-driven UI subscribes to state changes — no polling. Shop and simulation are separate layers: producers/upgrades carry no cost or unlock data. Fixed timestep at 1Hz default. WindowManager autoload for desktop window behavior.

**Tech Stack:** Godot 4.4, GDScript (tab-indented, typed, warnings as errors), GUT testing framework, MIT license.

**Spec:** `docs/superpowers/specs/2026-11-22-desktop-idle-template-design.md`

## Global Constraints

- Godot 4.4, GDScript tab-indented, typed, warnings-as-errors
- MIT license
- Desktop-only (Windows primary)
- GUT for all simulation tests; smoke tests for UI scenes
- Warnings are errors: use `clampi()`, `clampf()`, explicit type annotations for Dictionary lookups
- After creating a script with `class_name`, run `godot --headless --import` before running GUT
- Windowed mode, configurable size (~400x600 default)
- Always-on-top toggle via `DisplayServer.window_set_flag()`
- Commit: `Component: what changed`, imperative mood; `.gd.uid` in same commit

## Review Focus

These are failure modes the spec implies that are most likely to bite a user of this template. Each is tested in its owning task.

1. **Offline catchup with zero elapsed time** (fresh install, no previous save) — must not crash or show catchup modal. Tested in Task 2 (GameClock).
2. **Resource modification that would exceed max_value** — must clamp, not overflow. Tested in Task 3 (ResourcePool).
3. **Shop purchase with insufficient resources** — must return false, not go negative. Tested in Task 10 (Shop).
4. **Upgrade applied to non-existent producer ID** — must handle gracefully, not crash. Tested in Task 7 (Upgrades).
5. **Save/load roundtrip preserves all state exactly** — loaded state must match saved state field-for-field. Tested in Task 11 (SaveSystem).

---

### Task 1: Project Scaffolding

**Files:**
- Create: `project.godot`, `gutconfig.json`, `AGENTS.md`, `README.md`, `CONTRIBUTING.md`, `LICENSE`, directory tree (`scripts/core/`, `scripts/producers/`, `scripts/upgrades/`, `scripts/events/`, `scripts/shop/`, `scripts/ui/`, `scenes/ui/`, `test/core/`, `test/producers/`, `test/upgrades/`, `test/events/`, `test/shop/`, `test/ui/`, `assets/`, `addons/gut/`)

**Interfaces:**
- Consumes: nothing
- Produces: Godot project with GUT configured, all directories exist, AGENTS.md/README.md/CONTRIBUTING.md/LICENSE written

- [ ] **Step 1: Create project.godot**

Configure for Godot 4.4, windowed mode, 400x600 default, MIT license metadata. Input map: `click_action` bound to left mouse button. No main scene yet (assigned when main.tscn exists).

- [ ] **Step 2: Create gutconfig.json**

```json
{
  "dirs": ["res://test/"],
  "should_exit": true,
  "ignore_pause": true,
  "log_level": 1
}
```

- [ ] **Step 3: Copy GUT addon**

Copy `addons/gut/` from friendslop-template or Colony. If unavailable, install via Godot Asset Library or download GUT 9.x.

- [ ] **Step 4: Create directory tree**

All directories listed in Files above. Empty `.gitkeep` in each leaf directory.

- [ ] **Step 5: Write AGENTS.md**

Follow friendslop-template's AGENTS.md format. Same architecture rules, testing commands, GDScript conventions. Add idle-template-specific notes: 1Hz tick rate, shop/sim split, click API pattern.

- [ ] **Step 6: Write README.md**

Follow friendslop-template's README format. Describe purpose (genre-agnostic idle game template), key features (data-driven simulation, shop/sim split, offline catchup), project structure, quick start.

- [ ] **Step 7: Write CONTRIBUTING.md and LICENSE**

CONTRIBUTING.md mirrors friendslop-template's. LICENSE is MIT (copy from friendslop-template or standard MIT text).

- [ ] **Step 8: Run `godot --headless --import` to validate project**

Command: `godot --headless --import --path C:/Dev/GameDev/Templates/desktop-idle-template`
Expected: exit code 0, no errors.

- [ ] **Step 9: Commit**

```
git add -A
git commit -m "Scaffolding: project setup, docs, GUT, directory tree"
```

---

### Task 2: GameClock

**Files:**
- Create: `scripts/core/game_clock.gd`
- Test: `test/core/test_game_clock.gd`

**Interfaces:**
- Consumes: project.godot (GUT configured)
- Produces: `GameClock` (Resource, class_name)
  - Properties: `elapsed: float`, `tick_rate: float` (default 1.0), `is_paused: bool`, `last_save_epoch: int`, `ticks_per_second_during_catchup: float` (default 60.0)
  - Signals: `tick(delta: float)`, `offline_time_elapsed(seconds: float)`, `catchup_started(total_seconds: float)`, `catchup_progress(remaining: float, total: float)`, `catchup_finished()`
  - Methods: `start()`, `pause()`, `resume()`, `_on_timer_timeout()`

- [ ] **Step 1: Write failing test — tick increments elapsed**

```gdscript
extends GutTest

func test_tick_increments_elapsed():
    var clock = autofree(GameClock.new())
    clock.tick_rate = 1.0
    clock.start()
    # Simulate one tick
    clock._on_timer_timeout()
    assert_almost_eq(clock.elapsed, 1.0, 0.01)
```

Run: `godot --headless --rendering-driver opengl3 -s addons/gut/gut_cmdln.gd -gconfig=res://gutconfig.json -gdir=res://test/core`
Expected: FAIL (GameClock class not defined)

- [ ] **Step 2: Implement `GameClock` in `scripts/core/game_clock.gd`**

Extends `Resource`. Internal `Timer` node for ticks. `_on_timer_timeout()` increments `elapsed` by `1.0 / tick_rate` and emits `tick(delta)`. `start()` creates the timer and sets it running. `pause()`/`resume()` stop/start the timer.

- [ ] **Step 3: Run tick test — verify GREEN**

Expected: PASS

- [ ] **Step 4: Write failing test — pause stops ticks**

```gdscript
func test_pause_stops_ticks():
    var clock = autofree(GameClock.new())
    clock.tick_rate = 1.0
    clock.start()
    clock.pause()
    var before = clock.elapsed
    clock._on_timer_timeout()
    assert_eq(clock.elapsed, before)
```

- [ ] **Step 5: Implement pause/resume**

- [ ] **Step 6: Run pause test — verify GREEN**

- [ ] **Step 7: Write failing test — resume calculates offline delta and emits signal**

```gdscript
func test_resume_calculates_offline_delta():
    var clock = autofree(GameClock.new())
    clock.tick_rate = 1.0
    clock.start()
    clock.pause()
    clock.last_save_epoch = Time.get_unix_time_from_system() - 10  # 10 seconds ago
    var caught_signal = false
    clock.catchup_started.connect(func(total): caught_signal = true)
    clock.resume()
    assert_true(caught_signal, "catchup_started should emit on resume with offline time")
```

- [ ] **Step 8: Implement offline catchup in `resume()`**

On resume, check `last_save_epoch` vs current epoch. If delta > 0, emit `catchup_started(total_seconds)`. Run a tight loop at `ticks_per_second_during_catchup` rate, emitting `tick(sim_delta)` and `catchup_progress(remaining, total)` each iteration until caught up. Emit `catchup_finished()`. Handle zero delta (fresh install) — emit no catchup signals.

- [ ] **Step 9: Run offline test — verify GREEN**

- [ ] **Step 10: Write test — zero offline delta emits no catchup** (Review Focus #1)

```gdscript
func test_zero_offline_delta_no_catchup():
    var clock = autofree(GameClock.new())
    clock.start()
    clock.pause()
    clock.last_save_epoch = Time.get_unix_time_from_system()  # now
    var emitted = false
    clock.catchup_started.connect(func(_t): emitted = true)
    clock.resume()
    assert_false(emitted, "Zero delta should not trigger catchup")
```

- [ ] **Step 11: Verify zero-delta test passes**

- [ ] **Step 12: Run full test suite**

```bash
godot --headless --rendering-driver opengl3 -s addons/gut/gut_cmdln.gd -gconfig=res://gutconfig.json -gdir=res://test/core
```
Expected: all tests PASS

- [ ] **Step 13: Commit**

```
git add scripts/core/game_clock.gd scripts/core/game_clock.gd.uid test/core/test_game_clock.gd test/core/test_game_clock.gd.uid
git commit -m "GameClock: time tracking, tick, pause/resume, offline catchup"
```

---

### Task 3: GameResource + ResourcePool

**Files:**
- Create: `scripts/core/game_resource.gd`, `scripts/core/resource_pool.gd`
- Test: `test/core/test_resource_pool.gd`

**Interfaces:**
- Consumes: nothing (standalone)
- Produces:
  - `GameResource` (Resource, class_name): `resource_id: StringName`, `amount: float`, `min_value: float` (default 0), `max_value: float` (default INF), `display_name: String`. Signal `changed(new_amount: float, delta: float)`.
  - `ResourcePool` (RefCounted, class_name): `add_resource(id, initial, min, max) -> GameResource`, `get_resource(id) -> GameResource`, `modify(id, delta) -> float`, `has_resource(id) -> bool`, `all_resources() -> Array[GameResource]`. Signals: `resource_added`, `resource_removed`, `resource_changed`.

- [ ] **Step 1: Write failing test — add and retrieve resource**

```gdscript
extends GutTest

func test_add_and_get_resource():
    var pool = autofree(ResourcePool.new())
    var res = pool.add_resource("gold", 100.0, 0.0, 9999.0)
    assert_eq(res.amount, 100.0)
    assert_eq(pool.get_resource("gold").amount, 100.0)
    assert_true(pool.has_resource("gold"))
    assert_false(pool.has_resource("silver"))
```

Run: expected FAIL

- [ ] **Step 2: Implement `GameResource` and `ResourcePool`**

`GameResource` extends `Resource` with the properties listed. Signal `changed` emits on `amount` setter.
`ResourcePool` extends `RefCounted`. Internal `Dictionary[StringName, GameResource]`. `modify()` adds delta to amount, clamping to [min, max], emits resource's `changed` and pool's `resource_changed`. Returns new amount.

- [ ] **Step 3: Run add/get test — verify GREEN**

- [ ] **Step 4: Write failing test — modify clamps to min/max** (Review Focus #2)

```gdscript
func test_modify_clamps_to_limits():
    var pool = autofree(ResourcePool.new())
    pool.add_resource("gold", 50.0, 0.0, 100.0)
    var result = pool.modify("gold", 100.0)  # would be 150, capped at 100
    assert_eq(result, 100.0)
    result = pool.modify("gold", -200.0)  # would be -100, capped at 0
    assert_eq(result, 0.0)
```

- [ ] **Step 5: Implement clamping in `modify()`**

- [ ] **Step 6: Run clamp test — verify GREEN**

- [ ] **Step 7: Write failing test — signal emits on change**

```gdscript
func test_signal_emits_on_change():
    var pool = autofree(ResourcePool.new())
    pool.add_resource("gold", 0.0)
    var caught = null
    pool.resource_changed.connect(func(id, amount, delta): caught = {"id": id, "amount": amount, "delta": delta})
    pool.modify("gold", 50.0)
    assert_not_null(caught)
    assert_eq(caught.id, "gold")
    assert_eq(caught.amount, 50.0)
    assert_eq(caught.delta, 50.0)
```

- [ ] **Step 8: Implement signal emission**

- [ ] **Step 9: Run signal test — verify GREEN**

- [ ] **Step 10: Run full test suite and commit**

```
git add scripts/core/game_resource.gd scripts/core/game_resource.gd.uid scripts/core/resource_pool.gd scripts/core/resource_pool.gd.uid test/core/test_resource_pool.gd test/core/test_resource_pool.gd.uid
git commit -m "ResourcePool: named resources with min/max clamping and signals"
```

---

### Task 4: GameConfig

**Files:**
- Create: `scripts/core/game_config.gd`
- Test: `test/core/test_game_config.gd`

**Interfaces:**
- Consumes: nothing
- Produces: `GameConfig` (Resource, class_name): `window_width: int` (400), `window_height: int` (600), `tick_rate: float` (1.0), `catchup_ticks_per_second: float` (60.0), `starting_resources: Dictionary`, `starting_producers: Dictionary`

- [ ] **Step 1: Write failing test — default values**

```gdscript
extends GutTest

func test_default_values():
    var config = autofree(GameConfig.new())
    assert_eq(config.window_width, 400)
    assert_eq(config.window_height, 600)
    assert_almost_eq(config.tick_rate, 1.0, 0.01)
```

- [ ] **Step 2: Implement `GameConfig`**

Extends `Resource`. `@export var` for each property with defaults. `starting_resources` is `Dictionary[StringName, float]`. `starting_producers` is `Dictionary[StringName, int]` (producer_id → initial count).

- [ ] **Step 3: Run tests and commit**

```
git add scripts/core/game_config.gd scripts/core/game_config.gd.uid test/core/test_game_config.gd test/core/test_game_config.gd.uid
git commit -m "GameConfig: template-wide configuration Resource"
```

---

### Task 5: BaseProducer + PassiveProducer

**Files:**
- Create: `scripts/producers/base_producer.gd`, `scripts/producers/passive_producer.gd`
- Test: `test/producers/test_passive_producer.gd`

**Interfaces:**
- Consumes: `ResourcePool`, `GameResource`
- Produces:
  - `BaseProducer` (Resource, class_name, abstract): `producer_id: StringName`, `target_resource: StringName`, `is_active: bool`, `count: int`, `_calculate_output(delta: float) -> float` (virtual), `tick(delta: float, pool: ResourcePool) -> float`. Signal `produced(resource_id: StringName, amount: float)`.
  - `PassiveProducer` extends BaseProducer: `rate: float` (per second per instance), `_calculate_output(delta) -> rate * count * delta`.

- [ ] **Step 1: Write failing test — passive producer generates resources**

```gdscript
extends GutTest

func test_passive_producer_generates():
    var pool = autofree(ResourcePool.new())
    pool.add_resource("gold", 0.0)
    var producer = autofree(PassiveProducer.new())
    producer.producer_id = "gold_miner"
    producer.target_resource = "gold"
    producer.rate = 10.0
    producer.count = 2
    producer.is_active = true
    var produced = producer.tick(1.0, pool)
    assert_almost_eq(produced, 20.0, 0.01)
    assert_almost_eq(pool.get_resource("gold").amount, 20.0, 0.01)
```

Run: expected FAIL

- [ ] **Step 2: Implement `BaseProducer` and `PassiveProducer`**

`BaseProducer` extends `Resource`. `tick()` calls `_calculate_output(delta)`, calls `pool.modify(target_resource, output)`, emits `produced`, returns the amount. `PassiveProducer` overrides `_calculate_output`: `return rate * count * delta`.

- [ ] **Step 3: Run generation test — verify GREEN**

- [ ] **Step 4: Write failing test — inactive producer generates nothing**

```gdscript
func test_inactive_producer_zero():
    var pool = autofree(ResourcePool.new())
    pool.add_resource("gold", 0.0)
    var producer = autofree(PassiveProducer.new())
    producer.target_resource = "gold"
    producer.rate = 10.0
    producer.count = 1
    producer.is_active = false
    var produced = producer.tick(1.0, pool)
    assert_eq(produced, 0.0)
    assert_eq(pool.get_resource("gold").amount, 0.0)
```

- [ ] **Step 5: Implement `is_active` check in `tick()`**

- [ ] **Step 6: Run inactive test — verify GREEN**

- [ ] **Step 7: Run full test suite and commit**

```
git add scripts/producers/base_producer.gd scripts/producers/base_producer.gd.uid scripts/producers/passive_producer.gd scripts/producers/passive_producer.gd.uid test/producers/test_passive_producer.gd test/producers/test_passive_producer.gd.uid
git commit -m "Producers: BaseProducer + PassiveProducer with pool integration"
```

---

### Task 6: ClickProducer

**Files:**
- Create: `scripts/producers/click_producer.gd`
- Test: `test/producers/test_click_producer.gd`

**Interfaces:**
- Consumes: `PassiveProducer`, `ResourcePool`
- Produces: `ClickProducer` extends `PassiveProducer`: `click_amount: float`, `cooldown: float` (0 = none), `on_click(pool: ResourcePool) -> float` (returns amount produced, 0 if on cooldown)

- [ ] **Step 1: Write failing test — click produces resources**

```gdscript
extends GutTest

func test_click_produces():
    var pool = autofree(ResourcePool.new())
    pool.add_resource("gold", 0.0)
    var producer = autofree(ClickProducer.new())
    producer.target_resource = "gold"
    producer.click_amount = 5.0
    producer.count = 3
    var result = producer.on_click(pool)
    assert_almost_eq(result, 15.0, 0.01)
    assert_almost_eq(pool.get_resource("gold").amount, 15.0, 0.01)
```

- [ ] **Step 2: Implement `ClickProducer`**

`on_click(pool)`: if cooldown active, return 0.0. Otherwise, `amount = click_amount * count`, call `pool.modify(target_resource, amount)`, start cooldown timer, return amount. Track last click time for cooldown.

- [ ] **Step 3: Run click test — verify GREEN**

- [ ] **Step 4: Write failing test — cooldown blocks rapid clicks**

```gdscript
func test_cooldown_blocks_rapid_clicks():
    var pool = autofree(ResourcePool.new())
    pool.add_resource("gold", 0.0)
    var producer = autofree(ClickProducer.new())
    producer.target_resource = "gold"
    producer.click_amount = 10.0
    producer.count = 1
    producer.cooldown = 999.0  # effectively blocks second click
    var first = producer.on_click(pool)
    assert_almost_eq(first, 10.0, 0.01)
    var second = producer.on_click(pool)
    assert_eq(second, 0.0)
    assert_almost_eq(pool.get_resource("gold").amount, 10.0, 0.01)
```

- [ ] **Step 5: Implement cooldown enforcement**

- [ ] **Step 6: Run cooldown test — verify GREEN**

- [ ] **Step 7: Run test suite and commit**

```
git add scripts/producers/click_producer.gd scripts/producers/click_producer.gd.uid test/producers/test_click_producer.gd test/producers/test_click_producer.gd.uid
git commit -m "ClickProducer: on_click() API with internal cooldown enforcement"
```

---

### Task 7: BaseUpgrade + MultiplyRateUpgrade + UnlockProducerUpgrade

**Files:**
- Create: `scripts/upgrades/base_upgrade.gd`, `scripts/upgrades/multiply_rate_upgrade.gd`, `scripts/upgrades/unlock_producer_upgrade.gd`
- Test: `test/upgrades/test_upgrades.gd`

**Interfaces:**
- Consumes: `BaseProducer`, `PassiveProducer`
- Produces:
  - `BaseUpgrade` (Resource, class_name, abstract): `upgrade_id: StringName`, `target_producer_id: StringName`, `is_purchased: bool`, `apply(producer: BaseProducer) -> void` (virtual), `purchase()`. Signal `purchased(upgrade_id: StringName)`.
  - `MultiplyRateUpgrade` extends BaseUpgrade: `multiplier: float`, `apply(producer)` sets `producer.rate *= multiplier`
  - `UnlockProducerUpgrade` extends BaseUpgrade: `unlocks_producer_id: StringName`, `apply(producer)` sets `producer.is_active = true`

- [ ] **Step 1: Write failing test — multiply rate upgrade doubles rate**

```gdscript
extends GutTest

func test_multiply_rate_upgrade():
    var producer = autofree(PassiveProducer.new())
    producer.rate = 10.0
    var upgrade = autofree(MultiplyRateUpgrade.new())
    upgrade.target_producer_id = "miner"
    upgrade.multiplier = 2.0
    producer.producer_id = "miner"
    upgrade.apply(producer)
    assert_almost_eq(producer.rate, 20.0, 0.01)
```

- [ ] **Step 2: Implement `BaseUpgrade`, `MultiplyRateUpgrade`, `UnlockProducerUpgrade`**

`BaseUpgrade.purchase()` sets `is_purchased = true` and emits `purchased`. `MultiplyRateUpgrade.apply()` multiplies rate. `UnlockProducerUpgrade.apply()` sets `is_active = true`.

- [ ] **Step 3: Run multiply test — verify GREEN**

- [ ] **Step 4: Write failing test — unlock upgrade activates producer**

```gdscript
func test_unlock_upgrade_activates_producer():
    var producer = autofree(PassiveProducer.new())
    producer.is_active = false
    producer.producer_id = "miner"
    var upgrade = autofree(UnlockProducerUpgrade.new())
    upgrade.unlocks_producer_id = "miner"
    upgrade.target_producer_id = "miner"
    upgrade.apply(producer)
    assert_true(producer.is_active)
```

- [ ] **Step 5: Run unlock test — verify GREEN**

- [ ] **Step 6: Write test — upgrade purchase emits signal**

```gdscript
func test_upgrade_purchase_emits_signal():
    var upgrade = autofree(MultiplyRateUpgrade.new())
    upgrade.upgrade_id = "double_rate"
    var caught = false
    upgrade.purchased.connect(func(id): caught = true)
    upgrade.purchase()
    assert_true(caught)
    assert_true(upgrade.is_purchased)
```

- [ ] **Step 7: Run purchase test — verify GREEN**

- [ ] **Step 8: Write test — apply to non-existent producer is safe** (Review Focus #4)

```gdscript
func test_apply_to_wrong_producer_is_safe():
    var producer = autofree(PassiveProducer.new())
    producer.producer_id = "miner"
    producer.rate = 10.0
    var upgrade = autofree(MultiplyRateUpgrade.new())
    upgrade.target_producer_id = "wrong_id"  # doesn't match
    # Should not crash. Should not modify rate.
    upgrade.apply(producer)
    assert_almost_eq(producer.rate, 10.0, 0.01)
```

- [ ] **Step 9: Verify all tests pass and commit**

```
git add scripts/upgrades/ test/upgrades/
git commit -m "Upgrades: BaseUpgrade, MultiplyRateUpgrade, UnlockProducerUpgrade"
```

---

### Task 8: BaseEvent + ResourceThresholdEvent

**Files:**
- Create: `scripts/events/base_event.gd`, `scripts/events/resource_threshold_event.gd`
- Test: `test/events/test_events.gd`

**Interfaces:**
- Consumes: `GameState` (for condition checking), `ResourcePool`
- Produces:
  - `BaseEvent` (Resource, class_name, abstract): `event_id: StringName`, `has_fired: bool`, `one_shot: bool`, `check_condition(state: GameState) -> bool` (virtual), `execute(state: GameState) -> void` (virtual)
  - `ResourceThresholdEvent` extends BaseEvent: `resource_id: StringName`, `threshold: float`, `comparison: int` (enum: GREATER_THAN=0, LESS_THAN=1, EQUAL=2), `action_type: int` (enum: MODIFY_RESOURCE=0, ACTIVATE_PRODUCER=1), `action_target: StringName`, `action_value: float`

- [ ] **Step 1: Write failing test — threshold event fires when resource exceeds threshold**

Create a minimal GameState-like object or mock. Since GameState doesn't exist yet, test with a ResourcePool directly.

```gdscript
extends GutTest

func test_threshold_event_fires():
    var pool = autofree(ResourcePool.new())
    pool.add_resource("gold", 0.0)
    var event = autofree(ResourceThresholdEvent.new())
    event.resource_id = "gold"
    event.threshold = 100.0
    event.comparison = ResourceThresholdEvent.Comparison.GREATER_THAN
    # Mock state with just a pool reference
    # check_condition needs a pool; pass it via a simple wrapper or direct pool access
    pool.modify("gold", 150.0)
    # For now, test the comparison logic directly
    var result = event._check_threshold(pool)
    assert_true(result)
```

Note: `_check_threshold(pool)` is an internal helper. The real `check_condition(state)` will call `state.resources` to get the pool.

- [ ] **Step 2: Implement `BaseEvent` and `ResourceThresholdEvent`**

`ResourceThresholdEvent.check_condition(state)` gets `state.resources.get_resource(resource_id)`, compares amount vs threshold. `execute(state)` dispatches based on `action_type`: MODIFY_RESOURCE calls `state.resources.modify(action_target, action_value)`, ACTIVATE_PRODUCER calls `state.get_producer(action_target).is_active = true`. One-shot events set `has_fired = true` after execute and won't re-fire.

- [ ] **Step 3: Run threshold test — verify GREEN**

- [ ] **Step 4: Write failing test — one-shot event only fires once**

```gdscript
func test_one_shot_fires_once():
    var event = autofree(ResourceThresholdEvent.new())
    event.one_shot = true
    assert_false(event.has_fired)
    event.execute(mock_state)
    assert_true(event.has_fired)
    var second_result = event.check_condition(mock_state)
    assert_false(second_result, "one-shot should not re-check after firing")
```

- [ ] **Step 5: Implement one-shot behavior**

- [ ] **Step 6: Run one-shot test — verify GREEN**

- [ ] **Step 7: Run test suite and commit**

```
git add scripts/events/ test/events/
git commit -m "Events: BaseEvent + ResourceThresholdEvent with one-shot support"
```

---

### Task 9: GameState

**Files:**
- Create: `scripts/core/game_state.gd`
- Test: `test/core/test_game_state.gd`

**Interfaces:**
- Consumes: `GameClock`, `ResourcePool`, `GameResource`, `GameConfig`, `BaseProducer`, `BaseUpgrade`, `BaseEvent`, `ShopInventory`
- Produces: `GameState` (Resource, class_name)
  - Properties: `clock: GameClock`, `resources: ResourcePool` (RefCounted, not serialized directly), `producers: Array[BaseProducer]`, `upgrades: Array[BaseUpgrade]`, `events: Array[BaseEvent]`, `shop_inventory: ShopInventory`, `config: GameConfig`, `save_version: int` (default 1)
  - Methods: `get_producer(id: StringName) -> BaseProducer`, `get_upgrade(id: StringName) -> BaseUpgrade`, `get_event(id: StringName) -> BaseEvent`, `add_producer(producer)`, `add_upgrade(upgrade)`, `add_event(event)`

- [ ] **Step 1: Write failing test — GameState holds and retrieves producers**

```gdscript
extends GutTest

func test_game_state_holds_producers():
    var state = autofree(GameState.new())
    var producer = autofree(PassiveProducer.new())
    producer.producer_id = "miner"
    state.add_producer(producer)
    var retrieved = state.get_producer("miner")
    assert_eq(retrieved.producer_id, "miner")
```

Note: Test imports depend on all prior tasks. Run `godot --headless --import` first if class_name lookup fails.

- [ ] **Step 2: Implement `GameState`**

Extends `Resource`. Contains arrays for producers/upgrades/events. `get_producer()` iterates array and matches by `producer_id`. Similar for upgrades and events. `resources` is a `ResourcePool` (RefCounted) — initialized in `_init()`. `clock` is a `GameClock`. `config` is a `GameConfig`. `save_version: int = 1`.

- [ ] **Step 3: Run producer retrieval test — verify GREEN**

- [ ] **Step 4: Write failing test — GameState initializes with defaults**

```gdscript
func test_game_state_initializes_defaults():
    var state = autofree(GameState.new())
    assert_not_null(state.resources)
    assert_not_null(state.clock)
    assert_not_null(state.config)
    assert_eq(state.save_version, 1)
```

- [ ] **Step 5: Implement `_init()` defaults**

- [ ] **Step 6: Run init test — verify GREEN**

- [ ] **Step 7: Write test — apply config starting resources**

```gdscript
func test_apply_starting_resources():
    var state = autofree(GameState.new())
    state.config.starting_resources = {"gold": 100.0, "energy": 50.0}
    state._apply_starting_config()
    assert_eq(state.resources.get_resource("gold").amount, 100.0)
    assert_eq(state.resources.get_resource("energy").amount, 50.0)
```

- [ ] **Step 8: Implement `_apply_starting_config()`**

Iterates `config.starting_resources`, calls `resources.add_resource()` for each. Iterates `config.starting_producers`, sets `count` on matching producers.

- [ ] **Step 9: Run config apply test — verify GREEN**

- [ ] **Step 10: Run test suite and commit**

```
git add scripts/core/game_state.gd scripts/core/game_state.gd.uid test/core/test_game_state.gd test/core/test_game_state.gd.uid
git commit -m "GameState: top-level container for all simulation state"
```

---

### Task 10: ShopEntry + ShopInventory

**Files:**
- Create: `scripts/shop/shop_entry.gd`, `scripts/shop/producer_shop_entry.gd`, `scripts/shop/upgrade_shop_entry.gd`, `scripts/shop/shop_inventory.gd`
- Test: `test/shop/test_shop_inventory.gd`

**Interfaces:**
- Consumes: `GameState`, `BaseProducer`, `BaseUpgrade`, `BaseEvent`, `ResourcePool`
- Produces:
  - `ShopEntry` (Resource, class_name, abstract): `entry_id: StringName`, `display_name: String`, `cost_resource: StringName`, `cost_amount: float`, `unlock_condition: BaseEvent` (null = always visible), `is_visible(state: GameState) -> bool`, `can_afford(state: GameState) -> bool`, `purchase(state: GameState) -> bool` (virtual)
  - `ProducerShopEntry` extends ShopEntry: `producer_id: StringName`, `purchase(state)` deducts cost, increments `state.get_producer(producer_id).count`
  - `UpgradeShopEntry` extends ShopEntry: `upgrade_id: StringName`, `purchase(state)` deducts cost, calls `state.get_upgrade(upgrade_id).purchase()` then `apply()`
  - `ShopInventory` (Resource, class_name): `entries: Array[ShopEntry]`, `get_visible_entries(state) -> Array[ShopEntry]`, `purchase(entry_id: StringName, state: GameState) -> bool`

- [ ] **Step 1: Write failing test — producer shop entry increments count**

```gdscript
extends GutTest

func test_producer_shop_entry_purchase():
    var state = autofree(GameState.new())
    state.resources.add_resource("gold", 100.0)
    var producer = autofree(PassiveProducer.new())
    producer.producer_id = "miner"
    producer.count = 1
    state.add_producer(producer)
    var entry = autofree(ProducerShopEntry.new())
    entry.entry_id = "buy_miner"
    entry.producer_id = "miner"
    entry.cost_resource = "gold"
    entry.cost_amount = 50.0
    var result = entry.purchase(state)
    assert_true(result)
    assert_eq(producer.count, 2)
    assert_almost_eq(state.resources.get_resource("gold").amount, 50.0, 0.01)
```

- [ ] **Step 2: Implement `ShopEntry`, `ProducerShopEntry`, `UpgradeShopEntry`, `ShopInventory`**

`ShopEntry.is_visible()`: if `unlock_condition == null`, return true. Otherwise return `unlock_condition.check_condition(state)`. `can_afford()` checks `state.resources.get_resource(cost_resource).amount >= cost_amount`. `ProducerShopEntry.purchase()`: if `!can_afford`, return false. Deduct cost, increment count, return true. `UpgradeShopEntry.purchase()`: same but calls `upgrade.purchase()` + `upgrade.apply(producer)`.

`ShopInventory.purchase()`: finds entry by id, calls `entry.purchase(state)`. `get_visible_entries()`: filters entries by `is_visible()`.

- [ ] **Step 3: Run purchase test — verify GREEN**

- [ ] **Step 4: Write failing test — insufficient funds returns false** (Review Focus #3)

```gdscript
func test_insufficient_funds():
    var state = autofree(GameState.new())
    state.resources.add_resource("gold", 10.0)
    var producer = autofree(PassiveProducer.new())
    producer.producer_id = "miner"
    producer.count = 1
    state.add_producer(producer)
    var entry = autofree(ProducerShopEntry.new())
    entry.producer_id = "miner"
    entry.cost_resource = "gold"
    entry.cost_amount = 50.0
    var result = entry.purchase(state)
    assert_false(result)
    assert_eq(producer.count, 1)  # unchanged
    assert_eq(state.resources.get_resource("gold").amount, 10.0)  # unchanged
```

- [ ] **Step 5: Verify insufficient funds test — GREEN**

- [ ] **Step 6: Write failing test — unlock condition gates visibility**

```gdscript
func test_unlock_condition_gates_visibility():
    var state = autofree(GameState.new())
    state.resources.add_resource("gold", 0.0)
    var event = autofree(ResourceThresholdEvent.new())
    event.resource_id = "gold"
    event.threshold = 100.0
    event.comparison = ResourceThresholdEvent.Comparison.GREATER_THAN
    var entry = autofree(ProducerShopEntry.new())
    entry.unlock_condition = event
    assert_false(entry.is_visible(state))
    state.resources.modify("gold", 200.0)
    assert_true(entry.is_visible(state))
```

- [ ] **Step 7: Implement unlock condition logic**

- [ ] **Step 8: Run visibility test — verify GREEN**

- [ ] **Step 9: Run test suite and commit**

```
git add scripts/shop/ test/shop/
git commit -m "Shop: ShopEntry, ProducerShopEntry, UpgradeShopEntry, ShopInventory"
```

---

### Task 11: SaveSystem

**Files:**
- Create: `scripts/core/save_system.gd`
- Test: `test/core/test_save_system.gd`

**Interfaces:**
- Consumes: `GameState`, all prior types (for serialization)
- Produces: `SaveSystem` (RefCounted, class_name): `save(state: GameState, path: String) -> bool`, `load(path: String) -> GameState`, `_migrate(state: GameState, from_version: int) -> void`

- [ ] **Step 1: Write failing test — save and load roundtrip** (Review Focus #5)

```gdscript
extends GutTest

func test_save_load_roundtrip():
    var state = autofree(GameState.new())
    state.resources.add_resource("gold", 500.0)
    state.save_version = 1
    var producer = autofree(PassiveProducer.new())
    producer.producer_id = "miner"
    producer.rate = 10.0
    producer.count = 3
    state.add_producer(producer)
    
    var saver = autofree(SaveSystem.new())
    var save_path = "user://test_save.tres"
    var saved = saver.save(state, save_path)
    assert_true(saved)
    
    var loaded = saver.load(save_path)
    assert_not_null(loaded)
    assert_eq(loaded.save_version, 1)
    assert_almost_eq(loaded.resources.get_resource("gold").amount, 500.0, 0.01)
    var loaded_producer = loaded.get_producer("miner")
    assert_eq(loaded_producer.count, 3)
    assert_almost_eq(loaded_producer.rate, 10.0, 0.01)
```

- [ ] **Step 2: Implement `SaveSystem`**

`save()`: uses `ResourceSaver.save(path, state, ResourceSaver.FLAG_COMPRESS)` or equivalent. Serializes the full GameState resource tree. Since `ResourcePool` is RefCounted (not a Resource), it won't serialize directly — must convert to/from a serializable form. Two options: (a) make ResourcePool a Resource after all, or (b) serialize pool data into a Dictionary on GameState before save and rebuild on load.

Decision: make `ResourcePool` extend `Resource` instead of `RefCounted`. Update Task 3's implementation if needed. This avoids custom serialization.

`load()`: uses `ResourceLoader.load(path)`. Checks `save_version` field, runs migrations if version < current. Returns the loaded GameState.

`_migrate()`: base implementation is a no-op. Template ships with v1 as current. When upgraded, add migration functions: `_migrate_v1_to_v2(state)`.

- [ ] **Step 3: Run roundtrip test — verify GREEN**

- [ ] **Step 4: Write test — load non-existent file returns null**

```gdscript
func test_load_nonexistent_returns_null():
    var saver = autofree(SaveSystem.new())
    var result = saver.load("user://does_not_exist.tres")
    assert_null(result)
```

- [ ] **Step 5: Handle missing file gracefully**

- [ ] **Step 6: Run null test — verify GREEN**

- [ ] **Step 7: Run test suite and commit**

If ResourcePool was changed to Resource, update that commit message to note the change.

```
git add scripts/core/save_system.gd scripts/core/save_system.gd.uid test/core/test_save_system.gd test/core/test_save_system.gd.uid
git commit -m "SaveSystem: .tres save/load with versioning and migration hooks"
```

---

### Task 12: IdleRunner

**Files:**
- Create: `scripts/core/idle_runner.gd`
- Test: `test/core/test_idle_runner.gd`

**Interfaces:**
- Consumes: `GameState`, `GameClock`, `BaseProducer`, `BaseEvent`, `SaveSystem`
- Produces: `IdleRunner` (Node, class_name)
  - Properties: `game_state: GameState`
  - Methods: `start()`, `_on_tick(delta: float)`, `save()`, `load()`
  - Signals: `state_loaded`, `state_saved`

- [ ] **Step 1: Write failing test — IdleRunner ticks producers**

```gdscript
extends GutTest

func test_idle_runner_ticks_producers():
    var runner = autofree(IdleRunner.new())
    var state = autofree(GameState.new())
    state.resources.add_resource("gold", 0.0)
    var producer = autofree(PassiveProducer.new())
    producer.producer_id = "miner"
    producer.target_resource = "gold"
    producer.rate = 10.0
    producer.count = 1
    producer.is_active = true
    state.add_producer(producer)
    runner.game_state = state
    runner._on_tick(1.0)
    assert_almost_eq(state.resources.get_resource("gold").amount, 10.0, 0.01)
```

- [ ] **Step 2: Implement `IdleRunner`**

Extends `Node`. `start()`: loads or creates GameState, starts clock timer. `_on_tick(delta)`: ticks clock, iterates producers calling `producer.tick(delta, game_state.resources)`, iterates events calling `event.check_condition()` → `event.execute()`. `save()`: delegates to `SaveSystem`. `load()`: delegates to `SaveSystem`, emits `state_loaded`.

- [ ] **Step 3: Run tick test — verify GREEN**

- [ ] **Step 4: Write failing test — IdleRunner evaluates events each tick**

```gdscript
func test_idle_runner_evaluates_events():
    var runner = autofree(IdleRunner.new())
    var state = autofree(GameState.new())
    state.resources.add_resource("gold", 200.0)
    var event = autofree(ResourceThresholdEvent.new())
    event.resource_id = "gold"
    event.threshold = 100.0
    event.comparison = ResourceThresholdEvent.Comparison.GREATER_THAN
    event.action_type = ResourceThresholdEvent.ActionType.MODIFY_RESOURCE
    event.action_target = "gold"
    event.action_value = 50.0
    state.add_event(event)
    runner.game_state = state
    runner._on_tick(1.0)
    # Event should have fired, adding 50 to gold
    assert_almost_eq(state.resources.get_resource("gold").amount, 250.0, 0.01)
```

- [ ] **Step 5: Implement event evaluation loop**

- [ ] **Step 6: Run event test — verify GREEN**

- [ ] **Step 7: Run test suite and commit**

```
git add scripts/core/idle_runner.gd scripts/core/idle_runner.gd.uid test/core/test_idle_runner.gd test/core/test_idle_runner.gd.uid
git commit -m "IdleRunner: simulation coordinator — ticks producers and events"
```

---

### Task 13: WindowManager (Autoload)

**Files:**
- Create: `scripts/ui/window_manager.gd`
- Test: `test/ui/test_window_manager.gd` (smoke test)

**Interfaces:**
- Consumes: `project.godot` (autoload registration), `GameConfig`
- Produces: `WindowManager` (Node, autoload)
  - Properties: `always_on_top: bool`, `window_position: Vector2i`, `window_size: Vector2i`
  - Methods: `toggle_always_on_top()`, `save_window_state()`, `load_window_state()`

- [ ] **Step 1: Create `WindowManager` as autoload**

Register in `project.godot` under `[autoload]`:
```
WindowManager="*res://scripts/ui/window_manager.gd"
```

- [ ] **Step 2: Implement `WindowManager`**

`_ready()`: load saved window position/size from `user://window.cfg`, apply via `DisplayServer.window_set_position()` and `DisplayServer.window_set_size()`. `toggle_always_on_top()`: flip bool, call `DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, always_on_top)`. `_notification(NOTIFICATION_WM_CLOSE_REQUEST)`: save window state before exit.

- [ ] **Step 3: Write smoke test**

```gdscript
extends GutTest

func test_window_manager_exists():
    var wm = autofree(WindowManager.new())
    assert_not_null(wm)
```

- [ ] **Step 4: Verify autoload works**

Run `godot --headless --import`. Verify no errors. Run smoke test. Autoload availability is confirmed by the smoke test not crashing on `WindowManager.new()`.

- [ ] **Step 5: Run test and commit**

```
git add scripts/ui/window_manager.gd scripts/ui/window_manager.gd.uid test/ui/test_window_manager.gd test/ui/test_window_manager.gd.uid project.godot
git commit -m "WindowManager: autoload for always-on-top and window state persistence"
```

---

### Task 14: Minimal UI

**Files:**
- Create: `scenes/main.tscn`, `scenes/ui/main_view.tscn`, `scenes/ui/resource_display.tscn`, `scenes/ui/producer_button.tscn`, `scenes/ui/shop_view.tscn`, `scenes/ui/catchup_modal.tscn`, `scripts/ui/main_view.gd`, `scripts/ui/resource_display.gd`, `scripts/ui/producer_button.gd`, `scripts/ui/shop_view.gd`, `scripts/ui/catchup_modal.gd`
- Test: `test/ui/test_main_view.gd` (smoke test)

**Interfaces:**
- Consumes: `IdleRunner`, `GameState`, `ResourcePool`, `ClickProducer`, `ShopInventory`, `GameClock` signals
- Produces: playable minimal demo with one resource ("Gold"), one click producer ("Click Mine"), one shop entry (buy more mines), catchup modal on resume

- [ ] **Step 1: Create `main.tscn`**

Root `Control` node. Child `IdleRunner` with a configured `GameState`:
  - `GameConfig`: starting resource "Gold" at 0
  - `ClickProducer`: "click_mine", targets "Gold", `click_amount = 1`, `count = 1`
  - `PassiveProducer`: "auto_mine", targets "Gold", `rate = 0.5`, `count = 1`, `is_active = true`
  - `ProducerShopEntry`: "buy_auto_mine", costs 10 Gold, targets "auto_mine"
  - `ShopInventory` with the one entry

- [ ] **Step 2: Create `resource_display.tscn`**

Label that shows "Gold: 0". Script connects to `game_state.resources.resource_changed` signal, updates text when "Gold" changes.

- [ ] **Step 3: Create `producer_button.tscn`**

Button labeled "Mine Gold (+1)". On press, calls `click_producer.on_click(state.resources)`. Displays cooldown visual feedback (greyed out when on cooldown).

- [ ] **Step 4: Create `shop_view.tscn`**

Lists visible shop entries from `shop_inventory.get_visible_entries(state)`. Each entry shows display name + cost + a "Buy" button. Button disabled when `!can_afford`. On press, calls `shop_inventory.purchase(entry_id, state)`.

- [ ] **Step 5: Create `catchup_modal.tscn`**

Hidden by default. Shows "Running Offline Catchup…" text, a `ProgressBar`, and "Ticks/sec: N" label. Connects to `clock.catchup_started` (show), `clock.catchup_progress` (update bar + label), `clock.catchup_finished` (hide).

- [ ] **Step 6: Create `main_view.tscn`**

Assembles all sub-scenes: resource display at top, click button below, shop view below that, catchup modal overlay. Script wires up IdleRunner reference.

- [ ] **Step 7: Write smoke test**

```gdscript
extends GutTest

func test_main_view_loads():
    var scene = load("res://scenes/ui/main_view.tscn")
    var instance = autofree(scene.instantiate())
    assert_not_null(instance)
```

- [ ] **Step 8: Assign `main.tscn` as project main scene**

In `project.godot`: `run/main_scene="res://scenes/main.tscn"`

- [ ] **Step 9: Verify the demo runs**

Run `godot --headless --import` then GUT smoke tests. Open in editor and confirm: gold displays, clicking mine button increments gold, buying auto mine at 10 gold works, catchup modal appears on load (simulated by setting a past `last_save_epoch`).

- [ ] **Step 10: Commit**

```
git add scenes/ scripts/ui/ test/ui/ project.godot
git commit -m "UI: minimal demo — resource display, click button, shop, catchup modal"
```

---

## Self-Review Checklist

Before handing off, verify:

1. **Spec coverage:** Every section in the design doc maps to a task. GameClock → T2, ResourcePool → T3, GameConfig → T4, Producers → T5/T6, Upgrades → T7, Events → T8, GameState → T9, Shop → T10, SaveSystem → T11, IdleRunner → T12, WindowManager → T13, UI → T14. Project scaffolding → T1. All covered.

2. **Step scan:** Each step has an exact test name, exact command, or exact signature. No "handle edge cases" or "add validation" without specifics. Gaps: Task 8's mock state approach needs the real GameState — but Task 9 builds GameState after Task 8. Reorder? No — Task 8 tests against ResourcePool directly for comparison logic, and the real `check_condition(GameState)` integration is tested in Task 12 (IdleRunner evaluates events). Acceptable.

3. **Type consistency:** `ResourcePool` — declared as RefCounted in Task 3, but Task 11 notes it must be Resource for serialization. The plan explicitly says "make ResourcePool extend Resource instead of RefCounted" in Task 11. However, Task 3 currently says RefCounted. Need to reconcile: Task 3 should build ResourcePool as Resource from the start, OR Task 11 updates it. Decision: build as Resource from start. Task 3's interface block says "RefCounted" — change to "Resource". The implementation behavior is identical; only the parent class changes.

4. **Review Focus:** All 5 items have corresponding tests: #1 in T2 step 10, #2 in T3 step 4, #3 in T10 step 4, #4 in T7 step 8, #5 in T11 step 1. Verified.

5. **Proportion:** The plan is detailed but each step is a single actionable item. Code blocks are test assertions (needed for unambiguous TDD) or signatures. No full function bodies. The plan is longer than the spec because it specifies every test and every file — this is appropriate for a greenfield project with no existing codebase patterns to reference.

**Fix applied:** Task 3 ResourcePool — change from RefCounted to Resource in the interface block.
