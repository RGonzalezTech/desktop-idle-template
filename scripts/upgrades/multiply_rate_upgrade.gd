class_name MultiplyRateUpgrade
extends BaseUpgrade

## Upgrade that multiplies a producer's rate.
## apply(producer) sets producer.rate *= multiplier when producer_id matches.

@export var multiplier: float = 1.0


func apply(producer: BaseProducer) -> void:
	if producer.producer_id != target_producer_id:
		return
	producer.rate *= multiplier
