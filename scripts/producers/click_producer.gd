class_name ClickProducer
extends PassiveProducer

## Producer that generates resources on click with optional cooldown.
## on_click() is called by the UI layer directly — no input middleware.
## Returns click_amount * count, or 0.0 if cooldown hasn't expired.

@export var click_amount: float = 0.0

## Cooldown between clicks in seconds. 0.0 = no cooldown.
@export var cooldown: float = 0.0

var _last_click_time: float = -INF


## Called by the UI layer when the player clicks.
## Returns the amount produced (click_amount * count), or 0.0 if on cooldown.
func on_click(pool: ResourcePool) -> float:
	if not is_active:
		return 0.0

	# Check cooldown
	if cooldown > 0.0:
		var now := Time.get_ticks_msec() / 1000.0
		if now - _last_click_time < cooldown:
			return 0.0

	var amount := click_amount * count
	pool.modify(target_resource, amount)
	if amount != 0.0:
		produced.emit(target_resource, amount)

	# Start cooldown
	if cooldown > 0.0:
		_last_click_time = Time.get_ticks_msec() / 1000.0

	return amount
