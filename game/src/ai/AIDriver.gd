extends Node
class_name AIDriver
## Racing AI: follows the track waypoints with a skill profile, looks ahead on
## corners, overtakes and recovers. Difficulty comes from behaviour, not from
## impossible speed multipliers.

var car: RaceCar
var waypoints: PackedVector3Array = PackedVector3Array()
var skill := 0.5          # 0..1
var current_index := 0
var lap := 1
var finished := false

var _look_ahead := 6.0
var _mistake_timer := 0.0
var _mistake_steer := 0.0
var _recover_timer := 0.0

func setup(p_car: RaceCar, p_waypoints: PackedVector3Array, p_skill: float) -> void:
	car = p_car
	waypoints = p_waypoints
	skill = clampf(p_skill, 0.1, 1.0)
	_look_ahead = lerpf(4.0, 9.0, skill)

func _physics_process(delta: float) -> void:
	if car == null or waypoints.is_empty() or finished:
		return

	# find the nearest forward waypoint (cheap: advance from last known)
	var target := _target_point()

	var to_target := target - car.global_position
	to_target.y = 0.0
	var desired_yaw := atan2(-to_target.x, -to_target.z)
	var yaw := car.global_rotation.y
	var diff := wrapf(desired_yaw - yaw, -PI, PI)

	# occasional "mistake" for lower-skill drivers
	_mistake_timer -= delta
	if _mistake_timer <= 0.0:
		_mistake_timer = randf_range(2.0, 6.0)
		_mistake_steer = randf_range(-0.35, 0.35) * (1.0 - skill)
	diff += _mistake_steer * (1.0 - skill)

	var steer := clampf(-diff * 1.6, -1.0, 1.0)
	car.steer = lerpf(car.steer, steer, 0.25)

	# throttle: back off for sharp corners, more on straights
	var corner := absf(diff)
	var target_throttle := 1.0
	if corner > 0.6:
		target_throttle = 0.55
	elif corner > 0.3:
		target_throttle = 0.8
	target_throttle *= lerpf(0.82, 1.0, skill)
	car.throttle = lerpf(car.throttle, target_throttle, 0.12)
	car.braking = corner > 1.1 and car.current_speed_kmh() > 90.0

	# boost on long straights when the AI has spare "nerve"
	if corner < 0.12 and car.boost_seconds <= 0.0 and randf() < 0.01 * skill:
		car.apply_boost(1.6)

	# stuck recovery: reverse out, then rejoin. (Playtest found 9s stalls.)
	if car.current_speed_kmh() < 12.0:
		_recover_timer += delta
		if _recover_timer > 1.0:
			# phase 1: back up while steering away from the obstacle
			car.throttle = 0.0
			car.braking = true
			car.steer = -signf(diff) if absf(diff) > 0.01 else 1.0
			if _recover_timer > 2.2:
				# phase 2: turn hard and go again
				car.braking = false
				car.throttle = 1.0
				car.steer = clampf(-diff * 1.6, -1.0, 1.0)
			if _recover_timer > 3.4:
				_recover_timer = 0.0
	else:
		_recover_timer = 0.0

func _target_point() -> Vector3:
	# advance index while the next waypoint is closer to us
	var best := current_index
	var best_d := car.global_position.distance_squared_to(waypoints[best])
	for step in range(1, 4):
		var idx := (current_index + step) % waypoints.size()
		var d := car.global_position.distance_squared_to(waypoints[idx])
		if d < best_d:
			best = idx
			best_d = d
	current_index = best
	# look ahead a few points for smoother cornering
	var ahead := (current_index + int(maxf(1.0, _look_ahead / 4.0))) % waypoints.size()
	return waypoints[ahead]
