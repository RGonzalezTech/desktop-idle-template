extends GutTest

func test_default_values() -> void:
	var config = autofree(GameConfig.new())
	assert_eq(config.window_width, 400)
	assert_eq(config.window_height, 600)
	assert_almost_eq(config.tick_rate, 1.0, 0.01)
	assert_almost_eq(config.catchup_ticks_per_second, 60.0, 0.01)

func test_starting_resources_is_empty_by_default() -> void:
	var config = autofree(GameConfig.new())
	assert_eq(config.starting_resources, {})

func test_starting_producers_is_empty_by_default() -> void:
	var config = autofree(GameConfig.new())
	assert_eq(config.starting_producers, {})

func test_can_set_and_read_starting_resources() -> void:
	var config = autofree(GameConfig.new())
	config.starting_resources = { &"gold": 100.0, &"energy": 50.0 }
	assert_eq(config.starting_resources[&"gold"], 100.0)
	assert_eq(config.starting_resources[&"energy"], 50.0)

func test_can_set_and_read_starting_producers() -> void:
	var config = autofree(GameConfig.new())
	config.starting_producers = { &"clicker": 1, &"generator": 0 }
	assert_eq(config.starting_producers[&"clicker"], 1)
	assert_eq(config.starting_producers[&"generator"], 0)
