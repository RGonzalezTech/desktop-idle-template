class_name UpgradeShopEntry
extends ShopEntry

## Shop entry that purchases an upgrade and applies it to its target producer.

@export var upgrade_id: StringName = &""


func purchase(state: GameState) -> bool:
	if not can_afford(state):
		return false
	state.resources.modify(cost_resource, -cost_amount)
	var upgrade: BaseUpgrade = state.get_upgrade(upgrade_id)
	if upgrade == null:
		return false
	upgrade.purchase()
	var producer: BaseProducer = state.get_producer(upgrade.target_producer_id)
	if producer != null:
		upgrade.apply(producer)
	return true
