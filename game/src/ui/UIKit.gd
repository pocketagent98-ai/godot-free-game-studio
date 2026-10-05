extends RefCounted
class_name UIKit
## Shared UI builders so every screen looks consistent without scene files.

const BG := Color(0.08, 0.09, 0.12)
const PANEL := Color(0.13, 0.15, 0.19)
const ACCENT := Color(0.31, 0.82, 0.77)
const GOLD := Color(0.98, 0.80, 0.28)
const DIAMOND := Color(0.45, 0.78, 0.98)
const TEXT := Color(0.92, 0.95, 0.97)
const MUTED := Color(0.62, 0.67, 0.73)

static func button(text: String, on_press: Callable, width: float = 320.0, height: float = 64.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(width, height)
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(func():
		Audio.play("ui")
		on_press.call())
	return b

static func label(text: String, size: int = 20, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

static func panel(color: Color = PANEL) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12
	sb.corner_radius_bottom_right = 12
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	p.add_theme_stylebox_override("panel", sb)
	return p

static func background() -> ColorRect:
	var c := ColorRect.new()
	c.color = BG
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	return c

static func title(text: String) -> Label:
	var l := label(text, 44)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

static func currency_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	row.alignment = BoxContainer.ALIGNMENT_END
	var coins := label("C  %d" % Economy.coins(), 24, GOLD)
	coins.name = "CoinsLabel"
	var diamonds := label("D  %d" % Economy.diamonds(), 24, DIAMOND)
	diamonds.name = "DiamondsLabel"
	row.add_child(coins)
	row.add_child(diamonds)
	Economy.changed.connect(func():
		if is_instance_valid(coins):
			coins.text = "C  %d" % Economy.coins()
		if is_instance_valid(diamonds):
			diamonds.text = "D  %d" % Economy.diamonds())
	return row

static func refresh_currency(root: Node) -> void:
	var coins := root.find_child("CoinsLabel", true, false)
	if coins:
		coins.text = "C  %d" % Economy.coins()
	var diamonds := root.find_child("DiamondsLabel", true, false)
	if diamonds:
		diamonds.text = "D  %d" % Economy.diamonds()
