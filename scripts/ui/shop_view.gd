class_name ShopView
extends Control

@export var shop_inventory: ShopInventory
@export var game_state: GameState

var _container: VBoxContainer
var _connected: bool = false


func _ready() -> void:
	_container = VBoxContainer.new()
	add_child(_container)
	if game_state != null:
		_connect_and_refresh()


func _connect_and_refresh() -> void:
	if game_state != null and not _connected:
		game_state.resources.resource_changed.connect(_on_resource_changed)
		_connected = true
	_refresh()


func _on_resource_changed(_id: StringName, _amount: float, _delta: float) -> void:
	_refresh()


func _refresh() -> void:
	if game_state == null or shop_inventory == null or _container == null:
		return
	for child in _container.get_children():
		child.queue_free()
	for entry in shop_inventory.get_visible_entries(game_state):
		var btn := Button.new()
		btn.text = "%s — %.0f %s" % [entry.display_name, entry.cost_amount, entry.cost_resource]
		btn.disabled = not entry.can_afford(game_state)
		var entry_id: StringName = entry.entry_id
		btn.pressed.connect(func(): shop_inventory.purchase(entry_id, game_state))
		_container.add_child(btn)
