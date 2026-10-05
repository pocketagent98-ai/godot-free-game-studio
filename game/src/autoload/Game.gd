extends Node
## Game — scene router + global settings + race handoff.

const SCENES := {
	"main_menu": "res://scenes/main_menu.tscn",
	"garage": "res://scenes/garage.tscn",
	"levels": "res://scenes/levels.tscn",
	"daily": "res://scenes/daily.tscn",
	"settings": "res://scenes/settings.tscn",
	"race": "res://scenes/race.tscn",
	"results": "res://scenes/results.tscn",
}

var pending_level: int = 0
var last_result: Dictionary = {}
var pre_race_booster: String = ""

func goto(scene_key: String) -> void:
	if not SCENES.has(scene_key):
		push_error("Unknown scene: %s" % scene_key)
		return
	get_tree().change_scene_to_file(SCENES[scene_key])

func start_race(level_id: int, booster: String = "") -> void:
	pending_level = level_id
	pre_race_booster = booster
	goto("race")

func finish_race(position: int, double_coins: bool) -> void:
	last_result = Progression.complete_level(pending_level, position, double_coins)
	last_result["position"] = position
	last_result["level"] = pending_level
	goto("results")

func settings() -> Dictionary:
	return SaveManager.get_value("settings", {})

func set_setting(key: String, value: Variant) -> void:
	var s := settings()
	s[key] = value
	SaveManager.set_value("settings", s)
	Audio._apply_settings()

func quit() -> void:
	get_tree().quit()
