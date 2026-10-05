extends Control
## Garage — 3D preview, stats, and four tabs: Cars, Paints, Wheels, Upgrades.
## Everything is bought with coins or diamonds. No real-money purchases exist.

var _preview: CarPreview
var _viewport: SubViewport
var _stats_label: Label
var _list: VBoxContainer
var _tab := 0
var _preview_car := 0
var _preview_paint := 0
var _preview_wheel := 0

func _ready() -> void:
	add_child(UIKit.background())
	_preview_car = Economy.selected_car()
	_preview_paint = Economy.selected_paint()
	_preview_wheel = Economy.selected_wheel()

	var root := HBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	# left: preview + stats
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(560, 0)
	left.add_theme_constant_override("separation", 8)
	root.add_child(left)

	var header := HBoxContainer.new()
	header.add_child(UIKit.button("◀", func(): Game.goto("main_menu"), 90, 48))
	header.add_child(UIKit.currency_row())
	left.add_child(header)

	left.add_child(_make_viewport())
	_stats_label = UIKit.label("", 20, UIKit.TEXT)
	left.add_child(_stats_label)

	# right: tabs + list
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	root.add_child(right)

	var tabs := HBoxContainer.new()
	for i in ["Cars", "Paints", "Wheels", "Upgrades"]:
		var idx := tabs.get_child_count()
		tabs.add_child(UIKit.button(i, func(): _set_tab(idx), 150, 48))
	right.add_child(tabs)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_list)

	_refresh()

func _make_viewport() -> SubViewportContainer:
	var container := SubViewportContainer.new()
	container.custom_minimum_size = Vector2(560, 340)
	container.stretch = true
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(560, 340)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.transparent_bg = false
	container.add_child(_viewport)

	var cam := Camera3D.new()
	cam.position = Vector3(0, 2.2, 7.0)
	cam.rotation_degrees = Vector3(-14, 0, 0)
	cam.current = true
	_viewport.add_child(cam)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, 30, 0)
	_viewport.add_child(light)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.10, 0.12, 0.15)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.6, 0.65, 0.75)
	e.ambient_light_energy = 0.7
	env.environment = e
	_viewport.add_child(env)

	_preview = CarPreview.new()
	_viewport.add_child(_preview)
	return container

func _set_tab(i: int) -> void:
	_tab = i
	_refresh()

func _refresh() -> void:
	_preview.build(_preview_car, _preview_paint, _preview_wheel)
	var car := GameData.car(_preview_car)
	_stats_label.text = "%s   [%s]\nSpeed %d   Accel %d   Handling %d   Grip %d" % [
		car["name"], car["rarity"],
		int(car["top_speed"]), int(car["acceleration"] * 4.0),
		int(car["handling"] * 100.0), int(car["grip"] * 100.0)]
	for c in _list.get_children():
		c.queue_free()
	match _tab:
		0: _list_cars()
		1: _list_paints()
		2: _list_wheels()
		3: _list_upgrades()
	UIKit.refresh_currency(self)

func _row(text: String, cost: String, owned: bool, selected: bool, on_click: Callable) -> Control:
	var p := UIKit.panel(Color(0.16, 0.19, 0.24) if not selected else Color(0.14, 0.32, 0.30))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	var name_l := UIKit.label(text, 20)
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(name_l)
	var cost_l := UIKit.label("" if owned else cost, 20, UIKit.GOLD if not owned else UIKit.MUTED)
	h.add_child(cost_l)
	var btn_text := "SELECT" if owned else "BUY"
	if selected:
		btn_text = "SELECTED"
	var b := UIKit.button(btn_text, on_click, 150, 44)
	b.disabled = selected
	h.add_child(b)
	p.add_child(h)
	return p

func _list_cars() -> void:
	for i in mini(24, GameData.CAR_COUNT):
		var c := GameData.car(i)
		var owned := Economy.is_car_unlocked(i)
		var sel := _preview_car == i
		var cap := i
		_list.add_child(_row("%d. %s" % [i + 1, c["name"]], "C %d" % int(c["price_coins"]), owned, sel,
			func():
				if owned:
					Economy.select_car(cap)
				else:
					if Economy.buy_car(cap):
						Economy.select_car(cap)
				_preview_car = cap
				_refresh()))

func _list_paints() -> void:
	for i in mini(36, GameData.PAINT_COUNT):
		var p := GameData.paint(i)
		var owned := Economy.is_paint_unlocked(i)
		var sel := _preview_paint == i
		var cost := "D %d" % int(p["price_diamonds"]) if int(p["price_diamonds"]) > 0 else "C %d" % int(p["price_coins"])
		var cap := i
		_list.add_child(_row("%d. %s" % [i + 1, p["name"]], cost, owned, sel,
			func():
				if owned:
					Economy.select_paint(cap)
				else:
					if Economy.buy_paint(cap):
						Economy.select_paint(cap)
				_preview_paint = cap
				_refresh()))

func _list_wheels() -> void:
	for i in mini(36, GameData.WHEEL_COUNT):
		var w := GameData.wheel(i)
		var owned := Economy.is_wheel_unlocked(i)
		var sel := _preview_wheel == i
		var cost := "D %d" % int(w["price_diamonds"]) if int(w["price_diamonds"]) > 0 else "C %d" % int(w["price_coins"])
		var cap := i
		_list.add_child(_row("%d. %s" % [i + 1, w["name"]], cost, owned, sel,
			func():
				if owned:
					Economy.select_wheel(cap)
				else:
					if Economy.buy_wheel(cap):
						Economy.select_wheel(cap)
				_preview_wheel = cap
				_refresh()))

func _list_upgrades() -> void:
	var lvl := Economy.upgrade_level(_preview_car)
	var p := UIKit.panel()
	var v := VBoxContainer.new()
	v.add_child(UIKit.label("Upgrade level: %d / 5" % lvl, 22))
	v.add_child(UIKit.label("Each level adds +6% speed and acceleration.", 18, UIKit.MUTED))
	if lvl < 5:
		v.add_child(UIKit.button("UPGRADE  (C %d)" % Economy.upgrade_cost(_preview_car), func():
			Economy.buy_upgrade(_preview_car)
			_refresh(), 280, 52))
	else:
		v.add_child(UIKit.label("MAXED OUT", 22, UIKit.ACCENT))
	p.add_child(v)
	_list.add_child(p)
