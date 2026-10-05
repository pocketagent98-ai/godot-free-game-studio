extends Control
class_name PauseMenu
## In-race pause menu.

var hud: RaceHUD

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.65)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.add_theme_constant_override("separation", 16)
	add_child(box)

	box.add_child(_btn("Resume", func():
		get_tree().paused = false
		queue_free()))
	box.add_child(_btn("Restart", func():
		get_tree().paused = false
		Game.start_race(Game.pending_level)))
	box.add_child(_btn("Quit to Menu", func():
		get_tree().paused = false
		Game.goto("main_menu")))

func _btn(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(320, 64)
	b.add_theme_font_size_override("font_size", 26)
	b.pressed.connect(func():
		Audio.play("ui")
		action.call())
	return b
