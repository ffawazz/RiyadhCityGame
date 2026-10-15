class_name RiyadhBuilder
extends RefCounted
## Builds Riyadh-style architecture for the driving scenes (low-poly, all in code):
##  * Najdi villas   - sand-coloured compounds with walls, triangular crenellations and
##                     triangle-window bands under the parapet
##  * mid-rise blocks - window grids, shop signboards, rooftop water tanks
##  * glass towers   - the business-district skyline, stepped crowns, pyramid tops
##  * landmarks      - Kingdom Centre (with the sky-bridge opening), Al Faisaliyah (sphere
##                     and spire), Masmak Fort (mud-brick towers), mosques with minarets

const SHADER := """
shader_type spatial;
uniform vec4 base_color : source_color = vec4(0.85, 0.75, 0.6, 1.0);
uniform vec4 glass_color : source_color = vec4(0.25, 0.4, 0.55, 1.0);
uniform int style = 1;          // 0 plain, 1 window grid, 2 Najdi, 3 glass curtain wall
uniform float top_y = 10.0;
varying vec3 wpos;
varying vec3 wnrm;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	vec3 col = base_color.rgb;
	float metal = 0.0;
	float rough = 1.0;
	bool wall = abs(wnrm.y) < 0.5 && wpos.y > 0.6;
	float along = (abs(wnrm.x) > 0.5) ? wpos.z : wpos.x;
	if (wall && style == 1) {
		vec2 cell = vec2(fract(along / 4.5), fract(wpos.y / 3.6));
		float w = step(0.2, cell.x) * step(cell.x, 0.8) * step(0.25, cell.y) * step(cell.y, 0.75);
		col = mix(col, glass_color.rgb, w);
	} else if (wall && style == 2) {
		vec2 c = vec2(fract(along / 3.2), fract(wpos.y / 3.4));
		float w = step(0.38, c.x) * step(c.x, 0.62) * step(0.3, c.y) * step(c.y, 0.72);
		float low = step(wpos.y, top_y - 2.4);
		col = mix(col, vec3(0.2, 0.13, 0.08), w * low);
		// Najdi triangle band under the parapet
		float by = (wpos.y - (top_y - 2.2)) / 1.4;
		vec2 t = vec2(fract(along / 1.6), by);
		float tri = step(0.0, by) * step(by, 1.0) * step(t.y, 1.0 - abs(2.0 * t.x - 1.0));
		col = mix(col, vec3(0.32, 0.21, 0.12), tri);
	} else if (wall && style == 3) {
		float g = clamp(wpos.y / max(top_y, 1.0), 0.0, 1.0);
		vec3 gc = mix(glass_color.rgb * 0.7, glass_color.rgb * 1.3, g);
		vec2 c = vec2(fract(along / 2.2), fract(wpos.y / 3.4));
		float line = clamp(step(c.x, 0.05) + step(c.y, 0.06), 0.0, 1.0);
		col = mix(gc, base_color.rgb, line * 0.55);
		metal = 0.4;
		rough = 0.3;
	}
	ALBEDO = col;
	METALLIC = metal;
	ROUGHNESS = rough;
}
"""

const SAND := ["e8d8b0", "d9c7a0", "f0e6d0", "c9b58a", "e3c9a0", "d8b98a", "f2e8d2", "cfae80"]
const SIGNS := ["e63946", "2a9d8f", "f4a261", "457b9d", "e9c46a", "6a994e", "f1faee", "9b5de5"]
const GLASS := ["4a6f8f", "3f7f86", "5a7fa6", "6b8a9a", "3d5f80"]

static var _shader: Shader

var scene: Node3D
var rng: RandomNumberGenerator
var _mats: Dictionary = {}
var _merlons: Array[Transform3D] = []
var _tanks: Array[Transform3D] = []


func _init(scene_ref: Node3D, random: RandomNumberGenerator) -> void:
	scene = scene_ref
	rng = random


# ---- low-level pieces ---------------------------------------------------------

func flat(color: Color, metallic: float = 0.0, rough: float = 0.9) -> StandardMaterial3D:
	var key := "%s_%.1f_%.1f" % [color.to_html(), metallic, rough]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = rough
	_mats[key] = m
	return m


