extends RigidBody3D
class_name RaceCar
## Arcade car controller. Tuned for touch screens: responsive, forgiving,
## fun — not a simulation. Body is a RigidBody3D driven by forces.

signal crashed(force: float)
signal boost_used

var stats: Dictionary = {}
var is_player := false
var paint_data: Dictionary = {}
var wheel_data: Dictionary = {}

# control state (set by player input or by the AI driver)
var throttle := 0.0
var steer := 0.0
var braking := false
var drifting := false

var boost_seconds := 0.0
var boost_power := 1.3

var lap := 1
var finished := false

var _body_mesh: MeshInstance3D
var _wheels: Array[Node3D] = []
var _front_wheels: Array[Node3D] = []
var _wheel_spin := 0.0
var _speed := 0.0
var _crash_cooldown := 0.0

const WHEEL_RADIUS := 0.36

func setup(car_id: int, paint_id: int, wheel_id: int, upgrade_lvl: int, player: bool) -> void:
	stats = GameData.car(car_id).duplicate()
	paint_data = GameData.paint(paint_id)
	wheel_data = GameData.wheel(wheel_id)
	is_player = player
	# apply upgrades
	var up_mult := 1.0 + 0.06 * float(upgrade_lvl)
	stats["top_speed"] = float(stats["top_speed"]) * up_mult
	stats["acceleration"] = float(stats["acceleration"]) * up_mult

func _ready() -> void:
	mass = float(stats.get("weight", 1200.0)) / 100.0
	contact_monitor = true
	max_contacts_reported = 4
	continuous_cd = true
	gravity_scale = 1.0
	# Low friction: a box with default friction (1.0) cannot overcome its own
	# static friction and never moves. Found by playtest.
	var pm := PhysicsMaterial.new()
	pm.friction = 0.08
	pm.bounce = 0.0
	physics_material_override = pm
	_build_visuals()
	body_entered.connect(_on_body_entered)
	if is_player:
		collision_layer = 0b0010
		collision_mask = 0b0001 | 0b0100
	else:
		collision_layer = 0b0100
		collision_mask = 0b0001 | 0b0010 | 0b0100

func _build_visuals() -> void:
	# collision shape
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.9, 0.6, 4.2)
	shape.shape = box
	shape.position = Vector3(0, 0.30, 0)   # wheels rest on the ground at y = 0
	add_child(shape)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = paint_data.get("color", Color.CORNFLOWER_BLUE)
	mat.metallic = float(paint_data.get("metallic", 0.4))
	mat.roughness = float(paint_data.get("roughness", 0.4))

	_body_mesh = MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(1.9, 0.6, 4.2)
	_body_mesh.mesh = body_mesh
	_body_mesh.material_override = mat
	_body_mesh.position = Vector3(0, 0.55, 0)
	add_child(_body_mesh)

	# cabin
	var cabin := MeshInstance3D.new()
	var cabin_mesh := BoxMesh.new()
	cabin_mesh.size = Vector3(1.5, 0.5, 1.8)
	cabin.mesh = cabin_mesh
	cabin.position = Vector3(0, 1.0, 0.1)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.15, 0.2, 0.28, 0.9)
	glass.metallic = 0.6
	glass.roughness = 0.15
	cabin.material_override = glass
	add_child(cabin)

	# wheels
	var rim_mat := StandardMaterial3D.new()
	rim_mat.albedo_color = wheel_data.get("rim_color", Color.SILVER)
	rim_mat.metallic = 0.85
	rim_mat.roughness = 0.25
	var positions := [
		Vector3(-0.95, WHEEL_RADIUS, -1.35),
		Vector3(0.95, WHEEL_RADIUS, -1.35),
		Vector3(-0.95, WHEEL_RADIUS, 1.35),
		Vector3(0.95, WHEEL_RADIUS, 1.35),
	]
	for i in positions.size():
		var hub := Node3D.new()
		hub.position = positions[i]
		add_child(hub)
		var w := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = float(wheel_data.get("size", WHEEL_RADIUS))
		cyl.bottom_radius = float(wheel_data.get("size", WHEEL_RADIUS))
		cyl.height = 0.28
		cyl.radial_segments = 12 + int(wheel_data.get("spokes", 5)) * 2
		w.mesh = cyl
		w.material_override = rim_mat
		w.rotation_degrees = Vector3(0, 0, 90)
		hub.add_child(w)
		_wheels.append(w)
		if i < 2:
			_front_wheels.append(hub)

func _physics_process(delta: float) -> void:
	if finished:
		throttle = 0.0
		steer = 0.0

	var xform := global_transform.basis
	var forward := -xform.z
	var right := xform.x
	_speed = linear_velocity.dot(forward)

	# --- engine ---------------------------------------------------------
	var top_speed := float(stats.get("top_speed", 170.0))
	var accel := float(stats.get("acceleration", 20.0))
	var boosting := boost_seconds > 0.0
	if boosting:
		boost_seconds = maxf(0.0, boost_seconds - delta)
		accel *= boost_power
		top_speed *= boost_power

	if throttle > 0.01 and _speed < top_speed:
		apply_central_force(forward * accel * throttle * mass)
	if braking:
		# brake / reverse
		var brake_force := float(stats.get("braking", 26.0)) * mass
		if _speed > 0.5:
			apply_central_force(-forward * brake_force)
		else:
			apply_central_force(-forward * accel * 0.5 * mass)

	# --- steering -------------------------------------------------------
	var steer_response := float(stats.get("steering", 0.95))
	var speed_factor := clampf(absf(_speed) / 40.0, 0.0, 1.0)
	var target_yaw := -steer * steer_response * speed_factor * 2.4
	angular_velocity = Vector3(0, lerpf(angular_velocity.y, target_yaw, 0.25), 0)

	# --- grip / drift ---------------------------------------------------
	var grip := float(stats.get("grip", 0.75))
	if drifting:
		grip *= 0.45
	var lateral := linear_velocity.dot(right)
	apply_central_force(-right * lateral * grip * mass * 2.0)

	# --- downforce + anti-roll -----------------------------------------
	# Gentle and capped: a strong downforce made the body sink into the road.
	apply_central_force(Vector3(0, -minf(absf(_speed), 60.0) * 0.06 * mass, 0))

	# --- crash cooldown -------------------------------------------------
	if _crash_cooldown > 0.0:
		_crash_cooldown -= delta

	_update_wheel_visuals(delta, steer)

func _update_wheel_visuals(delta: float, steer_input: float) -> void:
	_wheel_spin += _speed * delta / WHEEL_RADIUS
	for w in _wheels:
		w.rotation = Vector3(_wheel_spin, 0, deg_to_rad(90))
	for hub in _front_wheels:
		hub.rotation.y = lerpf(hub.rotation.y, -steer_input * 0.5, 0.3)

func apply_boost(seconds: float = 2.5) -> void:
	boost_seconds = maxf(boost_seconds, seconds)
	boost_used.emit()
	Audio.play("boost")

func current_speed_kmh() -> float:
	return absf(_speed) * 3.6

func _on_body_entered(_body: Node) -> void:
	if _crash_cooldown > 0.0:
		return
	var impact := absf(_speed)
	if impact > 8.0:
		_crash_cooldown = 0.5
		Audio.play("crash")
		crashed.emit(impact)

func reset_to(transform_xf: Transform3D) -> void:
	global_transform = transform_xf
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
