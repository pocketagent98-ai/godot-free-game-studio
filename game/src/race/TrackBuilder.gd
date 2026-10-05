extends Node3D
class_name TrackBuilder
## Procedural track generator. From a level seed it builds a closed circuit:
## road ribbon, markings, barriers, checkpoints, start grid and scenery.

var waypoints := PackedVector3Array()
var checkpoints: Array[Vector3] = []
var start_transforms: Array[Transform3D] = []
var total_length := 0.0
var theme := "City"

const ROAD_WIDTH := 12.0
const SEGMENT := 10.0

func build(level: Dictionary) -> void:
	theme = String(level.get("theme", "City"))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(level.get("seed", 1234))
	var curviness := float(level.get("curviness", 0.5))
	var segments := int(level.get("length_segments", 30))

	_build_centerline(rng, curviness, segments)
	_build_road()
	_build_ground_collision()
	_build_markings()
	_build_barriers()
	_build_scenery(rng)
	_build_checkpoints()
	_build_start_grid()

func _build_centerline(rng: RandomNumberGenerator, curviness: float, segments: int) -> void:
	# A smooth CLOSED loop: points on a jittered circle. Guarantees the loop
	# closes cleanly with no giant final segment (found by playtest: the old
	# random-walk snapped the last point to the origin and jammed every car).
	var n := maxi(16, segments)
	var base_r := 45.0 + curviness * 55.0
	var radii: Array[float] = []
	for i in n:
		radii.append(base_r * (1.0 + rng.randf_range(-0.28, 0.28) * curviness))
	# Smooth the radii so the loop has no sharp spikes that trap cars.
	for _pass in 3:
		var smoothed: Array[float] = []
		for i in n:
			var a: float = radii[(i - 1 + n) % n]
			var b: float = radii[i]
			var c: float = radii[(i + 1) % n]
			smoothed.append((a + 2.0 * b + c) / 4.0)
		radii = smoothed
	waypoints.clear()
	for i in n:
		var ang := TAU * float(i) / float(n)
		waypoints.append(Vector3(sin(ang) * radii[i], 0.0, -cos(ang) * radii[i]))
	total_length = 0.0
	for i in n:
		total_length += waypoints[i].distance_to(waypoints[(i + 1) % n])

func _build_road() -> void:
	var mesh := _ribbon(ROAD_WIDTH, 0.02, _theme_color())
	add_child(mesh)

func _build_ground_collision() -> void:
	# The world needs a floor or the cars fall forever (found by playtest).
	var body := StaticBody3D.new()
	body.collision_layer = 0b0001
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1400, 40, 1400)      # thick, so fast cars cannot tunnel through
	cs.shape = box
	cs.position = Vector3(0, -20, 0)        # top surface sits at y = 0
	body.add_child(cs)
	add_child(body)

func _build_markings() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.95, 0.9)
	var mesh := _ribbon(0.35, 0.03, mat, 0.02)
	add_child(mesh)

func _theme_color() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	match theme:
		"Highway":
			mat.albedo_color = Color(0.16, 0.17, 0.19)
		"Industrial":
			mat.albedo_color = Color(0.20, 0.19, 0.18)
		"Circuit":
			mat.albedo_color = Color(0.12, 0.12, 0.14)
		_:
			mat.albedo_color = Color(0.18, 0.19, 0.21)
	mat.roughness = 0.9
	return mat

## Build a flat ribbon mesh following the centerline at a given width.
func _ribbon(width: float, y: float, mat: StandardMaterial3D, inset: float = 0.0) -> MeshInstance3D:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var count := waypoints.size()
	for i in count:
		var p := waypoints[i]
		var nxt := waypoints[(i + 1) % count]
		var dir := (nxt - p)
		dir.y = 0.0
		if dir.length() < 0.001:
			dir = Vector3(0, 0, -1)
		dir = dir.normalized()
		var side := Vector3(-dir.z, 0, dir.x)
		var half := (width * 0.5) - inset
		verts.append(p + side * half + Vector3(0, y, 0))
		verts.append(p - side * half + Vector3(0, y, 0))
		normals.append(Vector3.UP)
		normals.append(Vector3.UP)
		uvs.append(Vector2(0, float(i)))
		uvs.append(Vector2(1, float(i)))
	for i in count:
		var a := i * 2
		var b := a + 1
		var c := ((i + 1) % count) * 2
		var d := c + 1
		indices.append_array([a, c, b, b, c, d])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance3D.new()
	mi.mesh = am
	mi.material_override = mat
	return mi

