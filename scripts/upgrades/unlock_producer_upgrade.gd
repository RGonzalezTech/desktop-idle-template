class_name UnlockProducerUpgrade
extends BaseUpgrade

## Upgrade that unlocks (activates) a producer.
## apply(producer) sets producer.is_active = true when unlocks_producer_id matches.

@export var unlocks_producer_id: StringName = &""


func apply(producer: BaseProducer) -> void:
	if producer.producer_id != target_producer_id:
		return
	producer.is_active = true
