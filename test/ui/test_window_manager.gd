extends GutTest

func test_window_manager_exists():
	var WM = load("res://scripts/ui/window_manager.gd")
	var wm = autofree(WM.new())
	assert_not_null(wm)
