extends GutTest


class TestProducerShopEntry:
	extends GutTest

	var _state: GameState
	var _producer: PassiveProducer

	func before_each() -> void:
		_state = autofree(GameState.new())
		_state.resources.add_resource("gold", 100.0)
		_producer = autofree(PassiveProducer.new())
		_producer.producer_id = "miner"
		_producer.count = 1
		_producer.rate = 10.0
		_state.add_producer(_producer)

	func test_producer_shop_entry_purchase() -> void:
		var entry: ProducerShopEntry = autofree(ProducerShopEntry.new())
		entry.producer_id = "miner"
		entry.cost_resource = "gold"
		entry.cost_amount = 50.0
		var result: bool = entry.purchase(_state)
		assert_true(result)
		assert_eq(_producer.count, 2)
		assert_eq(_state.resources.get_resource("gold").amount, 50.0)

	func test_insufficient_funds() -> void:
		_state.resources.modify("gold", -90.0)  # gold = 10
		var entry: ProducerShopEntry = autofree(ProducerShopEntry.new())
		entry.producer_id = "miner"
		entry.cost_resource = "gold"
		entry.cost_amount = 50.0
		var result: bool = entry.purchase(_state)
		assert_false(result)
		assert_eq(_producer.count, 1)
		assert_eq(_state.resources.get_resource("gold").amount, 10.0)


class TestVisibility:
	extends GutTest

	var _state: GameState
	var _entry: ShopEntry
	var _condition: ResourceThresholdEvent

	func before_each() -> void:
		_state = autofree(GameState.new())
		_state.resources.add_resource("gold", 0.0)
		_entry = autofree(ShopEntry.new())
		_entry.cost_resource = "gold"
		_entry.cost_amount = 10.0
		_condition = autofree(ResourceThresholdEvent.new())
		_condition.resource_id = "gold"
		_condition.threshold = 100.0
		_condition.comparison = ResourceThresholdEvent.Comparison.GREATER_THAN
		_entry.unlock_condition = _condition

	func test_unlock_condition_gates_visibility() -> void:
		# Before meeting condition, not visible.
		assert_false(_entry.is_visible(_state))
		# Add enough gold to meet threshold.
		_state.resources.modify("gold", 200.0)
		# Now gold=200 > 100, should be visible.
		assert_true(_entry.is_visible(_state))

	func test_always_visible_when_no_condition() -> void:
		_entry.unlock_condition = null
		assert_true(_entry.is_visible(_state))


class TestUpgradeShopEntry:
	extends GutTest

	var _state: GameState
	var _producer: PassiveProducer
	var _upgrade: MultiplyRateUpgrade

	func before_each() -> void:
		_state = autofree(GameState.new())
		_state.resources.add_resource("gold", 100.0)
		_producer = autofree(PassiveProducer.new())
		_producer.producer_id = "miner"
		_producer.count = 1
		_producer.rate = 10.0
		_state.add_producer(_producer)
		_upgrade = autofree(MultiplyRateUpgrade.new())
		_upgrade.upgrade_id = "double_rate"
		_upgrade.target_producer_id = "miner"
		_upgrade.multiplier = 2.0
		_state.add_upgrade(_upgrade)

	func test_upgrade_shop_entry_purchase() -> void:
		var entry: UpgradeShopEntry = autofree(UpgradeShopEntry.new())
		entry.upgrade_id = "double_rate"
		entry.cost_resource = "gold"
		entry.cost_amount = 50.0
		var result: bool = entry.purchase(_state)
		assert_true(result)
		assert_true(_upgrade.is_purchased)
		assert_eq(_producer.rate, 20.0)
		assert_eq(_state.resources.get_resource("gold").amount, 50.0)

	func test_upgrade_entry_insufficient_funds() -> void:
		_state.resources.modify("gold", -90.0)  # gold = 10
		var entry: UpgradeShopEntry = autofree(UpgradeShopEntry.new())
		entry.upgrade_id = "double_rate"
		entry.cost_resource = "gold"
		entry.cost_amount = 50.0
		var result: bool = entry.purchase(_state)
		assert_false(result)
		assert_false(_upgrade.is_purchased)
		assert_eq(_producer.rate, 10.0)
		assert_eq(_state.resources.get_resource("gold").amount, 10.0)


class TestShopInventory:
	extends GutTest

	var _state: GameState
	var _inventory: ShopInventory
	var _entry: ProducerShopEntry

	func before_each() -> void:
		_state = autofree(GameState.new())
		_state.resources.add_resource("gold", 100.0)
		var producer: PassiveProducer = autofree(PassiveProducer.new())
		producer.producer_id = "miner"
		producer.count = 1
		producer.rate = 10.0
		_state.add_producer(producer)
		_entry = autofree(ProducerShopEntry.new())
		_entry.entry_id = "buy_miner"
		_entry.producer_id = "miner"
		_entry.cost_resource = "gold"
		_entry.cost_amount = 50.0
		_inventory = autofree(ShopInventory.new())
		_inventory.entries = [_entry]

	func test_shop_inventory_purchase() -> void:
		var result: bool = _inventory.purchase("buy_miner", _state)
		assert_true(result)
		assert_eq(_state.get_producer("miner").count, 2)

	func test_shop_inventory_get_visible_entries() -> void:
		var hidden_entry: ProducerShopEntry = autofree(ProducerShopEntry.new())
		hidden_entry.entry_id = "hidden_one"
		hidden_entry.producer_id = "miner"
		hidden_entry.cost_resource = "gold"
		hidden_entry.cost_amount = 999.0
		var condition: ResourceThresholdEvent = autofree(ResourceThresholdEvent.new())
		condition.resource_id = "gold"
		condition.threshold = 1000.0
		condition.comparison = ResourceThresholdEvent.Comparison.GREATER_THAN
		hidden_entry.unlock_condition = condition
		_inventory.entries.append(hidden_entry)
		var visible: Array = _inventory.get_visible_entries(_state)
		assert_eq(visible.size(), 1)
		assert_eq(visible[0].entry_id, "buy_miner")
