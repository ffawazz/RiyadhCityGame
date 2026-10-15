class_name CarDamage
extends RefCounted
## Crash damage for the family car: dents, a lifted hood, hanging bumpers, broken lights,
## cracked and shattered glass, a mirror knocked off line, steam / smoke / flames, plus a
## performance penalty. Damage is kept in Game so it persists between scenes; it is repaired
## at the Mazda Service garage or by going home.

var car: Car
var parts: Dictionary = {}       # named model nodes handed over by the Car
var _sparks: CPUParticles3D
var _smoke: CPUParticles3D
var _fire: CPUParticles3D
var _windshield_mat: StandardMaterial3D
var _glass_mat: StandardMaterial3D
var _rng := RandomNumberGenerator.new()


func _init(owner_car: Car, model_parts: Dictionary) -> void:
	car = owner_car
	parts = model_parts
	_rng.randomize()
	_windshield_mat = parts["windshield_mat"]
	_glass_mat = parts["glass_mat"]
	_sparks = _make_particles(0.5, 14, Color(1.0, 0.85, 0.3), 0.12, true, Vector3(0, -6, 0), 6.0)
	_sparks.one_shot = true
	_smoke = _make_particles(1.4, 24, Color(0.75, 0.75, 0.75, 0.6), 0.5, false, Vector3(0, 1.2, 0), 1.2)
	_fire = _make_particles(0.6, 22, Color(1.0, 0.55, 0.1, 0.9), 0.35, false, Vector3(0, 2.5, 0), 1.5)
	_smoke.position = Vector3(0, 1.2, -1.7)
	_fire.position = Vector3(0, 1.2, -1.8)
	car.add_child(_smoke)
	car.add_child(_fire)
	car.add_child(_sparks)


func health() -> float:
	return clampf(100.0 - Game.car_damage, 0.0, 100.0)


## 1.0 when new, down to 0.55 when wrecked.
func perf() -> float:
	return lerpf(1.0, 0.55, clampf(Game.car_damage / 100.0, 0.0, 1.0))


## Rebuild the look of the car from the stored hits (when a scene loads).
func replay() -> void:
	var hits: Array = Game.car_hits.duplicate()
	for h: Dictionary in hits:
		_apply(h["n"], h["s"], false)
	_apply_thresholds()


## `local_n`: the wall's normal in the car's own frame (+z = front hit, -z = rear, +x = left side).
func take_hit(local_n: Vector3, strength: float) -> void:
	if strength < 3.0:
		return
	Game.car_damage = minf(100.0, Game.car_damage + (strength - 3.0) * 1.7)
	Game.car_hits.append({"n": local_n, "s": strength})
	if Game.car_hits.size() > 14:
		Game.car_hits.pop_front()
	_apply(local_n, strength, true)
	_apply_thresholds()


func repair() -> void:
	Game.car_damage = 0.0
	Game.car_hits.clear()
	for k in parts:
		if parts[k] is Node3D and k != "windshield_mat" and k != "glass_mat":
			var n: Node3D = parts[k]
			if n.has_meta("rest"):
				var rest: Transform3D = n.get_meta("rest")
				n.transform = rest
				n.visible = true
	for dent: Node in car.get_children():
		if dent.has_meta("dent"):
			dent.queue_free()
	_windshield_mat.albedo_color = Color(0.35, 0.5, 0.62, 0.28)
	_glass_mat.albedo_color = Color(0.35, 0.5, 0.62, 0.28)
	for l: Node3D in parts["headlights"]:
		l.visible = true
	for l: Node3D in parts["taillights"]:
		l.visible = true
	_smoke.emitting = false
	_fire.emitting = false
	car.steer_pull = 0.0


