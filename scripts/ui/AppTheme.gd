class_name AppTheme extends RefCounted
## 앱 공용 테마 (밝은 종이 톤). 화면 루트가 _ready 에서 theme = AppTheme.get_theme()

const BG := Color("#F4F1E8")
const PANEL := Color("#FBFAF5")
const INK := Color("#2B2B2B")
const ACCENT := Color("#2A7F7A")
const MARK := Color("#B5483B")
const BUTTON_BASE := Color("#E6E1D3")
const BUTTON_MIN := 64.0

static var _theme: Theme

static func get_theme() -> Theme:
	if _theme == null:
		_theme = _build()
	return _theme

static func _box(color: Color, radius := 10, pad := 12.0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(pad)
	return sb

## normal/hover/pressed/hover_pressed/disabled 스타일과 글자·아이콘 색을 한 번에
static func _button_type(t: Theme, type: String, normal: Color, pressed: Color, fg: Color, pressed_fg: Color) -> void:
	t.set_stylebox("normal", type, _box(normal))
	t.set_stylebox("hover", type, _box(normal.darkened(0.06)))
	t.set_stylebox("pressed", type, _box(pressed))
	t.set_stylebox("hover_pressed", type, _box(pressed.darkened(0.06)))
	t.set_stylebox("disabled", type, _box(normal.lightened(0.4)))
	t.set_stylebox("focus", type, StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_focus_color", "icon_normal_color", "icon_hover_color", "icon_focus_color"]:
		t.set_color(c, type, fg)
	for c in ["font_pressed_color", "font_hover_pressed_color", "icon_pressed_color", "icon_hover_pressed_color"]:
		t.set_color(c, type, pressed_fg)

static func _build() -> Theme:
	var t := Theme.new()
	t.default_font_size = 18

	_button_type(t, "Button", BUTTON_BASE, BUTTON_BASE.darkened(0.12), INK, INK)
	t.set_constant("icon_max_width", "Button", 28)
	t.set_constant("h_separation", "Button", 10)

	t.set_type_variation("AccentButton", "Button")
	_button_type(t, "AccentButton", ACCENT, ACCENT.darkened(0.15), Color.WHITE, Color.WHITE)

	t.set_type_variation("SegmentButton", "Button")  # 토글: 눌린 쪽이 ACCENT
	_button_type(t, "SegmentButton", BUTTON_BASE, ACCENT, INK, Color.WHITE)

	t.set_type_variation("CardButton", "Button")  # 목록 행
	_button_type(t, "CardButton", PANEL, BUTTON_BASE, INK, INK)

	t.set_color("font_color", "Label", INK)

	var edit := _box(Color.WHITE, 8, 10.0)
	var edit_focus := _box(Color.WHITE, 8, 10.0)
	edit_focus.set_border_width_all(2)
	edit_focus.border_color = ACCENT
	t.set_stylebox("normal", "LineEdit", edit)
	t.set_stylebox("focus", "LineEdit", edit_focus)
	t.set_color("font_color", "LineEdit", INK)
	t.set_color("caret_color", "LineEdit", INK)
	t.set_color("font_placeholder_color", "LineEdit", Color(INK, 0.45))

	t.set_stylebox("panel", "PanelContainer", _box(PANEL, 14, 12.0))
	t.set_stylebox("panel", "PopupMenu", _box(PANEL, 8, 8.0))
	t.set_stylebox("hover", "PopupMenu", _box(BUTTON_BASE, 6, 4.0))
	t.set_color("font_color", "PopupMenu", INK)
	t.set_color("font_hover_color", "PopupMenu", INK)
	return t
