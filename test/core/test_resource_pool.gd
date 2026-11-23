extends GutTest

var _signal_caught: Dictionary = {}


func _on_resource_changed(id: StringName, amount: float, delta: float) -> void:
	_signal_caught = {"id": id, "amount": amount, "delta": delta}


func test_add_and_get_resource() -> void:
	var pool = autofree(ResourcePool.new())
	var res = pool.add_resource("gold", 100.0, 0.0, 9999.0)
	assert_eq(res.amount, 100.0)
	assert_eq(pool.get_resource("gold").amount, 100.0)
	assert_true(pool.has_resource("gold"))
	assert_false(pool.has_resource("silver"))


func test_modify_clamps_to_limits() -> void:
	var pool = autofree(ResourcePool.new())
	pool.add_resource("gold", 50.0, 0.0, 100.0)
	var result = pool.modify("gold", 100.0)  # would be 150, capped at 100
	assert_eq(result, 100.0)
	result = pool.modify("gold", -200.0)  # would be -100, capped at 0
	assert_eq(result, 0.0)


func test_signal_emits_on_change() -> void:
	_signal_caught = {}
	var pool = autofree(ResourcePool.new())
	pool.add_resource("gold", 0.0)
	pool.resource_changed.connect(_on_resource_changed)
	pool.modify("gold", 50.0)
	assert_false(_signal_caught.is_empty(), "Signal should have been caught")
	assert_eq(_signal_caught.id, "gold")
	assert_eq(_signal_caught.amount, 50.0)
	assert_eq(_signal_caught.delta, 50.0)
