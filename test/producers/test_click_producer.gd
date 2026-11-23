extends GutTest

func test_click_produces() -> void:
	var pool = autofree(ResourcePool.new())
	pool.add_resource("gold", 0.0)
	var producer = autofree(ClickProducer.new())
	producer.target_resource = "gold"
	producer.click_amount = 5.0
	producer.count = 3
	var result = producer.on_click(pool)
	assert_almost_eq(result, 15.0, 0.01)
	assert_almost_eq(pool.get_resource("gold").amount, 15.0, 0.01)


func test_cooldown_blocks_rapid_clicks() -> void:
	var pool = autofree(ResourcePool.new())
	pool.add_resource("gold", 0.0)
	var producer = autofree(ClickProducer.new())
	producer.target_resource = "gold"
	producer.click_amount = 10.0
	producer.count = 1
	producer.cooldown = 999.0  # effectively blocks second click
	var first = producer.on_click(pool)
	assert_almost_eq(first, 10.0, 0.01)
	var second = producer.on_click(pool)
	assert_eq(second, 0.0)
	assert_almost_eq(pool.get_resource("gold").amount, 10.0, 0.01)


func test_inactive_click_returns_zero() -> void:
	var pool = autofree(ResourcePool.new())
	pool.add_resource("gold", 0.0)
	var producer = autofree(ClickProducer.new())
	producer.target_resource = "gold"
	producer.click_amount = 5.0
	producer.count = 3
	producer.is_active = false
	var result = producer.on_click(pool)
	assert_eq(result, 0.0)
	assert_almost_eq(pool.get_resource("gold").amount, 0.0, 0.01)