func wall_material(color: Color, style: int, top_y: float, glass: Color) -> ShaderMaterial:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	var m := ShaderMaterial.new()
	m.shader = _shader
	m.set_shader_parameter("base_color", color)
	m.set_shader_parameter("glass_color", glass)
	m.set_shader_parameter("style", style)
	m.set_shader_parameter("top_y", top_y)
	return m


## A solid (collidable) box. `style` picks the facade pattern in the shader.
func solid(rect: Rect2, height: float, color: Color, style: int, y0: float = 0.0,
		glass: Color = Color.html("4a6f8f")) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = Vector3(rect.get_center().x, y0 + height * 0.5, rect.get_center().y)
	var shape := BoxShape3D.new()
	shape.size = Vector3(rect.size.x, height, rect.size.y)
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = shape.size
	mi.mesh = bm
	mi.material_override = wall_material(color, style, y0 + height, glass)
	body.add_child(mi)
	scene.add_child(body)
	return body


## A visual-only box (no collision).
func deco(pos: Vector3, size: Vector3, color: Color, rot_y_deg: float = 0.0, metallic: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.rotation_degrees.y = rot_y_deg
	mi.material_override = flat(color, metallic)
	scene.add_child(mi)
	return mi


func label(text: String, pos: Vector3, font_px: int = 96, pixel: float = 0.06) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = font_px
	l.pixel_size = pixel
	l.outline_size = 24
	l.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	l.position = pos
	scene.add_child(l)
	return l


func multi(mesh: Mesh, mat: Material, xforms: Array) -> MultiMeshInstance3D:
	var mmi := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
	mmi.multimesh = mm
	mmi.material_override = mat
	scene.add_child(mmi)
	return mmi


## Najdi crenellations: a row of little triangular teeth along the roof edge.
func merlons(rect: Rect2, y: float) -> void:
	var gap := 1.3
	var x := rect.position.x + 0.6
	while x < rect.end.x - 0.5:
		for zz: float in [rect.position.y + 0.2, rect.end.y - 0.2]:
			_merlons.append(Transform3D(Basis.IDENTITY, Vector3(x, y + 0.45, zz)))
		x += gap
	var z := rect.position.y + 1.8
	while z < rect.end.y - 1.5:
		for xx: float in [rect.position.x + 0.2, rect.end.x - 0.2]:
			_merlons.append(Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(xx, y + 0.45, z)))
		z += gap


func rooftop_tanks(rect: Rect2, y: float, count: int) -> void:
	for i in count:
		var p := Vector3(rng.randf_range(rect.position.x + 2.0, rect.end.x - 2.0), y + 0.8,
				rng.randf_range(rect.position.y + 2.0, rect.end.y - 2.0))
		_tanks.append(Transform3D(Basis.IDENTITY, p))


## Call once after everything is placed: merges merlons and tanks into MultiMeshes.
func finish() -> void:
	if not _merlons.is_empty():
		var prism := PrismMesh.new()
		prism.size = Vector3(0.9, 0.9, 0.35)
		multi(prism, flat(Color.html("d8c29d")), _merlons)
	if not _tanks.is_empty():
		var tank := CylinderMesh.new()
		tank.top_radius = 0.9
		tank.bottom_radius = 0.9
		tank.height = 1.6
		tank.radial_segments = 8
		multi(tank, flat(Color.html("f2f2f0")), _tanks)


# ---- typical Riyadh building types ----------------------------------------------

func sand_color() -> Color:
	return Color.html(SAND[rng.randi() % SAND.size()])


## Najdi-style villa: walled compound, stepped two-storey house, palms in the yard.
func villa(lot: Rect2, height: float, color: Color) -> void:
	_wall_ring(lot, 2.6, color.darkened(0.05))
	var body := lot.grow(-9.0)
	solid(body, height, color, 2)
	merlons(body, height)
	var upper := Rect2(body.position.x + body.size.x * 0.12, body.position.y + body.size.y * 0.15,
			body.size.x * 0.55, body.size.y * 0.55)
	solid(upper, 3.4, color.lightened(0.05), 2, height)
	merlons(upper, height + 3.4)
	rooftop_tanks(body, height, 1)
	for p in [lot.position + Vector2(4.5, 4.5), lot.end - Vector2(4.5, 4.5)]:
		scene.call("add_palm_at", p)


