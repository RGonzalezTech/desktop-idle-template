extends GutTest

# Minimal mock state for testing execute() without full GameState (T9)
class MockState:
	var resources: ResourcePool
	var _producers: Dictionary = {}

	func _init(pool: ResourcePool) -> void:
		resources = pool

	func get_producer(id: StringName):
		return _producers.get(id, null)

	func set_producer(id: StringName, producer) -> void:
		_producers[id] = producer


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
	var pool = autofree(ResourcePool.new())
	pool.add_resource("gold", 0.0)
	var mock_state = MockState.new(pool)
	var event = autofree(ResourceThresholdEvent.new())
	event.one_shot = true
	event.resource_id = "gold"
	event.threshold = 100.0
	event.comparison = ResourceThresholdEvent.Comparison.GREATER_THAN
	event.action_type = ResourceThresholdEvent.ActionType.MODIFY_RESOURCE
	event.action_target = "gold"
	event.action_value = 50.0
	pool.modify("gold", 150.0)
	assert_false(event.has_fired)
	event.execute(mock_state)
	assert_true(event.has_fired)
	var second_result = event.check_condition(mock_state)
	assert_false(second_result, "one-shot should not re-check after firing")
