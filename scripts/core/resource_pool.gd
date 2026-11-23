class_name ResourcePool
extends Resource

## Dictionary-backed pool of GameResource instances.
## Central hub for all resource read/write operations.
## Extends Resource (not RefCounted) for .tres serialization compatibility.

signal resource_added(id: StringName)
signal resource_removed(id: StringName)
signal resource_changed(id: StringName, new_amount: float, delta: float)

var _resources: Dictionary = {}


func add_resource(id: StringName, initial: float, min_val: float = 0.0, max_val: float = INF) -> GameResource:
	var res := GameResource.new()
	res.resource_id = id
	res.min_value = min_val
	res.max_value = max_val
	res.amount = initial
	var captured_id: StringName = id
	res.amount_changed.connect(func(new_amount: float, delta: float):
		resource_changed.emit(captured_id, new_amount, delta)
	)
	_resources[id] = res
	resource_added.emit(id)
	return res


func get_resource(id: StringName) -> GameResource:
	return _resources.get(id, null)


func has_resource(id: StringName) -> bool:
	return _resources.has(id)


func modify(id: StringName, delta: float) -> float:
	var res: GameResource = _resources.get(id, null)
	if res == null:
		push_error("Resource '%s' not found" % id)
		return 0.0
	res.amount = clampf(res.amount + delta, res.min_value, res.max_value)
	return res.amount


func all_resources() -> Array[GameResource]:
	var result: Array[GameResource] = []
	for res in _resources.values():
		result.append(res)
	return result


func remove_resource(id: StringName) -> void:
	if not _resources.has(id):
		return
	# Lambda connections can't be individually disconnected by name,
	# but erasing the resource from the dict severs the reference chain.
	_resources.erase(id)
	resource_removed.emit(id)


