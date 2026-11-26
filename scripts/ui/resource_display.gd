class_name ResourceDisplay
extends Label

@export var resource_id: StringName = &"gold"
@export var game_state: GameState

func _ready() -> void:
	if game_state != null:
		_connect_and_update()


func _connect_and_update() -> void:
	if game_state != null and game_state.resources.has_resource(resource_id):
		if not game_state.resources.resource_changed.is_connected(_on_resource_changed):
			game_state.resources.resource_changed.connect(_on_resource_changed)
	_update_text()


func _on_resource_changed(id: StringName, _new_amount: float, _delta: float) -> void:
	if id == resource_id:
		_update_text()


func _update_text() -> void:
	if game_state == null:
		return
	var res := game_state.resources.get_resource(resource_id)
	if res:
		text = "%s: %.0f" % [resource_id, res.amount]
