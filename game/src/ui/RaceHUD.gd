extends Control
class_name RaceHUD
## Race HUD + touch controls, built entirely in code (safe-area aware).

var race: Node
var _pos_label: Label
var _speed_label: Label
var _lap_label: Label
var _time_label: Label
var _countdown_label: Label
var _boost_bar: ProgressBar
var _pause_btn: Button

# touch control state
var _t_left := false
var _t_right := false
var _t_accel := false
var _t_brake := false
var _t_boost := false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS

	_pos_label = _label("1st", 64, Vector2(28, 24))
	_lap_label = _label("Lap 1/2", 28, Vector2(28, 100))
	_time_label = _label("0:00.0", 26, Vector2(28, 136))

	_speed_label = _label("0 km/h", 34, Vector2(-220, -70), true)
	_speed_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_speed_label.position = Vector2(-260, -110)

	_countdown_label = _label("", 120, Vector2.ZERO)
	_countdown_label.set_anchors_preset(Control.PRESET_CENTER)
	_countdown_label.add_theme_color_override("font_color", Color(0.35, 0.95, 0.85))

	_boost_bar = ProgressBar.new()
	_boost_bar.max_value = 100
	_boost_bar.value = 0
	_boost_bar.size = Vector2(240, 18)
	_boost_bar.position = Vector2(28, 176)
	_boost_bar.show_percentage = false
	add_child(_boost_bar)

	_pause_btn = Button.new()
	_pause_btn.text = "II"
	_pause_btn.custom_minimum_size = Vector2(56, 56)
	_pause_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_pause_btn.position = Vector2(-72, 20)
	_pause_btn.pressed.connect(_on_pause)
	add_child(_pause_btn)

	_build_touch_controls()

func _label(text: String, size: int, pos: Vector2, absolute: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	if not absolute:
		l.position = pos
	else:
		l.position = pos
	add_child(l)
	return l

func _build_touch_controls() -> void:
	_touch_button("<", Vector2(40, -160), Control.PRESET_BOTTOM_LEFT, func(p): _t_left = p)
	_touch_button(">", Vector2(170, -160), Control.PRESET_BOTTOM_LEFT, func(p): _t_right = p)
	_touch_button("GO", Vector2(-170, -160), Control.PRESET_BOTTOM_RIGHT, func(p): _t_accel = p)
	_touch_button("BRK", Vector2(-40, -160), Control.PRESET_BOTTOM_RIGHT, func(p): _t_brake = p)
	_touch_button("NOS", Vector2(-105, -280), Control.PRESET_BOTTOM_RIGHT, func(p): _t_boost = p)

func _touch_button(text: String, pos: Vector2, anchor: int, setter: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(110, 110)
	b.set_anchors_preset(anchor)
	b.position = pos
	b.button_down.connect(func(): setter.call(true))
	b.button_up.connect(func(): setter.call(false))
	b.modulate = Color(1, 1, 1, 0.55)
	add_child(b)

func _on_pause() -> void:
	Audio.play("ui")
	get_tree().paused = true
	var pause := PauseMenu.new()
	pause.hud = self
	add_child(pause)

func set_countdown(value: float) -> void:
	if value > 0.0:
		_countdown_label.text = str(int(ceil(value)))
	else:
		_countdown_label.text = "GO!"

func hide_countdown() -> void:
	_countdown_label.text = ""

func _process(_delta: float) -> void:
	if race == null or race.player == null:
		return
	if race.autopilot:
		return
	var p: RaceCar = race.player
	# apply touch controls (only if not paused)
	if not get_tree().paused:
		p.steer = (1.0 if _t_right else 0.0) - (1.0 if _t_left else 0.0)
		p.throttle = 1.0 if _t_accel else 0.0
		p.braking = _t_brake
		if _t_boost:
			p.apply_boost(2.0)
			Progression.add_boost()
			_t_boost = false

func update_from(rm: Node) -> void:
	if rm == null or rm.player == null:
		return
	_pos_label.text = _ordinal(rm.player_position)
	_speed_label.text = "%d km/h" % int(rm.player.current_speed_kmh())
	_lap_label.text = "Lap %d/%d" % [rm.player_lap, int(rm.level_data.get("laps", 2))]
	_time_label.text = _fmt_time(rm.race_time)
	_boost_bar.value = clampf(rm.player.boost_seconds / 4.0 * 100.0, 0.0, 100.0)

func _ordinal(n: int) -> String:
	match n:
		1: return "1st"
		2: return "2nd"
		3: return "3rd"
		_: return "%dth" % n

func _fmt_time(t: float) -> String:
	var m := int(t) / 60
	var s := int(t) % 60
	var ms := int((t - floor(t)) * 10.0)
	return "%d:%02d.%d" % [m, s, ms]
