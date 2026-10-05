extends Node3D
## RaceManager — builds the track, spawns the field, runs the flow:
## pre-race (booster ad) → countdown → race → checkpoints → finish → results.

var level_id := 0
var level_data: Dictionary = {}
var track: TrackBuilder
var player: RaceCar
var racers: Array[RaceCar] = []
var ai_drivers: Array[AIDriver] = []
var camera: ChaseCamera
var hud: RaceHUD

var started := false
var finished := false
var autopilot := false
var _ap_elapsed := 0.0
var _ap_log := 0.0
var countdown := 3.0
var race_time := 0.0
var player_lap := 1
var player_checkpoint := 0
var last_checkpoint_time := 0.0

const AI_CAR_POOL := [3, 8, 14, 21, 29, 37, 46, 55]

func _ready() -> void:
	level_id = Game.pending_level
	level_data = GameData.level(level_id)
	autopilot = "--autopilot" in OS.get_cmdline_args()
	_build()
	_setup_camera()
	_setup_hud()
	_spawn_field()
	if autopilot:
		_setup_autopilot()
	Audio.play("countdown")

func _build() -> void:
	track = TrackBuilder.new()
	add_child(track)
	track.build(level_data)
	# ambient light so the Compatibility renderer looks alive
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 35, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = false
	add_child(sun)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.5, 0.55, 0.65)
	e.ambient_light_energy = 0.6
	var sky := Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	e.sky = sky
	env.environment = e
	add_child(env)

func _setup_camera() -> void:
	camera = ChaseCamera.new()
	add_child(camera)

func _setup_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = RaceHUD.new()
	hud.race = self
	layer.add_child(hud)

func _spawn_field() -> void:
	var paint_id := Economy.selected_paint()
	var wheel_id := Economy.selected_wheel()
	var player_car_id := Economy.selected_car()
	var upgrade := Economy.upgrade_level(player_car_id)

	player = RaceCar.new()
	player.setup(player_car_id, paint_id, wheel_id, upgrade, true)
	add_child(player)
	player.global_transform = track.start_transforms[0]
	racers.append(player)
	camera.target = player

	var ai_skill := float(level_data.get("ai_skill", 0.5))
	var count := int(level_data.get("ai_count", 5))
	for i in count:
		var car_id: int = AI_CAR_POOL[i % AI_CAR_POOL.size()]
		var ai_car := RaceCar.new()
		ai_car.setup(car_id, (i * 5 + 3) % GameData.PAINT_COUNT,
			(i * 7 + 1) % GameData.WHEEL_COUNT, 0, false)
		add_child(ai_car)
		ai_car.global_transform = track.start_transforms[(i + 1) % track.start_transforms.size()]
		racers.append(ai_car)
		var driver := AIDriver.new()
		add_child(driver)
		driver.setup(ai_car, track.waypoints, clampf(ai_skill + randf_range(-0.08, 0.08), 0.15, 1.0))
		ai_drivers.append(driver)

func _process(delta: float) -> void:
	if not started:
		countdown -= delta
		if hud:
			hud.set_countdown(countdown)
		if countdown <= 0.0:
			started = true
			Audio.play("go")
			if hud:
				hud.hide_countdown()
			_apply_pre_race_booster()
		return

	race_time += delta
	_update_player_progress()
	_update_positions()
	_rescue_check(delta)
	if hud:
		hud.update_from(self)

	if player.finished and not finished:
		finished = true
		_end_race()

	if autopilot:
		_autopilot_tick(delta)

func _apply_pre_race_booster() -> void:
	if Game.pre_race_booster == "nitro":
		player.apply_boost(4.0)
		Game.pre_race_booster = ""

func _update_player_progress() -> void:
	if player.finished:
		return
	var idx := int(track.progress_for_position(player.global_position))
	# lap detection: passing the last checkpoint index wraps to 0
	if idx < player_checkpoint - 2 and player_checkpoint > 3:
		player_lap += 1
		Audio.play("checkpoint")
		if player_lap > int(level_data.get("laps", 2)):
			player.finished = true
	player_checkpoint = idx

func _update_positions() -> void:
	# score = (lap-1)*len + progress
	var scored: Array = []
	for i in racers.size():
		var car := racers[i]
		var prog := track.progress_for_position(car.global_position)
		var lap := 1
		if car == player:
			lap = player_lap
		else:
			# AI lap from its driver index wrap
			var driver := _driver_for(car)
			if driver:
				lap = driver.lap
		var score := float(lap - 1) * track.waypoints.size() + prog
		scored.append({"car": car, "score": score})
	scored.sort_custom(func(a, b): return a["score"] > b["score"])
	for i in scored.size():
		scored[i]["car"].set_meta("position", i + 1)
		if scored[i]["car"] == player:
			player_position = i + 1

