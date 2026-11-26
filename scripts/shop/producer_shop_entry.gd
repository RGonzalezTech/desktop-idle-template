class_name ProducerShopEntry
extends ShopEntry

## Shop entry that increments a producer's count when purchased.

@export var producer_id: StringName = &""


func purchase(state: GameState) -> bool:
	if not can_afford(state):
		return false
	state.resources.modify(cost_resource, -cost_amount)
	var producer: BaseProducer = state.get_producer(producer_id)
	if producer == null:
		return false
	producer.count += 1
	return true
