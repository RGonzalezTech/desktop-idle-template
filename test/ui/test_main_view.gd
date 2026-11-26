extends GutTest

func test_main_view_loads() -> void:
	var scene = load("res://scenes/ui/main_view.tscn")
	assert_not_null(scene, "Scene should load")
	var instance = scene.instantiate()
	assert_not_null(instance, "Instance should not be null")
	instance.queue_free()
