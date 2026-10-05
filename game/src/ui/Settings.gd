extends Control
## Settings — audio, steering sensitivity, haptics, left-handed layout.

func _ready() -> void:
	add_child(UIKit.background())
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 18)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(root)
	root.add_child(UIKit.title("SETTINGS"))

	var s := Game.settings()
	root.add_child(_slider("Music", float(s.get("music", 0.7)), func(v): Game.set_setting("music", v)))
	root.add_child(_slider("Sound", float(s.get("sfx", 0.9)), func(v): Game.set_setting("sfx", v)))
	root.add_child(_slider("Steering sensitivity", float(s.get("steer_sensitivity", 1.0)) / 2.0,
		func(v): Game.set_setting("steer_sensitivity", v * 2.0)))
	root.add_child(_toggle("Haptics", bool(s.get("haptics", true)), func(v): Game.set_setting("haptics", v)))
	root.add_child(_toggle("Left-handed controls", bool(s.get("left_handed", false)), func(v): Game.set_setting("left_handed", v)))

	root.add_child(_center(UIKit.button("RESET PROGRESS", func():
		SaveManager.reset()
		Game.goto("main_menu"))))
	root.add_child(_center(UIKit.button("BACK", func(): Game.goto("main_menu"))))

func _center(c: Control) -> CenterContainer:
	var cc := CenterContainer.new()
	cc.add_child(c)
	return cc

func _slider(text: String, value: float, on_change: Callable) -> Control:
	var p := UIKit.panel()
	var v := VBoxContainer.new()
	v.add_child(UIKit.label(text, 22))
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = clampf(value, 0.0, 1.0)
	slider.custom_minimum_size = Vector2(420, 32)
	slider.value_changed.connect(on_change)
	v.add_child(slider)
	p.add_child(v)
	return p

func _toggle(text: String, value: bool, on_change: Callable) -> Control:
	var p := UIKit.panel()
	var h := HBoxContainer.new()
	var l := UIKit.label(text, 22)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	var cb := CheckButton.new()
	cb.button_pressed = value
	cb.toggled.connect(on_change)
	h.add_child(cb)
	p.add_child(h)
	return p
