extends GutTest

func test_passive_producer_generates() -> void:
	var pool = autofree(ResourcePool.new())
	pool.add_resource("gold", 0.0)
	var producer = autofree(PassiveProducer.new())
	producer.producer_id = "gold_miner"
	producer.target_resource = "gold"
	producer.rate = 10.0
	producer.count = 2
	producer.is_active = true
	var produced = producer.tick(1.0, pool)
	assert_almost_eq(produced, 20.0, 0.01)
	assert_almost_eq(pool.get_resource("gold").amount, 20.0, 0.01)


func test_inactive_producer_zero() -> void:
	var pool = autofree(ResourcePool.new())
	pool.add_resource("gold", 0.0)
	var producer = autofree(PassiveProducer.new())
	producer.target_resource = "gold"
	producer.rate = 10.0
	producer.count = 1
	producer.is_active = false
	var produced = producer.tick(1.0, pool)
	assert_eq(produced, 0.0)
	assert_eq(pool.get_resource("gold").amount, 0.0)
