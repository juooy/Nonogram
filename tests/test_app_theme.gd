extends "res://tests/test_case.gd"

func test_theme_is_cached() -> void:
	assert_true(AppTheme.get_theme() == AppTheme.get_theme())

func test_variations_exist() -> void:
	var t := AppTheme.get_theme()
	for v in ["AccentButton", "SegmentButton", "CardButton", "DangerButton"]:
		assert_eq(t.get_type_variation_base(v), &"Button", v)

func test_label_uses_ink() -> void:
	assert_eq(AppTheme.get_theme().get_color("font_color", "Label"), AppTheme.INK)

func test_icons_load() -> void:
	for n in ["back", "fill", "mark", "retry", "play", "save", "plus", "trash", "edit"]:
		assert_true(_icon(n) is Texture2D, n)

func test_slot_px_for_matches_instance() -> void:
	var b := HintBar.new()
	b.cell_px = 50.0
	assert_eq(HintBar.slot_px_for(50.0), b.slot_px())
	b.free()

func _icon(n: String) -> Resource:
	var png := "res://assets/icons/%s.png" % n
	return load(png) if ResourceLoader.exists(png) else load("res://assets/icons/%s.svg" % n)