func _build_barriers() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.2, 0.2)
	mat.roughness = 0.6
	var body := StaticBody3D.new()
	body.collision_layer = 0b0001
	add_child(body)
	for i in waypoints.size():
		if i % 2 != 0:
			continue
		var p := waypoints[i]
		var nxt := waypoints[(i + 1) % waypoints.size()]
		var dir := (nxt - p)
		dir.y = 0
		if dir.length() < 0.001:
			continue
		dir = dir.normalized()
		var side := Vector3(-dir.z, 0, dir.x)
		for s: float in [-1.0, 1.0]:
			var pos: Vector3 = p + side * s * (ROAD_WIDTH * 0.5 + 2.5)
			var mi := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.4, 0.8, SEGMENT * 0.6)
			mi.mesh = bm
			mi.material_override = mat
			mi.position = pos + Vector3(0, 0.4, 0)
			mi.rotation.y = atan2(dir.x, dir.z)
			add_child(mi)
			var cs := CollisionShape3D.new()
			var bs := BoxShape3D.new()
			bs.size = Vector3(0.4, 0.8, SEGMENT * 0.6)
			cs.shape = bs
			cs.position = mi.position
			body.add_child(cs)

func _build_scenery(rng: RandomNumberGenerator) -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(1200, 1200)
	ground.mesh = plane
	var gmat := StandardMaterial3D.new()
	match theme:
		"Suburban":
			gmat.albedo_color = Color(0.24, 0.34, 0.20)
		"Industrial":
			gmat.albedo_color = Color(0.28, 0.27, 0.25)
		_:
			gmat.albedo_color = Color(0.22, 0.26, 0.22)
	ground.material_override = gmat
	ground.position = Vector3(0, -0.05, 0)
	add_child(ground)

	# buildings along the outside of the track
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.35, 0.38, 0.44)
	var count := waypoints.size()
	for i in count:
		if i % 3 != 0:
			continue
		var p := waypoints[i]
		var nxt := waypoints[(i + 1) % count]
		var dir := (nxt - p)
		dir.y = 0
		if dir.length() < 0.001:
			continue
		dir = dir.normalized()
		var side := Vector3(-dir.z, 0, dir.x)
		for s: float in [-1.0, 1.0]:
			if rng.randf() > 0.7:
				continue
			var h: float = rng.randf_range(6.0, 26.0)
			var b := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(rng.randf_range(6, 12), h, rng.randf_range(6, 12))
			b.mesh = bm
			b.material_override = bmat
			b.position = p + side * s * (ROAD_WIDTH * 0.5 + rng.randf_range(10.0, 30.0)) + Vector3(0, h * 0.5, 0)
			add_child(b)

func _build_checkpoints() -> void:
	checkpoints.clear()
	var count := waypoints.size()
	var step := maxi(3, count / 6)
	var i := 0
	while i < count - 1:
		checkpoints.append(waypoints[i])
		i += step

func _build_start_grid() -> void:
	start_transforms.clear()
	var count := waypoints.size()
	# All six cars share the SAME start line and form a 2-column grid behind it.
	var base := waypoints[0]
	var nxt := waypoints[1 % count]
	var dir := (nxt - base)
	dir.y = 0
	if dir.length() < 0.001:
		dir = Vector3(0, 0, -1)
	dir = dir.normalized()
	var side := Vector3(-dir.z, 0, dir.x)
	for i in 6:
		var row := i / 2
		var col := i % 2
		var pos: Vector3 = base - dir * (float(row) * 6.0) + side * (1.0 if col == 0 else -1.0) * 3.0
		pos.y = 0.6
		var xf := Transform3D()
		xf = xf.looking_at(dir, Vector3.UP)
		xf.origin = pos
		start_transforms.append(xf)

func progress_for_position(pos: Vector3) -> float:
	# rough progress = nearest segment index + fraction
	var best_i := 0
	var best_d := INF
	for i in waypoints.size():
		var d := pos.distance_squared_to(waypoints[i])
		if d < best_d:
			best_d = d
			best_i = i
	return float(best_i)
