extends Node

## Autoload that manages always-on-top toggle and window state persistence.
## Saves/loads position, size, and always-on-top flag to "user://window.cfg".

var always_on_top: bool = false
var window_position: Vector2i = Vector2i(0, 0)
var window_size: Vector2i = Vector2i(400, 600)

const CONFIG_PATH := "user://window.cfg"
const SECTION_GENERAL := "general"
const KEY_ALWAYS_ON_TOP := "always_on_top"
const KEY_POS_X := "position_x"
const KEY_POS_Y := "position_y"
const KEY_SIZE_X := "size_x"
const KEY_SIZE_Y := "size_y"


func _ready() -> void:
	load_window_state()
	_apply_window_state()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_window_state()


func toggle_always_on_top() -> void:
	always_on_top = not always_on_top
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, always_on_top)


func save_window_state() -> void:
	_read_current_state()
	var config := ConfigFile.new()
	config.set_value(SECTION_GENERAL, KEY_ALWAYS_ON_TOP, always_on_top)
	config.set_value(SECTION_GENERAL, KEY_POS_X, window_position.x)
	config.set_value(SECTION_GENERAL, KEY_POS_Y, window_position.y)
	config.set_value(SECTION_GENERAL, KEY_SIZE_X, window_size.x)
	config.set_value(SECTION_GENERAL, KEY_SIZE_Y, window_size.y)
	config.save(CONFIG_PATH)


func load_window_state() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return
	always_on_top = config.get_value(SECTION_GENERAL, KEY_ALWAYS_ON_TOP, false)
	var x: int = config.get_value(SECTION_GENERAL, KEY_POS_X, 0)
	var y: int = config.get_value(SECTION_GENERAL, KEY_POS_Y, 0)
	var w: int = config.get_value(SECTION_GENERAL, KEY_SIZE_X, 400)
	var h: int = config.get_value(SECTION_GENERAL, KEY_SIZE_Y, 600)
	window_position = Vector2i(x, y)
	window_size = Vector2i(w, h)


func _read_current_state() -> void:
	window_position = DisplayServer.window_get_position()
	window_size = DisplayServer.window_get_size()


func _apply_window_state() -> void:
	DisplayServer.window_set_position(window_position)
	DisplayServer.window_set_size(window_size)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, always_on_top)
