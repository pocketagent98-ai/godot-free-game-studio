extends Control
## Results — position, rewards, "double coins" rewarded ad, next/replay.
## Ad placed at a natural break: the race has just ended.

var _result: Dictionary = {}
var _doubled := false

func _ready() -> void:
	add_child(UIKit.background())
	_result = Game.last_result
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 16)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(root)

	root.add_child(UIKit.title(_ordinal(int(_result.get("position", 1))) + " PLACE"))
	var lvl := UIKit.label("Level %d complete" % (int(_result.get("level", 0)) + 1), 24, UIKit.MUTED)
	lvl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(lvl)

	var rewards := UIKit.panel()
	var rv := VBoxContainer.new()
	rv.add_child(UIKit.label("Coins   +%d" % int(_result.get("coins", 0)), 30, UIKit.GOLD))
	rv.add_child(UIKit.label("Diamonds   +%d" % int(_result.get("diamonds", 0)), 30, UIKit.DIAMOND))
	rewards.add_child(rv)
	root.add_child(_center(rewards))

	# Rewarded ad: double the coins earned this race
	Ads.rewarded_finished.connect(_on_reward)
	root.add_child(_center(UIKit.button("▶ WATCH AD  →  DOUBLE COINS", func():
		Ads.show_rewarded("double_coins"), 420, 60)))

	root.add_child(_center(UIKit.button("NEXT LEVEL  ▶", func():
		Ads.maybe_show_interstitial()
		Game.start_race(Progression.current_level()), 420, 60)))
	root.add_child(_center(UIKit.button("REPLAY", func(): Game.start_race(int(_result.get("level", 0))))))
	root.add_child(_center(UIKit.button("GARAGE", func(): Game.goto("garage"))))
	root.add_child(_center(UIKit.button("MAIN MENU", func(): Game.goto("main_menu"))))

func _center(c: Control) -> CenterContainer:
	var cc := CenterContainer.new()
	cc.add_child(c)
	return cc

func _on_reward(kind: String, success: bool) -> void:
	if kind == "double_coins" and success and not _doubled:
		_doubled = true
		Economy.add_coins(int(_result.get("coins", 0)))
		Audio.play("reward")
		Game.goto("results")

func _ordinal(n: int) -> String:
	match n:
		1: return "1ST"
		2: return "2ND"
		3: return "3RD"
		_: return "%dTH" % n
