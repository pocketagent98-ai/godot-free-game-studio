extends Control
## Boot — first screen: refresh daily tasks, then go to the main menu.

func _ready() -> void:
	add_child(UIKit.background())
	var t := UIKit.title("TURBO RUSH")
	t.set_anchors_preset(Control.PRESET_CENTER)
	add_child(t)
	var sub := UIKit.label("Loading…", 22, UIKit.MUTED)
	sub.set_anchors_preset(Control.PRESET_CENTER)
	sub.position = Vector2(-40, 60)
	add_child(sub)
	Progression.refresh_daily()
	await get_tree().create_timer(0.4).timeout
	Game.goto("main_menu")
