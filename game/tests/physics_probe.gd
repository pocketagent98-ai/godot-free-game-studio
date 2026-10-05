extends Node3D
## physics_probe — drops a single car on the generated track and reports its
## resting height, so we can verify the car sits ON the road, not inside it.

var car: RaceCar
var t := 0.0
var _next := 0.0

func _ready() -> void:
	var tb := TrackBuilder.new()
	add_child(tb)
	tb.build(GameData.level(0))
	car = RaceCar.new()
	car.setup(0, 0, 0, 0, true)
	add_child(car)
	car.global_transform = tb.start_transforms[0]
	print("[PROBE] spawn y=%.2f  (collision box centre offset = 0.30)" % car.global_position.y)

func _physics_process(delta: float) -> void:
	t += delta
	# after settling, drive forward to reproduce the "sinking while moving" bug
	if t > 1.5:
		car.throttle = 1.0
	if t > 2.5:
		car.steer = 0.6
	if t >= _next:
		_next += 0.25
		var contacts := 0
		if car.contact_monitor:
			contacts = car.get_contact_count()
		print("[PROBE] t=%.2f y=%.3f vy=%.2f spd=%.0f contacts=%d" % [
			t, car.global_position.y, car.linear_velocity.y,
			car.current_speed_kmh(), contacts])
	if t > 4.0:
		get_tree().quit()
