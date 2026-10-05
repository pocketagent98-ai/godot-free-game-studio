extends Node
## SaveManager — versioned, corruption-tolerant local save (offline-first).

const SAVE_PATH := "user://turbo_rush_save.json"
const SAVE_VERSION := 1

var data: Dictionary = {}

func _ready() -> void:
	load_game()

func default_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"coins": 500,
		"diamonds": 5,
		"current_level": 0,
		"completed_levels": [],
		"unlocked_cars": [0],
		"unlocked_paints": [0, 1, 2, 3, 4, 5, 6, 7],
		"unlocked_wheels": [0, 1, 2, 3, 4, 5],
		"selected_car": 0,
		"selected_paint": 0,
		"selected_wheel": 0,
		"upgrades": {},
		"settings": {
			"music": 0.7,
			"sfx": 0.9,
			"steer_sensitivity": 1.0,
			"haptics": true,
			"left_handed": false,
		},
		"daily": {
			"date": "",
			"tasks": [],
			"claimed": [],
			"ads_watched_today": 0,
		},
		"stats": {"races": 0, "wins": 0, "best_positions": {}},
	}

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		data = default_data()
		save_game()
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		data = default_data()
		return
	var text := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Save corrupted; starting fresh.")
		data = default_data()
		save_game()
		return
	# migrate + fill missing keys
	var def := default_data()
	for key in def.keys():
		if not parsed.has(key):
			parsed[key] = def[key]
	parsed["version"] = SAVE_VERSION
	data = parsed

func save_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Could not write save file.")
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()

func get_value(key: String, fallback: Variant = null) -> Variant:
	return data.get(key, fallback)

func set_value(key: String, value: Variant) -> void:
	data[key] = value
	save_game()

func reset() -> void:
	data = default_data()
	save_game()
