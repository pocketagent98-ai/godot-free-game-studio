extends Camera3D
class_name ChaseCamera
## Smooth chase camera with speed-based FOV, look-ahead and subtle shake.

var target: RaceCar
var _current_pos := Vector3.ZERO
var _shake := 0.0

const BASE_OFFSET := Vector3(0, 3.2, 7.5)
const BASE_FOV := 68.0

func _ready() -> void:
	fov = BASE_FOV
	current = true

func _physics_process(delta: float) -> void:
	if target == null:
		return
	var speed := target.current_speed_kmh()
	var back := BASE_OFFSET.z + clampf(speed / 120.0, 0.0, 1.0) * 3.0
	var offset := Vector3(BASE_OFFSET.x, BASE_OFFSET.y + clampf(speed / 300.0, 0.0, 1.0), back)
	var desired := target.global_transform * offset
	_current_pos = _current_pos.lerp(desired, clampf(delta * 6.0, 0.0, 1.0))
	global_position = _current_pos
	# look slightly ahead of the car
	var ahead := target.global_position - target.global_transform.basis.z * 6.0 + Vector3(0, 1.0, 0)
	look_at(ahead, Vector3.UP)

	var target_fov := BASE_FOV + clampf(speed / 160.0, 0.0, 1.0) * 12.0
	if target.boost_seconds > 0.0:
		target_fov += 8.0
	fov = lerpf(fov, target_fov, clampf(delta * 4.0, 0.0, 1.0))

	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 3.0)
		global_position += Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * _shake * 0.15

func shake(amount: float) -> void:
	_shake = maxf(_shake, clampf(amount, 0.0, 1.0))
