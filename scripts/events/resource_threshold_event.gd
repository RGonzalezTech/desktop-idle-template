class_name ResourceThresholdEvent
extends BaseEvent

## Fires when a resource crosses a threshold (greater than, less than, equal).
## Actions: modify a resource or activate a producer.

enum Comparison { GREATER_THAN = 0, LESS_THAN = 1, EQUAL = 2 }
enum ActionType { MODIFY_RESOURCE = 0, ACTIVATE_PRODUCER = 1 }

@export var resource_id: StringName = &""

@export var threshold: float = 0.0

@export var comparison: int = Comparison.GREATER_THAN

@export var action_type: int = ActionType.MODIFY_RESOURCE

@export var action_target: StringName = &""

@export var action_value: float = 0.0


func _check_threshold(pool) -> bool:
	var res = pool.get_resource(resource_id)
	if res == null:
		return false
	match comparison:
		Comparison.GREATER_THAN:
			return res.amount > threshold
		Comparison.LESS_THAN:
			return res.amount < threshold
		Comparison.EQUAL:
			return is_equal_approx(res.amount, threshold)
	return false


func check_condition(state: GameState) -> bool:
	if one_shot and has_fired:
		return false
	return _check_threshold(state.resources)


func execute(state: GameState) -> void:
	match action_type:
		ActionType.MODIFY_RESOURCE:
			state.resources.modify(action_target, action_value)
		ActionType.ACTIVATE_PRODUCER:
			var producer = state.get_producer(action_target)
			if producer != null:
				producer.is_active = true
	if one_shot:
		has_fired = true
