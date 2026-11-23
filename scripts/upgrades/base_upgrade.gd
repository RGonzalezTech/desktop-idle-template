class_name BaseUpgrade
extends Resource

## Abstract upgrade base class.
## Upgrades carry NO cost data (costs live in T10 Shop).
## apply(producer) modifies the producer. purchase() sets is_purchased + emits signal.

signal purchased(upgrade_id: StringName)

@export var upgrade_id: StringName = &""

@export var target_producer_id: StringName = &""

@export var is_purchased: bool = false


func apply(_producer: BaseProducer) -> void:
	# Override in subclasses.
	pass


func purchase() -> void:
	is_purchased = true
	purchased.emit(upgrade_id)
