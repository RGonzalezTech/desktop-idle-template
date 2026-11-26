class_name ProducerShopEntry
extends ShopEntry

## Shop entry that increments a producer's count when purchased.

@export var producer_id: StringName = &""


func purchase(state: GameState) -> bool:
	if not can_afford(state):
		return false
	# Increment count BEFORE modify so the UI sees the new count
	# when resource_changed triggers _refresh().
	var producer: BaseProducer = state.get_producer(producer_id)
	if producer == null:
		return false
	producer.count += 1
	state.resources.modify(cost_resource, -cost_amount)
	return true
