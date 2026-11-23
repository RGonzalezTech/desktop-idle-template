class_name GameResource
extends Resource

## A named numeric resource with min/max clamping and change tracking.
## Backbone data type for all game resources (gold, energy, etc.).

signal amount_changed(new_amount: float, delta: float)

@export var resource_id: StringName = &""

@export var amount: float = 0.0:
	set(value):
		var delta: float = value - amount
		amount = value
		if delta != 0.0:
			amount_changed.emit(value, delta)

@export var min_value: float = 0.0

@export var max_value: float = INF

@export var display_name: String = ""
