# Desktop Idle Template 🎮

A genre-agnostic Godot 4.4 starter kit for building idle/incremental games. Ships with a data-driven simulation loop, shop/sim split architecture, offline catchup, and GUT testing pre-configured.

[![Godot Version](https://img.shields.io/badge/Godot-4.4-%23478cbf?logo=godot-engine&logoColor=white&style=for-the-badge)](https://godotengine.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

## 🚀 Key Features

- **Data-Driven Simulation**: Producers, upgrades, and events are defined as data resources — add new game content without touching engine code
- **Shop/Sim Split**: The simulation loop ticks independently from the shop UI. The shop reads state via a clean API and writes back through validated commands
- **Offline Catchup**: The simulation catches up on missed ticks when the game was closed. Multiplies base production by elapsed time, not delta
- **1Hz Tick Rate**: Everything updates once per second. No sub-second drift, no variable timestep headaches
- **Click API**: Clicks are routed through a central `ClickHandler`. UI elements register interest — clean, testable, decoupled
- **Testing Ready**: Pre-configured with [GUT](https://gut.readthedocs.io/en/v9.5.0/) for unit and integration testing

## 📂 Project Structure

- `addons/`: Third-party tools (GUT)
- `assets/`: Sprites, sounds, and data resources
- `scenes/ui/`: UI scenes (shop panels, click areas, resource displays)
- `scripts/`: The brains
  - `core/`: Simulation loop, offline catchup, game state
  - `producers/`: Resource generators (per tick)
  - `upgrades/`: Producer multipliers and unlocks
  - `events/`: One-shot and recurring game events
  - `shop/`: Purchase validation, cost checking, transaction commands
  - `ui/`: UI controllers and widgets
- `test/`: Unit and integration tests, mirroring `scripts/`

## 🛠️ Getting Started

1. **Clone or Fork**: This repo is designed as a template — clone it to start a new idle game
2. **Open in Godot**: Open the project in **Godot 4.4** or later
3. **Run Tests**: `godot --headless --rendering-driver opengl3 -s addons/gut/gut_cmdln.gd -gconfig=res://gutconfig.json -gdir=res://test`

## Philosophy

**Simple over Complex.** This template avoids monolithic managers in favor of small, focused components. If a script does more than one thing, it's probably doing too much. Genre-agnostic means no hardcoded theme — the simulation doesn't care if you're baking cookies or conquering galaxies.

See [CONTRIBUTING.md](CONTRIBUTING.md) for more information.

Enjoy!
