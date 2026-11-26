class_name ProducerButton
extends Button

@export var producer_id: StringName = &""
@export var game_state: GameState
@export var display_text: String = "Produce"

func _ready() -> void:
	pressed.connect(_on_pressed)
	if game_state != null:
		_update_label()


func _on_pressed() -> void:
	if game_state == null:
		return
	var producer := game_state.get_producer(producer_id)
	if producer == null:
		return
	producer.on_click(game_state.resources)


func _update_label() -> void:
	if game_state == null:
		return
	var producer := game_state.get_producer(producer_id)
	if producer is ClickProducer:
		text = "%s (+%.0f)" % [display_text, producer.click_amount]
