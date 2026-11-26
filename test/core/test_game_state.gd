extends GutTest


func test_game_state_holds_producers() -> void:
	var state = autofree(GameState.new())
	var producer = autofree(PassiveProducer.new())
	producer.producer_id = "miner"
	state.add_producer(producer)
	var retrieved = state.get_producer("miner")
	assert_eq(retrieved.producer_id, "miner")


func test_game_state_get_producer_missing() -> void:
	var state = autofree(GameState.new())
	assert_null(state.get_producer("nonexistent"))


func test_game_state_holds_upgrades() -> void:
	var state = autofree(GameState.new())
	var upgrade = autofree(MultiplyRateUpgrade.new())
	upgrade.upgrade_id = "double_rate"
	state.add_upgrade(upgrade)
	var retrieved = state.get_upgrade("double_rate")
	assert_eq(retrieved.upgrade_id, "double_rate")


func test_game_state_get_upgrade_missing() -> void:
	var state = autofree(GameState.new())
	assert_null(state.get_upgrade("nonexistent"))


func test_game_state_holds_events() -> void:
	var state = autofree(GameState.new())
	var event = autofree(ResourceThresholdEvent.new())
	event.event_id = "gold_rush"
	state.add_event(event)
	var retrieved = state.get_event("gold_rush")
	assert_eq(retrieved.event_id, "gold_rush")


func test_game_state_get_event_missing() -> void:
	var state = autofree(GameState.new())
	assert_null(state.get_event("nonexistent"))


func test_game_state_initializes_defaults() -> void:
	var state = autofree(GameState.new())
	assert_not_null(state.resources)
	assert_not_null(state.clock)
	assert_not_null(state.config)
	assert_eq(state.save_version, 1)
	assert_eq(state.producers.size(), 0)
	assert_eq(state.upgrades.size(), 0)
	assert_eq(state.events.size(), 0)


func test_apply_starting_resources() -> void:
	var state = autofree(GameState.new())
	state.config.starting_resources = {"gold": 100.0, "energy": 50.0}
	state._apply_starting_config()
	assert_eq(state.resources.get_resource("gold").amount, 100.0)
	assert_eq(state.resources.get_resource("energy").amount, 50.0)
