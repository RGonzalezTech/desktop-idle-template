class_name BaseProducer
extends Resource

## Abstract producer base class.
## Owns resource generation logic: tick() calls _calculate_output(),
## applies it to the pool, emits produced signal, returns the amount.

signal produced(resource_id: StringName, amount: float)

@export var producer_id: StringName = &""

@export var target_resource: StringName = &""

@export var is_active: bool = true

@export var count: int = 1


func _calculate_output(_delta: float) -> float:
	# Override in subclasses. Default: zero output.
	return 0.0


func tick(delta: float, pool: ResourcePool) -> float:
	if not is_active:
		return 0.0
	var output := _calculate_output(delta)
	pool.modify(target_resource, output)
	if output != 0.0:
		produced.emit(target_resource, output)
	return output
