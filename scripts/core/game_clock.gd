class_name GameClock
extends Resource

## Time tracking and tick-driving Resource.
## Uses an internal Timer node for tick scheduling.
## Supports pause/resume and offline catchup.

## Total elapsed simulation time in seconds.
var elapsed: float = 0.0

## Number of ticks per second of simulation time.
## At tick_rate 1.0, one tick = 1 second of sim time.
var tick_rate: float = 1.0

## Whether the clock is currently paused.
var is_paused: bool = false

## Epoch timestamp (seconds) from last save, used for offline catchup.
var last_save_epoch: int = 0

## Simulation ticks per second during offline catchup.
var ticks_per_second_during_catchup: float = 60.0

## Emitted each simulation tick with the delta (1.0 / tick_rate).
signal tick(delta: float)

## Emitted when offline time is detected on resume.
signal offline_time_elapsed(seconds: float)

## Emitted when catchup phase begins.
signal catchup_started(total_seconds: float)

## Emitted during each catchup iteration (remaining, total).
signal catchup_progress(remaining: float, total: float)

## Emitted when catchup phase completes.
signal catchup_finished()

# Internal Timer node — created in start().
var _timer: Timer = null


func start() -> void:
	if _timer == null:
		_timer = Timer.new()
		_timer.one_shot = false
		# tick_rate ticks per second, so wait_time = 1.0 / tick_rate
		_timer.wait_time = 1.0 / tick_rate
		_timer.timeout.connect(_on_timer_timeout)
		# Add timer as a child of this Resource's owner? No — Resource can't have children.
		# We'll add it to the scene tree via Engine.get_main_loop() if available,
		# but for testing, the timer callback can be called directly.
		# For real runtime, the timer needs to be in the tree.
		# We'll use a different approach: store the timer and let callers add it,
		# OR we can add it to the scene tree root.
		# Actually, for the test to work, we just need _on_timer_timeout callable.
		# In production, we add to scene tree.
		var main_loop := Engine.get_main_loop()
		if main_loop is SceneTree:
			main_loop.root.add_child(_timer)
	_timer.start()
	is_paused = false


func pause() -> void:
	is_paused = true
	if _timer != null:
		_timer.stop()


func resume() -> void:
	if not is_paused:
		return

	var now_epoch := Time.get_unix_time_from_system()
	# Use integer seconds for delta to match last_save_epoch (int) precision
	var offline_delta := int(now_epoch) - last_save_epoch

	# Offline catchup
	if offline_delta > 0:
		catchup_started.emit(float(offline_delta))
		offline_time_elapsed.emit(float(offline_delta))

		var remaining := float(offline_delta)
		var total := float(offline_delta)
		var sim_delta := 1.0 / ticks_per_second_during_catchup

		while remaining > 0.0:
			catchup_progress.emit(remaining, total)
			tick.emit(sim_delta)
			remaining -= sim_delta

		catchup_finished.emit()

	is_paused = false
	if _timer != null:
		_timer.start()


func _on_timer_timeout() -> void:
	if is_paused:
		return
	var delta := 1.0 / tick_rate
	elapsed += delta
	tick.emit(delta)