func _apply(n: Vector3, strength: float, effects: bool) -> void:
	var amount := clampf((strength - 3.0) / 12.0, 0.15, 1.5)
	_remember_rest()
	var hit_pos := Vector3(0.0, 0.9, 0.0)
	if n.z > 0.4:                                    # --- front hit ---
		hit_pos = Vector3(_rng.randf_range(-0.7, 0.7), 0.9, -2.5)
		var hood: Node3D = parts["hood"]
		hood.rotation_degrees.x += 4.5 * amount
		hood.position.y += 0.03 * amount
		hood.scale.z = maxf(0.78, hood.scale.z - 0.05 * amount)
		var fb: Node3D = parts["front_bumper"]
		fb.position.z += 0.06 * amount
		fb.rotation_degrees.x -= 7.0 * amount
		fb.rotation_degrees.z += _rng.randf_range(-4.0, 4.0) * amount
		var grille: Node3D = parts["grille"]
		grille.rotation_degrees.z += _rng.randf_range(-6.0, 6.0) * amount
		grille.position.z += 0.05 * amount
	elif n.z < -0.4:                                 # --- rear hit ---
		hit_pos = Vector3(_rng.randf_range(-0.7, 0.7), 0.9, 2.5)
		var rb: Node3D = parts["rear_bumper"]
		rb.position.z -= 0.06 * amount
		rb.rotation_degrees.x += 7.0 * amount
		rb.rotation_degrees.z += _rng.randf_range(-4.0, 4.0) * amount
		var tg: Node3D = parts["tailgate_bar"]
		tg.rotation_degrees.z += _rng.randf_range(-8.0, 8.0) * amount
	if absf(n.x) > 0.4:                              # --- side hit ---
		var side := -signf(n.x)                      # -1 = left side of the car
		hit_pos = Vector3(side * 1.0, 0.8, _rng.randf_range(-1.5, 1.8))
		_dent(Vector3(side * 0.985, 0.75, hit_pos.z), side, amount)
		var mirror: Node3D = parts["mirror_l"] if side < 0.0 else parts["mirror_r"]
		mirror.rotation_degrees.y += side * 28.0 * amount
		mirror.rotation_degrees.z += side * 12.0 * amount
		if hit_pos.z < -0.6:
			var wheel: Node3D = parts["wheel_fl"] if side < 0.0 else parts["wheel_fr"]
			wheel.set_meta("toe", float(wheel.get_meta("toe", 0.0)) + 0.1 * amount * -side)
		car.steer_pull += 0.012 * amount * side
	if absf(n.x) <= 0.4:
		_dent(hit_pos, 0.0, amount)
	if effects:
		_sparks.position = hit_pos
		_sparks.amount = int(10 + 14 * amount)
		_sparks.restart()
		_sparks.emitting = true


## A crumpled patch on the bodywork.
func _dent(pos: Vector3, side: float, amount: float) -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	var along_z := absf(side) > 0.1
	box.size = Vector3(0.05, 0.25 + 0.3 * amount, 0.5 + 0.7 * amount) if along_z else Vector3(0.5 + 0.7 * amount, 0.25 + 0.2 * amount, 0.05)
	mi.mesh = box
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.05, 0.12, 0.28)
	m.roughness = 0.9
	mi.material_override = m
	mi.position = pos
	mi.rotation_degrees = Vector3(_rng.randf_range(-10, 10), _rng.randf_range(-8, 8), _rng.randf_range(-12, 12))
	mi.set_meta("dent", true)
	car.add_child(mi)
	# a bright scratch beside it
	var sc := MeshInstance3D.new()
	var sb := BoxMesh.new()
	sb.size = Vector3(0.02, 0.03, 0.8) if along_z else Vector3(0.8, 0.03, 0.02)
	sc.mesh = sb
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.8, 0.82, 0.85)
	sc.material_override = sm
	sc.position = pos + (Vector3(side * 0.012, 0.18, 0.0) if along_z else Vector3(0.0, 0.18, 0.012))
	sc.rotation_degrees.y = _rng.randf_range(-15, 15)
	sc.set_meta("dent", true)
	car.add_child(sc)


func _apply_thresholds() -> void:
	var d := Game.car_damage
	var lights_on: Array = parts["headlights"]
	var tails: Array = parts["taillights"]
	if d > 25.0 and lights_on.size() > 0:
		(lights_on[0] as Node3D).visible = false
	if d > 55.0 and lights_on.size() > 1:
		(lights_on[1] as Node3D).visible = false
	if d > 45.0 and tails.size() > 0:
		(tails[0] as Node3D).visible = false
	if d > 30.0:
		_windshield_mat.albedo_color = Color(0.82, 0.88, 0.95, 0.55)      # cracked
	if d > 55.0:
		_glass_mat.albedo_color = Color(0.7, 0.78, 0.86, 0.5)
	if d > 78.0:
		(parts["windshield"] as Node3D).visible = false                  # shattered
	_smoke.emitting = d > 35.0
	_smoke.color = Color(0.9, 0.9, 0.9, 0.5) if d < 60.0 else Color(0.15, 0.15, 0.15, 0.75)
	_fire.emitting = d > 88.0


func _remember_rest() -> void:
	for k in parts:
		if parts[k] is Node3D and not parts[k].has_meta("rest") and k != "windshield_mat":
			(parts[k] as Node3D).set_meta("rest", (parts[k] as Node3D).transform)


func _make_particles(life: float, count: int, color: Color, size: float, sparks: bool, gravity: Vector3, speed: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.emitting = false
	p.amount = count
	p.lifetime = life
	p.direction = Vector3(0, 1, 0)
	p.spread = 60.0 if sparks else 25.0
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity = gravity
	p.color = color
	p.local_coords = false
	var mesh := SphereMesh.new()
	mesh.radius = size
	mesh.height = size * 2.0
	mesh.radial_segments = 5
	mesh.rings = 3
	p.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	p.material_override = mat
	if not sparks:
		var curve := Curve.new()
		curve.add_point(Vector2(0, 0.4))
		curve.add_point(Vector2(1, 1.8))
		p.scale_amount_curve = curve
		var grad := Gradient.new()
		grad.set_color(0, Color(1, 1, 1, 0.8))
		grad.set_color(1, Color(1, 1, 1, 0.0))
		p.color_ramp = grad
	return p
