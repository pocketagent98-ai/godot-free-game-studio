extends Node
## Progression — level completion, race rewards and daily tasks.
## Diamonds are intentionally scarce: they come mostly from daily tasks and
## milestone levels, never from ordinary wins.

signal level_completed(level_id: int, position: int, coins: int, diamonds: int)
signal daily_refreshed()

const DAILY_TASK_POOL := [
	{"id": "race3", "text": "Finish 3 races", "target": 3, "diamonds": 2, "coins": 150},
	{"id": "win1", "text": "Win 1 race", "target": 1, "diamonds": 3, "coins": 200},
	{"id": "podium2", "text": "Reach the podium twice", "target": 2, "diamonds": 2, "coins": 180},
	{"id": "boost5", "text": "Use nitro 5 times", "target": 5, "diamonds": 1, "coins": 120},
	{"id": "drift10", "text": "Drift for 10 seconds", "target": 10, "diamonds": 2, "coins": 160},
]

func current_level() -> int:
	return int(SaveManager.get_value("current_level", 0))

func is_completed(level_id: int) -> bool:
	return level_id in (SaveManager.get_value("completed_levels", []) as Array)

func best_position(level_id: int) -> int:
	var bp: Dictionary = SaveManager.get_value("best_positions", {})
	return int(bp.get(str(level_id), 99))

func complete_level(level_id: int, position: int, double_coins: bool = false) -> Dictionary:
	var lvl := GameData.level(level_id)
	var coins := GameData.coins_for_position(position)
	var diamonds := GameData.diamonds_for_position(position)
	# milestone diamonds (rare)
	if float(lvl.get("diamond_chance", 0.0)) > 0.0 and position == 0:
		diamonds += 2
	if double_coins:
		coins *= 2

	Economy.add_coins(coins)
	if diamonds > 0:
		Economy.add_diamonds(diamonds)

	var completed: Array = SaveManager.get_value("completed_levels", [])
	if not (level_id in completed):
		completed.append(level_id)
	SaveManager.set_value("completed_levels", completed)

	var bp: Dictionary = SaveManager.get_value("best_positions", {})
	bp[str(level_id)] = mini(int(bp.get(str(level_id), 99)), position)
	SaveManager.set_value("best_positions", bp)

	var stats: Dictionary = SaveManager.get_value("stats", {})
	stats["races"] = int(stats.get("races", 0)) + 1
	if position == 0:
		stats["wins"] = int(stats.get("wins", 0)) + 1
	SaveManager.set_value("stats", stats)

	if level_id == current_level():
		SaveManager.set_value("current_level", current_level() + 1)

	_track_daily({"race": 1, "win": 1 if position == 0 else 0,
		"podium": 1 if position <= 2 else 0})

	level_completed.emit(level_id, position, coins, diamonds)
	return {"coins": coins, "diamonds": diamonds}

# --------------------------------------------------------- daily tasks ---- #
func _today() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d["year"], d["month"], d["day"]]

func refresh_daily() -> void:
	var daily: Dictionary = SaveManager.get_value("daily", {})
	if daily.get("date", "") == _today():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(_today())
	var tasks: Array = []
	var pool := DAILY_TASK_POOL.duplicate()
	pool.shuffle()
	for i in mini(3, pool.size()):
		var t: Dictionary = (pool[i] as Dictionary).duplicate()
		t["progress"] = 0
		tasks.append(t)
	daily = {"date": _today(), "tasks": tasks, "claimed": [], "ads_watched_today": 0}
	SaveManager.set_value("daily", daily)
	daily_refreshed.emit()

func daily() -> Dictionary:
	refresh_daily()
	return SaveManager.get_value("daily", {})

func _track_daily(events: Dictionary) -> void:
	var d := daily()
	var tasks: Array = d.get("tasks", [])
	for t in tasks:
		var tid: String = t.get("id", "")
		if tid == "race3" and events.get("race", 0) > 0:
			t["progress"] = int(t.get("progress", 0)) + 1
		elif tid == "win1" and events.get("win", 0) > 0:
			t["progress"] = int(t.get("progress", 0)) + 1
		elif tid == "podium2" and events.get("podium", 0) > 0:
			t["progress"] = int(t.get("progress", 0)) + 1
		elif tid == "boost5" and events.get("boost", 0) > 0:
			t["progress"] = int(t.get("progress", 0)) + 1
		elif tid == "drift10":
			t["progress"] = int(t.get("progress", 0)) + int(events.get("drift", 0))
	SaveManager.set_value("daily", d)

func add_drift(seconds: float) -> void:
	_track_daily({"drift": int(seconds)})

func add_boost() -> void:
	_track_daily({"boost": 1})

func claim_task(index: int) -> bool:
	var d := daily()
	var tasks: Array = d.get("tasks", [])
	if index < 0 or index >= tasks.size():
		return false
	var t: Dictionary = tasks[index]
	var claimed: Array = d.get("claimed", [])
	if index in claimed:
		return false
	if int(t.get("progress", 0)) < int(t.get("target", 1)):
		return false
	claimed.append(index)
	d["claimed"] = claimed
	SaveManager.set_value("daily", d)
	Economy.add_diamonds(int(t.get("diamonds", 1)))
	Economy.add_coins(int(t.get("coins", 0)))
	return true
