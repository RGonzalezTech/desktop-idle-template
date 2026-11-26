class_name BaseEvent
extends Resource

## Abstract event base class.
## Events check conditions against GameState and execute effects when triggered.

@export var event_id: StringName = &""

@export var has_fired: bool = false

@export var one_shot: bool = false


func check_condition(_state: GameState) -> bool:
	# Override in subclasses. Default: never triggers.
	return false


func execute(_state: GameState) -> void:
	# Override in subclasses.
	pass
