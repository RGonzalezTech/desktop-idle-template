extends GutTest


func test_idle_runner_ticks_producers() -> void:
	var runner: IdleRunner = autofree(IdleRunner.new())
	var state: GameState = autofree(GameState.new())
	state.resources.add_resource("gold", 0.0)

	var miner: PassiveProducer = autofree(PassiveProducer.new())
	miner.producer_id = "miner"
	miner.target_resource = "gold"
	miner.rate = 10.0
	miner.count = 1
	miner.is_active = true
	state.add_producer(miner)

	runner.game_state = state
	runner._on_tick(1.0)

	assert_eq(state.resources.get_resource("gold").amount, 10.0)


func test_idle_runner_skips_inactive_producers() -> void:
	var runner: IdleRunner = autofree(IdleRunner.new())
	var state: GameState = autofree(GameState.new())
	state.resources.add_resource("gold", 0.0)

	var miner: PassiveProducer = autofree(PassiveProducer.new())
	miner.producer_id = "miner"
	miner.target_resource = "gold"
	miner.rate = 10.0
	miner.count = 1
	miner.is_active = false
	state.add_producer(miner)

	runner.game_state = state
	runner._on_tick(1.0)

	assert_eq(state.resources.get_resource("gold").amount, 0.0)


func test_idle_runner_evaluates_events() -> void:
	var runner: IdleRunner = autofree(IdleRunner.new())
	var state: GameState = autofree(GameState.new())
	state.resources.add_resource("gold", 200.0)

	var event: ResourceThresholdEvent = autofree(ResourceThresholdEvent.new())
	event.resource_id = "gold"
	event.threshold = 100.0
	event.comparison = ResourceThresholdEvent.Comparison.GREATER_THAN
	event.action_type = ResourceThresholdEvent.ActionType.MODIFY_RESOURCE
	event.action_target = "gold"
	event.action_value = 50.0
	state.add_event(event)

	runner.game_state = state
	runner._on_tick(1.0)

	assert_eq(state.resources.get_resource("gold").amount, 250.0)
