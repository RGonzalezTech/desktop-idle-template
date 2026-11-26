class_name SaveSystem
extends RefCounted

## .tres-based save/load with versioning and migration hooks.
## Saves the full GameState Resource tree to disk via ResourceSaver.
## _migrate is a no-op for v1 — override in subclasses for future versions.


func save(state: GameState, path: String) -> bool:
	return ResourceSaver.save(state, path) == OK


func load(path: String) -> GameState:
	if not FileAccess.file_exists(path):
		return null
	var state: GameState = ResourceLoader.load(path, "GameState", ResourceLoader.CACHE_MODE_IGNORE)
	if state == null:
		return null
	if state.save_version < 1:
		_migrate(state, state.save_version)
	return state


func _migrate(_state: GameState, _from_version: int) -> void:
	pass
