extends GutTest


func test_threshold_event_fires() -> void:
	var pool = autofree(ResourcePool.new())
	pool.add_resource("gold", 0.0)
	var event = autofree(ResourceThresholdEvent.new())
	event.resource_id = "gold"
	event.threshold = 100.0
	event.comparison = ResourceThresholdEvent.Comparison.GREATER_THAN
	pool.modify("gold", 150.0)
	var result = event._check_threshold(pool)
	assert_true(result)


func test_one_shot_fires_once() -> void:
	var state = autofree(GameState.new())
	state.resources.add_resource("gold", 0.0)
	var event = autofree(ResourceThresholdEvent.new())
	event.one_shot = true
	event.resource_id = "gold"
	event.threshold = 100.0
	event.comparison = ResourceThresholdEvent.Comparison.GREATER_THAN
	event.action_type = ResourceThresholdEvent.ActionType.MODIFY_RESOURCE
	event.action_target = "gold"
	event.action_value = 50.0
	state.resources.modify("gold", 150.0)
	assert_false(event.has_fired)
	event.execute(state)
	assert_true(event.has_fired)
	var second_result = event.check_condition(state)
	assert_false(second_result, "one-shot should not re-check after firing")
