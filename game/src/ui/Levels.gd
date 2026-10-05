extends Control
## Level select — a scrolling grid of 1000 levels with progress + best position.

func _ready() -> void:
	add_child(UIKit.background())
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	var header := HBoxContainer.new()
	header.add_child(UIKit.button("◀", func(): Game.goto("main_menu"), 90, 48))
	header.add_child(UIKit.currency_row())
	root.add_child(header)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)

	var unlocked_upto := Progression.current_level()
	for i in GameData.LEVEL_COUNT:
		var lvl := GameData.level(i)
		var done := Progression.is_completed(i)
		var unlocked := i <= unlocked_upto
		var text := "%d\n%s" % [i + 1, lvl["theme"]]
		if done:
			text += "\n%s" % _ordinal(Progression.best_position(i))
		var b := UIKit.button(text, func(): _start(i), 150, 78)
		b.add_theme_font_size_override("font_size", 16)
		b.disabled = not unlocked
		if done:
			b.modulate = Color(0.7, 1.0, 0.8)
		grid.add_child(b)

func _ordinal(n: int) -> String:
	match n:
		1: return "1st"
		2: return "2nd"
		3: return "3rd"
		4: return "4th"
		5: return "5th"
		_: return "-"

func _start(id: int) -> void:
	Game.start_race(id)
