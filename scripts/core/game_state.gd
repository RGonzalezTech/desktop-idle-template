class_name GameState
extends Resource

## Top-level container for all simulation state.
## Integrates T2-T8: holds clock, resources, producers, upgrades, events, and config.
## ShopInventory field is a placeholder — T10 builds it.

@export var save_version: int = 1
@export var clock: GameClock
@export var config: GameConfig
@export var resources: ResourcePool
@export var producers: Array[BaseProducer] = []
@export var upgrades: Array[BaseUpgrade] = []
@export var events: Array[BaseEvent] = []
## Placeholder — built in Task 10. Null until ShopInventory is created.
@export var shop_inventory: Resource = null


func _init() -> void:
	clock = GameClock.new()
	config = GameConfig.new()
	resources = ResourcePool.new()


func get_producer(id: StringName) -> BaseProducer:
	for p in producers:
		if p.producer_id == id:
			return p
	return null


func get_upgrade(id: StringName) -> BaseUpgrade:
	for u in upgrades:
		if u.upgrade_id == id:
			return u
	return null


func get_event(id: StringName) -> BaseEvent:
	for e in events:
		if e.event_id == id:
			return e
	return null


func add_producer(producer: BaseProducer) -> void:
	producers.append(producer)


func add_upgrade(upgrade: BaseUpgrade) -> void:
	upgrades.append(upgrade)


func add_event(event: BaseEvent) -> void:
	events.append(event)


func _apply_starting_config() -> void:
	for resource_id in config.starting_resources:
		resources.add_resource(resource_id, config.starting_resources[resource_id])
	for producer_id in config.starting_producers:
		var producer := get_producer(producer_id)
		if producer:
			producer.count = config.starting_producers[producer_id]