var player_position := 1
var _stuck_time: Dictionary = {}

func _rescue_check(delta: float) -> void:
	# Standard arcade-racer rescue: if a car goes far off track or stalls too
	# long, put it back on the racing line. Prevents permanent deadlocks.
	for c in racers:
		if c.finished:
			continue
		var idx := int(track.progress_for_position(c.global_position))
		var wp: Vector3 = track.waypoints[idx]
		var dist := c.global_position.distance_to(wp)
		var key := c.get_instance_id()
		if c.current_speed_kmh() < 12.0:
			_stuck_time[key] = float(_stuck_time.get(key, 0.0)) + delta
		else:
			_stuck_time[key] = 0.0
		if dist > 30.0 or float(_stuck_time.get(key, 0.0)) > 3.0:
			_respawn(c, idx)

func _respawn(c: RaceCar, idx: int) -> void:
	var count := track.waypoints.size()
	var wp: Vector3 = track.waypoints[idx]
	var nxt: Vector3 = track.waypoints[(idx + 1) % count]
	var dir := (nxt - wp)
	dir.y = 0
	if dir.length() < 0.001:
		dir = Vector3(0, 0, -1)
	dir = dir.normalized()
	var xf := Transform3D()
	xf = xf.looking_at(dir, Vector3.UP)
	xf.origin = wp + Vector3(0, 0.6, 0)
	c.reset_to(xf)
	_stuck_time[c.get_instance_id()] = 0.0
	if autopilot:
		print("[PLAYTEST] respawn %s at wp %d" % ["player" if c == player else "ai", idx])

func _driver_for(car: RaceCar) -> AIDriver:
	for d in ai_drivers:
		if d.car == car:
			return d
	return null

func _end_race() -> void:
	Audio.play("finish")
	if autopilot:
		_autopilot_report("FINISH")
		get_tree().quit()
		return
	Game.finish_race(player_position, false)

func nearest_waypoint_index(pos: Vector3) -> int:
	return int(track.progress_for_position(pos))

# ------------------------------------------------------------- playtest ---- #
func _setup_autopilot() -> void:
	Engine.time_scale = 1.0
	countdown = 0.05
	var bot := AIDriver.new()
	add_child(bot)
	bot.setup(player, track.waypoints, 0.9)
	ai_drivers.append(bot)
	print("[PLAYTEST] autopilot on waypoints=%d laps=%d racers=%d" % [
		track.waypoints.size(), int(level_data.get("laps", 2)), racers.size()])

func _autopilot_tick(delta: float) -> void:
	_ap_elapsed += delta
	_ap_log += delta
	if _ap_log >= 1.0:
		_ap_log = 0.0
		var min_y := 999.0
		var ai_speed := 0.0
		var ai_n := 0
		for c in racers:
			min_y = minf(min_y, c.global_position.y)
			if c != player:
				ai_speed += c.current_speed_kmh()
				ai_n += 1
		print("[PLAYTEST] t=%.1f pos=%d lap=%d spd=%.0f py=%.2f pvy=%.2f pxz=(%.1f,%.1f) minY=%.2f aiAvg=%.0f" % [
			_ap_elapsed, player_position, player_lap, player.current_speed_kmh(),
			player.global_position.y, player.linear_velocity.y,
			player.global_position.x, player.global_position.z,
			min_y, ai_speed / maxf(1.0, float(ai_n))])
	if _ap_elapsed > 150.0:
		_autopilot_report("TIMEOUT")
		get_tree().quit()

func _autopilot_report(tag: String) -> void:
	var ai_speed := 0.0
	var ai_n := 0
	var moving := 0
	var min_y := 999.0
	for c in racers:
		min_y = minf(min_y, c.global_position.y)
		if c.current_speed_kmh() > 5.0:
			moving += 1
		if c != player:
			ai_speed += c.current_speed_kmh()
			ai_n += 1
	print("[PLAYTEST] %s elapsed=%.1fs pos=%d lap=%d/%d playerSpd=%.0f aiAvg=%.0f moving=%d/%d minY=%.2f" % [
		tag, _ap_elapsed, player_position, player_lap, int(level_data.get("laps", 2)),
		player.current_speed_kmh(), ai_speed / maxf(1.0, float(ai_n)), moving, racers.size(), min_y])
