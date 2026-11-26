class_name ShopView
extends Control

@export var shop_inventory: ShopInventory
@export var game_state: GameState

var _container: VBoxContainer
var _buttons: Dictionary = {}  # entry_id -> Button
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

	var visible := shop_inventory.get_visible_entries(game_state)
	var seen: Dictionary = {}

	for entry in visible:
		var eid: StringName = entry.entry_id
		seen[eid] = true
		var btn: Button = _buttons.get(eid, null)
		var label := _build_label(entry)

		if btn == null:
			# New entry — create button
			btn = Button.new()
			btn.text = label
			btn.disabled = not entry.can_afford(game_state)
			btn.pressed.connect(_make_purchase_handler(eid))
			_container.add_child(btn)
			_buttons[eid] = btn
		else:
			# Existing — update in place
			btn.text = label
			btn.disabled = not entry.can_afford(game_state)

	# Remove buttons for entries no longer visible
	for eid in _buttons.keys():
		if not seen.has(eid):
			var old: Button = _buttons[eid]
			old.queue_free()
			_buttons.erase(eid)

func _build_label(entry: ShopEntry) -> String:
	var label := "%s — %.0f %s" % [entry.display_name, entry.cost_amount, entry.cost_resource]
	if entry is ProducerShopEntry:
		label += " (x%d)" % _get_owned_count(entry.producer_id)
	return label

func _make_purchase_handler(entry_id: StringName) -> Callable:
	return func(): shop_inventory.purchase(entry_id, game_state)

func _get_owned_count(producer_id: StringName) -> int:
	if game_state == null:
		return 0
	var producer := game_state.get_producer(producer_id)
	if producer == null:
		return 0
	return producer.count
