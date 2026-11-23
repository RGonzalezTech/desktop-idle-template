class_name GameConfig
extends Resource

## Template-wide configuration Resource.
## Holds window dimensions, tick settings, and starting state defaults.

@export var window_width: int = 400

@export var window_height: int = 600

@export var tick_rate: float = 1.0

@export var catchup_ticks_per_second: float = 60.0

@export var starting_resources: Dictionary = {}

@export var starting_producers: Dictionary = {}
