extends Node3D
class_name CarPreview
## Lightweight rotating car preview for the garage (meshes only, no physics).

var _spin := 0.0
var _body: MeshInstance3D
var _wheels: Array[MeshInstance3D] = []

func build(car_id: int, paint_id: int, wheel_id: int) -> void:
	for c in get_children():
		c.queue_free()
	_wheels.clear()

	var car := GameData.car(car_id)
	var paint := GameData.paint(paint_id)
	var wheel := GameData.wheel(wheel_id)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = paint.get("color", Color.CORNFLOWER_BLUE)
	mat.metallic = float(paint.get("metallic", 0.4))
	mat.roughness = float(paint.get("roughness", 0.4))

	_body = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.9, 0.6, 4.2)
	_body.mesh = bm
	_body.material_override = mat
	_body.position = Vector3(0, 0.6, 0)
	add_child(_body)

	var cabin := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(1.5, 0.5, 1.8)
	cabin.mesh = cm
	cabin.position = Vector3(0, 1.05, 0.1)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.15, 0.2, 0.28)
	glass.metallic = 0.6
	glass.roughness = 0.15
	cabin.material_override = glass
	add_child(cabin)

	var rim_mat := StandardMaterial3D.new()
	rim_mat.albedo_color = wheel.get("rim_color", Color.SILVER)
	rim_mat.metallic = 0.85
	rim_mat.roughness = 0.25
	var positions := [
		Vector3(-0.95, 0.36, -1.35), Vector3(0.95, 0.36, -1.35),
		Vector3(-0.95, 0.36, 1.35), Vector3(0.95, 0.36, 1.35),
	]
	for p in positions:
		var w := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = float(wheel.get("size", 0.36))
		cyl.bottom_radius = float(wheel.get("size", 0.36))
		cyl.height = 0.28
		cyl.radial_segments = 12 + int(wheel.get("spokes", 5)) * 2
		w.mesh = cyl
		w.material_override = rim_mat
		w.rotation_degrees = Vector3(0, 0, 90)
		w.position = p
		add_child(w)
		_wheels.append(w)

func _process(delta: float) -> void:
	_spin += delta * 0.6
	rotation.y = _spin
