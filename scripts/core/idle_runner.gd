class_name IdleRunner
extends Node

## Simulation coordinator. Ticks producers and evaluates events each tick.

signal state_loaded
signal state_saved

@export var game_state: GameState


func start() -> void:
	if game_state == null:
		return
	game_state._apply_starting_config()
	game_state.clock.tick.connect(_on_tick)
	game_state.clock.start()


func _on_tick(delta: float) -> void:
	if game_state == null:
		return

	for producer in game_state.producers:
		producer.tick(delta, game_state.resources)

	for event in game_state.events:
		if event.check_condition(game_state):
			event.execute(game_state)


func save() -> void:
	if game_state == null:
		return
	var saver := SaveSystem.new()
	saver.save(game_state, "user://save.tres")
	state_saved.emit()


func load() -> void:
	var saver := SaveSystem.new()
	var loaded := saver.load("user://save.tres")
	if loaded != null:
		game_state = loaded
		state_loaded.emit()