## Mid-rise apartments / shops: window grid, colourful signboards, rooftop tanks.
func midrise(lot: Rect2, height: float, color: Color) -> void:
	var r := lot.grow(-4.0)
	solid(r, height, color, 1, 0.0, Color.html(GLASS[rng.randi() % GLASS.size()]))
	merlons(r, height)
	rooftop_tanks(r, height, 2)
	var sign_color := Color.html(SIGNS[rng.randi() % SIGNS.size()])
	deco(Vector3(r.get_center().x, 3.6, r.position.y - 0.15), Vector3(r.size.x * 0.7, 1.3, 0.3), sign_color)
	deco(Vector3(r.get_center().x, 3.6, r.end.y + 0.15), Vector3(r.size.x * 0.7, 1.3, 0.3), Color.html(SIGNS[rng.randi() % SIGNS.size()]))
	deco(Vector3(r.position.x - 0.15, 3.6, r.get_center().y), Vector3(0.3, 1.3, r.size.y * 0.7), Color.html(SIGNS[rng.randi() % SIGNS.size()]))
	deco(Vector3(r.end.x + 0.15, 3.6, r.get_center().y), Vector3(0.3, 1.3, r.size.y * 0.7), Color.html(SIGNS[rng.randi() % SIGNS.size()]))


## Glass office tower with a stepped crown (and sometimes a pyramid top).
func tower(lot: Rect2, height: float, pyramid: bool = false) -> void:
	var f := lot.grow(-12.0)
	var glass := Color.html(GLASS[rng.randi() % GLASS.size()])
	var frame := Color.html("c9ccd1")
	solid(f, height, frame, 3, 0.0, glass)
	var crown := f.grow(-4.5)
	solid(crown, height * 0.16, frame, 3, height, glass)
	if pyramid:
		_pyramid(crown.get_center(), minf(crown.size.x, crown.size.y) * 0.72, height * 1.16, 12.0, Color.html("9fb0c0"))
	else:
		deco(Vector3(crown.get_center().x, height * 1.16 + 1.5, crown.get_center().y), Vector3(0.5, 3.0, 0.5), Color.html("8d99ae"))


func _pyramid(center: Vector2, radius: float, y: float, h: float, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.0
	c.bottom_radius = radius
	c.height = h
	c.radial_segments = 4
	mi.mesh = c
	mi.position = Vector3(center.x, y + h * 0.5, center.y)
	mi.rotation_degrees.y = 45.0
	mi.material_override = flat(color, 0.4, 0.3)
	scene.add_child(mi)


## Zone landmark (Tamimi, school, home...): Najdi box with a big sign on top.
func shop(rect: Rect2, height: float, color: Color, sign_text: String) -> void:
	solid(rect, height, color, 2)
	merlons(rect, height)
	rooftop_tanks(rect, height, 1)
	if sign_text != "":
		label(sign_text, Vector3(rect.get_center().x, height + 6.0, rect.get_center().y))


func mosque(rect: Rect2) -> void:
	var cream := Color.html("efe3c8")
	solid(rect, 9.0, cream, 2)
	merlons(rect, 9.0)
	var c := rect.get_center()
	var dome := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = minf(rect.size.x, rect.size.y) * 0.3
	sph.height = sph.radius * 2.0
	sph.radial_segments = 14
	sph.rings = 8
	dome.mesh = sph
	dome.position = Vector3(c.x, 9.0 + sph.radius * 0.35, c.y)
	dome.scale = Vector3(1.0, 0.8, 1.0)
	dome.material_override = flat(Color.html("e9e2cc"), 0.2, 0.5)
	scene.add_child(dome)
	deco(Vector3(c.x, 9.0 + sph.radius * 1.2, c.y), Vector3(0.3, 3.5, 0.3), Color.html("d4a84b"), 0.0, 0.8)
	minaret(Vector2(rect.position.x + 3.0, rect.position.y + 3.0), 34.0)
	minaret(Vector2(rect.end.x - 3.0, rect.end.y - 3.0), 34.0)


func minaret(pos: Vector2, height: float) -> void:
	var body := StaticBody3D.new()
	body.position = Vector3(pos.x, height * 0.5, pos.y)
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.8, height, 2.8)
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	body.add_child(_cyl_mesh(1.3, 1.5, height, 10, Color.html("efe3c8"), Vector3.ZERO))
	body.add_child(_cyl_mesh(2.1, 2.1, 0.8, 10, Color.html("d9c9a3"), Vector3(0, height * 0.5 - 6.0, 0)))
	body.add_child(_cyl_mesh(0.0, 1.7, 5.5, 10, Color.html("2d6a4f"), Vector3(0, height * 0.5 + 2.75, 0)))
	var ball := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.4
	sph.height = 0.8
	ball.mesh = sph
	ball.position = Vector3(0, height * 0.5 + 5.9, 0)
	ball.material_override = flat(Color.html("d4a84b"), 0.8, 0.3)
	body.add_child(ball)
	scene.add_child(body)


