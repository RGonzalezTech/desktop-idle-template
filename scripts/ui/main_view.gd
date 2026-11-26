class_name MainView
extends Control

@export var idle_runner: IdleRunner
@export var resource_display: ResourceDisplay
@export var producer_button: ProducerButton
@export var shop_view: ShopView
@export var catchup_modal: CatchupModal

func _ready() -> void:
	if idle_runner == null:
		return
	var state := idle_runner.game_state
	if state == null:
		return
	# Wire sub-scenes and trigger their deferred initialization.
	resource_display.game_state = state
	resource_display._connect_and_update()
	producer_button.game_state = state
	producer_button._update_label()
	shop_view.game_state = state
	shop_view.shop_inventory = state.shop_inventory
	shop_view._connect_and_refresh()
	# Wire catchup modal signals.
	state.clock.catchup_started.connect(catchup_modal.show_catchup)
	state.clock.catchup_progress.connect(catchup_modal.update_progress)
	state.clock.catchup_finished.connect(catchup_modal.hide_catchup)
	idle_runner.start()
