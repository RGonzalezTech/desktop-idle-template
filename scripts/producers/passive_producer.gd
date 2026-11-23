class_name PassiveProducer
extends BaseProducer

## Producer that generates resources at a constant rate per instance.
## Output = rate * count * delta.

@export var rate: float = 0.0


func _calculate_output(delta: float) -> float:
	return rate * count * delta
