extends GutTest

const SAVE_PATH := "user://test_save.tres"
const MISSING_PATH := "user://does_not_exist.tres"


func test_save_load_roundtrip() -> void:
	var system := SaveSystem.new()
	var state := GameState.new()
	state.save_version = 1
	state.resources.add_resource(&"gold", 500.0)
	var miner := PassiveProducer.new()
	miner.producer_id = &"miner"
	miner.rate = 10.0
	miner.count = 3
	state.add_producer(miner)

	assert_true(system.save(state, SAVE_PATH), "Save should succeed")

	var loaded: GameState = system.load(SAVE_PATH)
	assert_not_null(loaded, "Loaded state should not be null")
	assert_eq(loaded.save_version, 1)
	assert_true(loaded.resources.has_resource(&"gold"), "Gold resource should exist")
	assert_eq(loaded.resources.get_resource(&"gold").amount, 500.0)

	var loaded_miner: BaseProducer = loaded.get_producer(&"miner")
	assert_not_null(loaded_miner, "Miner producer should exist")
	assert_eq(loaded_miner.count, 3)
	var pp: PassiveProducer = loaded_miner as PassiveProducer
	assert_not_null(pp, "Should be a PassiveProducer")
	assert_eq(pp.rate, 10.0)


func test_load_nonexistent_returns_null() -> void:
	var system := SaveSystem.new()
	var result: GameState = system.load(MISSING_PATH)
	assert_null(result, "Loading a nonexistent file should return null")


func test_save_overwrites_existing() -> void:
	var system := SaveSystem.new()
	var path := "user://test_overwrite.tres"

	var state_a := GameState.new()
	state_a.resources.add_resource(&"gold", 100.0)
	assert_true(system.save(state_a, path))

	var state_b := GameState.new()
	state_b.resources.add_resource(&"gold", 200.0)
	assert_true(system.save(state_b, path))

	var loaded: GameState = system.load(path)
	assert_not_null(loaded)
	assert_eq(loaded.resources.get_resource(&"gold").amount, 200.0)
