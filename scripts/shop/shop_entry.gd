class_name ShopEntry
extends Resource

## Abstract shop entry base class.
## Costs live here; unlock conditions are event-driven.
## Subclasses implement purchase(state) to apply their effect.

@export var entry_id: StringName = &""

@export var display_name: String = ""

@export var cost_resource: StringName = &""

@export var cost_amount: float = 0.0

@export var unlock_condition: BaseEvent = null


func is_visible(state: GameState) -> bool:
	if unlock_condition == null:
		return true
	return unlock_condition.check_condition(state)


func can_afford(state: GameState) -> bool:
	var res: GameResource = state.resources.get_resource(cost_resource)
	if res == null:
		return false
	return res.amount >= cost_amount


func purchase(_state: GameState) -> bool:
	# Override in subclasses.
	return false
