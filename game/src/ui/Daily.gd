extends Control
## Daily tasks — the main, deliberate source of diamonds (which stay scarce).

func _ready() -> void:
	add_child(UIKit.background())
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 14)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(root)

	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_END
	header.add_child(UIKit.currency_row())
	root.add_child(header)

	root.add_child(UIKit.title("DAILY TASKS"))
	var note := UIKit.label("Diamonds are rare — daily tasks are the main way to earn them.", 20, UIKit.MUTED)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(note)

	var d := Progression.daily()
	var tasks: Array = d.get("tasks", [])
	var claimed: Array = d.get("claimed", [])
	for i in tasks.size():
		var t: Dictionary = tasks[i]
		var p := UIKit.panel()
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 16)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_child(UIKit.label(t.get("text", ""), 22))
		info.add_child(UIKit.label("Reward:  D %d   C %d" % [int(t.get("diamonds", 1)), int(t.get("coins", 0))], 18, UIKit.MUTED))
		h.add_child(info)
		var prog := UIKit.label("%d / %d" % [int(t.get("progress", 0)), int(t.get("target", 1))], 22)
		h.add_child(prog)
		var idx := i
		var ready := int(t.get("progress", 0)) >= int(t.get("target", 1))
		var btn := UIKit.button("CLAIM" if ready and not (idx in claimed) else ("CLAIMED" if idx in claimed else "IN PROGRESS"),
			func():
				if Progression.claim_task(idx):
					Audio.play("reward")
					Game.goto("daily"), 180, 50)
		btn.disabled = not ready or (idx in claimed)
		h.add_child(btn)
		p.add_child(h)
		root.add_child(p)

	root.add_child(_center(UIKit.button("WATCH AD  →  +1 DIAMOND", func():
		Ads.show_rewarded("daily_diamond"))))
	Ads.rewarded_finished.connect(_on_reward)
	root.add_child(_center(UIKit.button("BACK", func(): Game.goto("main_menu"))))

func _center(c: Control) -> CenterContainer:
	var cc := CenterContainer.new()
	cc.add_child(c)
	return cc

func _on_reward(kind: String, success: bool) -> void:
	if kind == "daily_diamond" and success:
		var d := Progression.daily()
		if int(d.get("ads_watched_today", 0)) < 5:
			d["ads_watched_today"] = int(d.get("ads_watched_today", 0)) + 1
			SaveManager.set_value("daily", d)
			Economy.add_diamonds(1)
			Audio.play("reward")
