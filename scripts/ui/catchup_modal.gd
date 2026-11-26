class_name CatchupModal
extends Control

@export var progress_bar: ProgressBar
@export var label: Label

func _ready() -> void:
	hide()

func show_catchup(total_seconds: float) -> void:
	progress_bar.max_value = total_seconds
	progress_bar.value = 0.0
	label.text = "Catching up..."
	show()

func update_progress(remaining: float, total: float) -> void:
	progress_bar.value = total - remaining

func hide_catchup() -> void:
	hide()
