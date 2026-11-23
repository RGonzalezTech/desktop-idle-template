extends GutTest

func test_tick_increments_elapsed():
	var clock = autofree(GameClock.new())
	clock.tick_rate = 1.0
	clock.start()
	# Simulate one tick
	clock._on_timer_timeout()
	assert_almost_eq(clock.elapsed, 1.0, 0.01)


func test_pause_stops_ticks():
	var clock = autofree(GameClock.new())
	clock.tick_rate = 1.0
	clock.start()
	clock.pause()
	var before = clock.elapsed
	clock._on_timer_timeout()
	assert_eq(clock.elapsed, before)


func test_resume_calculates_offline_delta():
	var clock = autofree(GameClock.new())
	clock.tick_rate = 1.0
	clock.start()
	clock.pause()
	clock.last_save_epoch = Time.get_unix_time_from_system() - 10  # 10 seconds ago
	watch_signals(clock)
	clock.resume()
	assert_signal_emitted(clock, "catchup_started", "catchup_started should emit on resume with offline time")


func test_zero_offline_delta_no_catchup():
	var clock = autofree(GameClock.new())
	clock.start()
	clock.pause()
	clock.last_save_epoch = Time.get_unix_time_from_system()  # now
	watch_signals(clock)
	clock.resume()
	assert_signal_not_emitted(clock, "catchup_started", "Zero delta should not trigger catchup")


func test_catchup_increments_elapsed():
	var clock = autofree(GameClock.new())
	clock.tick_rate = 1.0
	clock.ticks_per_second_during_catchup = 60.0
	clock.start()
	clock.pause()
	clock.last_save_epoch = Time.get_unix_time_from_system() - 10  # 10 seconds ago
	watch_signals(clock)
	clock.resume()
	assert_almost_eq(clock.elapsed, 10.0, 0.1, "elapsed should reflect 10s of catchup time")