func _cyl_mesh(top: float, bottom: float, h: float, segs: int, color: Color, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = segs
	mi.mesh = c
	mi.position = pos
	mi.material_override = flat(color)
	return mi


## Masmak-style mud-brick fort: thick walls, four corner towers, big gate.
func fort(rect: Rect2, sign_text: String) -> void:
	var mud := Color.html("c2965a")
	solid(rect, 11.0, mud, 2)
	merlons(rect, 11.0)
	for corner: Vector2 in [rect.position, Vector2(rect.end.x, rect.position.y), Vector2(rect.position.x, rect.end.y), rect.end]:
		var t := Rect2(corner - Vector2(7.0, 7.0), Vector2(14.0, 14.0))
		solid(t, 17.0, mud.darkened(0.04), 2)
		merlons(t, 17.0)
	deco(Vector3(rect.get_center().x, 3.6, rect.end.y + 0.2), Vector3(6.0, 7.2, 0.5), Color.html("3b2a1a"))
	if sign_text != "":
		label(sign_text, Vector3(rect.get_center().x, 30.0, rect.get_center().y))


const KC_HEIGHT := 300.0   # real Kingdom Centre: 302 m, 99 floors

## Kingdom Centre as built: one slender silver-glass tower whose top is cut by a huge
## inverted-parabola opening ("the bottle opener"), with the sky bridge spanning the
## opening near the top, standing on a low mall podium.
func kingdom_centre(c: Vector2) -> void:
	var silver := Color.html("a7bccd")
	var glass := Color.html("5f9ac8")
	# mall podium with two low wings
	solid(Rect2(c.x - 70.0, c.y - 38.0, 140.0, 76.0), 14.0, Color.html("e0d4b8"), 1)
	solid(Rect2(c.x - 70.0, c.y + 38.0, 48.0, 26.0), 9.0, Color.html("d9cdb0"), 1)
	solid(Rect2(c.x + 22.0, c.y + 38.0, 48.0, 26.0), 9.0, Color.html("d9cdb0"), 1)
	var w := 66.0
	var d := 36.0
	var y_open := 175.0     # where the opening begins
	var y_apex := 291.0     # top of the parabola
	var open_half := w * 0.5 - 5.5
	var body := StaticBody3D.new()
	scene.add_child(body)
	var x0 := c.x - w * 0.5
	var z0 := c.y - d * 0.5
	_tower_slab(body, Rect2(x0, z0, w, d), 14.0, y_open - 14.0, silver, glass)
	var y := y_open
	var bridge_half := 0.0
	while y < KC_HEIGHT:
		var top := minf(y + 4.0, KC_HEIGHT)
		var mid := (y + top) * 0.5
		var half := 0.0
		if mid < y_apex:
			half = open_half * sqrt(clampf((y_apex - mid) / (y_apex - y_open), 0.0, 1.0))
		if mid > 273.0 and mid < 279.0:
			bridge_half = half
		if half > 1.0:
			var leg := w * 0.5 - half
			_tower_slab(body, Rect2(x0, z0, leg, d), y, top - y, silver, glass)
			_tower_slab(body, Rect2(x0 + w - leg, z0, leg, d), y, top - y, silver, glass)
		else:
			_tower_slab(body, Rect2(x0, z0, w, d), y, top - y, silver, glass)
		y = top
	# the sky bridge across the opening
	deco(Vector3(c.x, 276.0, c.y), Vector3(bridge_half * 2.0 + 2.0, 6.0, d * 0.78), Color.html("93a8ba"), 0.0, 0.5)
	label("KINGDOM CENTRE", Vector3(c.x, KC_HEIGHT + 24.0, c.y), 96, 0.12)


func _tower_slab(body: StaticBody3D, rect: Rect2, y0: float, h: float, color: Color, glass: Color) -> void:
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(rect.size.x, h, rect.size.y)
	cs.shape = box
	cs.position = Vector3(rect.get_center().x, y0 + h * 0.5, rect.get_center().y)
	body.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = box.size
	mi.mesh = bm
	mi.position = cs.position
	mi.material_override = wall_material(color, 3, KC_HEIGHT, glass)
	body.add_child(mi)


## Al Faisaliyah Center as built (Foster + Partners, 267 m): a triangular glass tower that
## tapers upward, a big golden sphere carried at the top by three slender struts, then a
## faceted pyramid cap and a spire.
func faisaliyah(c: Vector2) -> void:
	var podium_h := 10.0
	solid(Rect2(c.x - 36.0, c.y - 36.0, 72.0, 72.0), podium_h, Color.html("e6dbc0"), 1)
	var frame := Color.html("c9ccd1")
	var glass := Color.html("5b8fa8")
	var shaft_h := 170.0
	var shaft := CylinderMesh.new()          # 3 sides = triangular plan
	shaft.top_radius = 9.0
	shaft.bottom_radius = 30.0
	shaft.height = shaft_h
	shaft.radial_segments = 3
	var body := StaticBody3D.new()
	body.position = Vector3(c.x, podium_h + shaft_h * 0.5, c.y)
	var cs := CollisionShape3D.new()
	cs.shape = shaft.create_convex_shape()
	body.add_child(cs)
	var mi := MeshInstance3D.new()
	mi.mesh = shaft
	mi.material_override = wall_material(frame, 3, 270.0, glass)
	body.add_child(mi)
	scene.add_child(body)
	var shaft_top := podium_h + shaft_h
	# golden sphere (the "globe" restaurant) held by three struts
	var ball := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 12.0
	sph.height = 24.0
	sph.radial_segments = 16
	sph.rings = 9
	ball.mesh = sph
	ball.position = Vector3(c.x, shaft_top + 12.0, c.y)
	ball.material_override = flat(Color.html("d9a93f"), 0.85, 0.25)
	scene.add_child(ball)
	var cap_base := shaft_top + 28.0
	for i in 3:
		var ang := float(i) * TAU / 3.0
		var dir := Vector3(sin(ang), 0.0, cos(ang))
		_strut(Vector3(c.x, shaft_top, c.y) + dir * 9.0, Vector3(c.x, cap_base, c.y) + dir * 16.0, 0.9, frame)
	# faceted cap and spire
	var cap := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.8
	cm.bottom_radius = 16.0
	cm.height = 62.0
	cm.radial_segments = 3
	cap.mesh = cm
	cap.position = Vector3(c.x, cap_base + 31.0, c.y)
	cap.material_override = wall_material(frame, 3, 270.0, glass)
	scene.add_child(cap)
	deco(Vector3(c.x, cap_base + 62.0 + 10.0, c.y), Vector3(0.7, 22.0, 0.7), Color.html("8d99ae"), 0.0, 0.6)
	label("AL FAISALIYAH", Vector3(c.x, cap_base + 100.0, c.y), 96, 0.12)


func _strut(a: Vector3, b: Vector3, radius: float, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = a.distance_to(b)
	cyl.radial_segments = 5
	mi.mesh = cyl
	mi.position = (a + b) * 0.5
	mi.basis = Basis(Quaternion(Vector3.UP, (b - a).normalized()))
	mi.material_override = flat(color, 0.5, 0.4)
	scene.add_child(mi)


func _wall_ring(rect: Rect2, h: float, color: Color) -> void:
	var t := 0.5
	var body := StaticBody3D.new()
	var mat := flat(color)
	for piece: Rect2 in [
			Rect2(rect.position.x, rect.position.y, rect.size.x, t),
			Rect2(rect.position.x, rect.end.y - t, rect.size.x, t),
			Rect2(rect.position.x, rect.position.y, t, rect.size.y),
			Rect2(rect.end.x - t, rect.position.y, t, rect.size.y)]:
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(piece.size.x, h, piece.size.y)
		cs.shape = box
		cs.position = Vector3(piece.get_center().x, h * 0.5, piece.get_center().y)
		body.add_child(cs)
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = box.size
		mi.mesh = bm
		mi.position = cs.position
		mi.material_override = mat
		body.add_child(mi)
	scene.add_child(body)
