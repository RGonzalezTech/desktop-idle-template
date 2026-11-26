class_name MainView
extends Control

@onready var idle_runner: IdleRunner = $"../IdleRunner"

@onready var resource_display: ResourceDisplay = $PanelContainer/VBoxContainer/ResourceDisplay
@onready var producer_button: ProducerButton = $PanelContainer/VBoxContainer/ProducerButton
@onready var shop_view: ShopView = $PanelContainer/VBoxContainer/ShopView
@onready var catchup_modal: CatchupModal = $PanelContainer/VBoxContainer/CatchupModal
@onready var per_sec_label: Label = $PanelContainer/VBoxContainer/PerSecLabel

func _ready() -> void:
	if idle_runner == null:
		return
	var state := idle_runner.game_state
	if state == null:
		return
	# Start simulation first so _apply_starting_config() initializes resources.
	idle_runner.start()
	# Wire sub-scenes — resources are now initialized.
	resource_display.game_state = state
	resource_display._connect_and_update()
	producer_button.game_state = state
	producer_button._update_label()
	shop_view.game_state = state
	shop_view.shop_inventory = state.shop_inventory
	shop_view._connect_and_refresh()
	# Wire per-second label to resource changes.
	state.resources.resource_changed.connect(_update_per_sec)
	_update_per_sec(&"", 0.0, 0.0)
	# Wire catchup modal signals.
	state.clock.catchup_started.connect(catchup_modal.show_catchup)
	state.clock.catchup_progress.connect(catchup_modal.update_progress)
	state.clock.catchup_finished.connect(catchup_modal.hide_catchup)

func _update_per_sec(_id: StringName, _amount: float, _delta: float) -> void:
	if idle_runner == null or idle_runner.game_state == null:
		return
	var rate: float = 0.0
	for producer in idle_runner.game_state.producers:
		if producer is PassiveProducer and producer.is_active:
			rate += producer.rate * producer.count
	per_sec_label.text = "%.1f / sec" % rate
