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
var countdown := 3.0
var race_time := 0.0
var player_lap := 1
var player_checkpoint := 0
var last_checkpoint_time := 0.0

const AI_CAR_POOL := [3, 8, 14, 21, 29, 37, 46, 55]

func _ready() -> void:
	level_id = Game.pending_level
	level_data = GameData.level(level_id)
	_build()
	_setup_camera()
	_setup_hud()
	_spawn_field()
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
	if hud:
		hud.update_from(self)

	if player.finished and not finished:
		finished = true
		_end_race()

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

func _driver_for(car: RaceCar) -> AIDriver:
	for d in ai_drivers:
		if d.car == car:
			return d
	return null

func _end_race() -> void:
	Audio.play("finish")
	Game.finish_race(player_position, false)

func nearest_waypoint_index(pos: Vector3) -> int:
	return int(track.progress_for_position(pos))
