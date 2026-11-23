extends GutTest

const MultiplyRateUpgrade = preload("res://scripts/upgrades/multiply_rate_upgrade.gd")
const UnlockProducerUpgrade = preload("res://scripts/upgrades/unlock_producer_upgrade.gd")

func test_multiply_rate_upgrade() -> void:
	var producer = autofree(PassiveProducer.new())
	producer.rate = 10.0
	var upgrade = autofree(MultiplyRateUpgrade.new())
	upgrade.target_producer_id = "miner"
	upgrade.multiplier = 2.0
	producer.producer_id = "miner"
	upgrade.apply(producer)
	assert_almost_eq(producer.rate, 20.0, 0.01)


func test_unlock_upgrade_activates_producer() -> void:
	var producer = autofree(PassiveProducer.new())
	producer.is_active = false
	producer.producer_id = "miner"
	var upgrade = autofree(UnlockProducerUpgrade.new())
	upgrade.unlocks_producer_id = "miner"
	upgrade.target_producer_id = "miner"
	upgrade.apply(producer)
	assert_true(producer.is_active)


func test_upgrade_purchase_emits_signal() -> void:
	var upgrade = autofree(MultiplyRateUpgrade.new())
	upgrade.upgrade_id = "double_rate"
	var caught := [false]  # array wrapper: GDScript closures capture primitives by value
	upgrade.purchased.connect(func(_id): caught[0] = true)
	upgrade.purchase()
	assert_true(caught[0])
	assert_true(upgrade.is_purchased)


func test_apply_to_wrong_producer_is_safe() -> void:
	var producer = autofree(PassiveProducer.new())
	producer.producer_id = "miner"
	producer.rate = 10.0
	var upgrade = autofree(MultiplyRateUpgrade.new())
	upgrade.target_producer_id = "wrong_id"  # doesn't match
	# Should not crash. Should not modify rate.
	upgrade.apply(producer)
	assert_almost_eq(producer.rate, 10.0, 0.01)


func test_multiply_rate_stacks() -> void:
	var producer = autofree(PassiveProducer.new())
	producer.producer_id = "miner"
	producer.rate = 10.0
	var upgrade1 = autofree(MultiplyRateUpgrade.new())
	upgrade1.target_producer_id = "miner"
	upgrade1.multiplier = 2.0
	var upgrade2 = autofree(MultiplyRateUpgrade.new())
	upgrade2.target_producer_id = "miner"
	upgrade2.multiplier = 3.0
	upgrade1.apply(producer)
	upgrade2.apply(producer)
	assert_almost_eq(producer.rate, 60.0, 0.01)


