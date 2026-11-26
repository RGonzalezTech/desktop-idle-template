class_name ProducerButton
extends Button

@export var producer_id: StringName = &""
@export var game_state: GameState
@export var display_text: String = "Produce"

var _cooldown_timer: Timer

func _ready() -> void:
	_cooldown_timer = Timer.new()
	_cooldown_timer.one_shot = true
	_cooldown_timer.wait_time = 0.1
	_cooldown_timer.timeout.connect(_on_cooldown_end)
	add_child(_cooldown_timer)
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
	disabled = true
	_cooldown_timer.start()


func _on_cooldown_end() -> void:
	disabled = false


func _update_label() -> void:
	if game_state == null:
		return
	var producer := game_state.get_producer(producer_id)
	if producer is ClickProducer:
		text = "%s (+%.0f)" % [display_text, producer.click_amount]
