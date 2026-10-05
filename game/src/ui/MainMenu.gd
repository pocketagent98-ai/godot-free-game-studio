extends Control
## Main menu — the hub. Continue, Garage, Levels, Daily, Settings.

func _ready() -> void:
	add_child(UIKit.background())

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 18)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(root)

	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_END
	top.add_child(UIKit.currency_row())
	root.add_child(top)

	root.add_child(UIKit.title("TURBO RUSH"))
	var lvl := UIKit.label("Level %d / %d" % [Progression.current_level() + 1, GameData.LEVEL_COUNT], 24, UIKit.MUTED)
	lvl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(lvl)

	root.add_child(_center(UIKit.button("CONTINUE  ▶", _continue)))
	root.add_child(_center(UIKit.button("GARAGE", func(): Game.goto("garage"))))
	root.add_child(_center(UIKit.button("LEVELS", func(): Game.goto("levels"))))
	root.add_child(_center(UIKit.button("DAILY TASKS", func(): Game.goto("daily"))))
	root.add_child(_center(UIKit.button("SETTINGS", func(): Game.goto("settings"))))

	Ads.show_banner()

func _center(c: Control) -> CenterContainer:
	var cc := CenterContainer.new()
	cc.add_child(c)
	return cc

func _continue() -> void:
	Game.start_race(Progression.current_level())
