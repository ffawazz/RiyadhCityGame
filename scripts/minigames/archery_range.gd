extends MiniGameBase

const _Art := preload("res://scripts/ui/avatar_art.gd")
## Bottle archery / air-rifle range. Bottles filled with sand, water, Pepsi or Cola stand on
## two shelves. The WIND blows your shot sideways (watch the flag!), the bow also drops with
## distance and needs a full draw, the rifle is flatter but reloads. 45 seconds.

const GAME_TIME := 45.0
const KINDS := {
	"sand":  {"liquid": "d9b26a", "label": "c9953c", "pts": 2, "hp": 2, "name": "Sand"},
	"water": {"liquid": "9fd8f5", "label": "2a9d8f", "pts": 1, "hp": 1, "name": "Water"},
	"pepsi": {"liquid": "1d3f8f", "label": "e63946", "pts": 1, "hp": 1, "name": "Pepsi"},
	"cola":  {"liquid": "3b1a10", "label": "d00000", "pts": 1, "hp": 1, "name": "Cola"},
}
const KIND_ORDER := ["sand", "water", "pepsi", "cola"]
const MAG := 6

var _time_left: float = 0.0
var _score: int = 0
var _shots: int = 0
var _hits: int = 0
var _bottles: Array = []    # {pos, kind, hp, fall(-1 = standing, else time), spin, respawn}
var _arrows: Array = []     # {from, to, t, dur, bow}
var _fx: Array = []         # {pos, vel, life, color}
var _use_bow: bool = true
var _draw_t: float = 0.0
var _drawing: bool = false
var _cooldown: float = 0.0
var _ammo: int = MAG
var _reload: float = 0.0
var _aim: Vector2 = Vector2.ZERO
var _sway_t: float = 0.0
var _wind: float = 0.0
var _wind_target: float = 0.0
var _wind_timer: float = 0.0
var _flash: String = ""
var _flash_t: float = 0.0
var _anim: float = 0.0


func _ready() -> void:
	bg_color = Color.html("8ecae6")
	super()


func _on_start() -> void:
	_time_left = GAME_TIME
	_score = 0
	_shots = 0
	_hits = 0
	_ammo = MAG
	_aim = Vector2(size.x * 0.7, size.y * 0.45)
	_wind_target = randf_range(-1.0, 1.0)
	_wind = _wind_target
	_wind_timer = 6.0
	_arrows.clear()
	_fx.clear()
	_stock()


func _stock() -> void:
	_bottles.clear()
	var kinds := KIND_ORDER.duplicate()
	var i := 0
	for row in 2:
		for col in 5:
			var k: String = kinds[(i * 3 + row) % 4]
			_bottles.append({"pos": Vector2(size.x * 0.52 + col * 100.0 + row * 24.0, _shelf_y(row)), "kind": k,
					"hp": int(KINDS[k]["hp"]), "fall": -1.0, "spin": 0.0, "respawn": 0.0, "row": row})
			i += 1


func _shelf_y(row: int) -> float:
	return size.y * (0.42 if row == 0 else 0.66)


func _muzzle() -> Vector2:
	return Vector2(190.0, size.y - 190.0)


func _wind_kmh() -> int:
	return int(round(absf(_wind) * 30.0))


func _tick(delta: float) -> void:
	_time_left -= delta
	_anim += delta
	_sway_t += delta
	_cooldown = maxf(0.0, _cooldown - delta)
	_flash_t = maxf(0.0, _flash_t - delta)
	# gusty wind that keeps changing
	_wind_timer -= delta
	if _wind_timer <= 0.0:
		_wind_timer = randf_range(4.0, 7.0)
		_wind_target = randf_range(-1.0, 1.0)
	_wind = move_toward(_wind, _wind_target, delta * 0.35)
	# keyboard aiming (the mouse sets _aim directly)
	var kb := Input.get_vector("steer_left", "steer_right", "accelerate", "brake")
	_aim += kb * 380.0 * delta
	_aim.x = clampf(_aim.x, 260.0, size.x - 20.0)
	_aim.y = clampf(_aim.y, 120.0, size.y - 60.0)
	if _drawing:
		_draw_t = minf(1.0, _draw_t + delta / 0.7)
	if _reload > 0.0:
		_reload -= delta
		if _reload <= 0.0:
			_ammo = MAG
	for i in range(_arrows.size() - 1, -1, -1):
		var a: Dictionary = _arrows[i]
		a["t"] = float(a["t"]) + delta
		if float(a["t"]) >= float(a["dur"]):
			_land(a)
			_arrows.remove_at(i)
	for b: Dictionary in _bottles:
		if float(b["fall"]) >= 0.0:
			b["fall"] = float(b["fall"]) + delta
			b["spin"] = float(b["spin"]) + delta * 9.0
			if float(b["fall"]) > 2.2:
				b["fall"] = -1.0
				b["spin"] = 0.0
				b["hp"] = int(KINDS[b["kind"]]["hp"])
	for i in range(_fx.size() - 1, -1, -1):
		var f: Dictionary = _fx[i]
		f["life"] = float(f["life"]) - delta
		f["vel"] = (f["vel"] as Vector2) + Vector2(_wind * 40.0, 700.0) * delta
		f["pos"] = (f["pos"] as Vector2) + (f["vel"] as Vector2) * delta
		if float(f["life"]) <= 0.0:
			_fx.remove_at(i)
	if _time_left <= 0.0 and running:
		complete(maxi(1, stars_from(_score, 8, 14, 20)))


func _crosshair() -> Vector2:
	var breath := Vector2(sin(_sway_t * 1.7), cos(_sway_t * 2.3)) * (9.0 if _use_bow else 5.0)
	if _use_bow and _drawing:
		breath *= 1.0 - 0.6 * _draw_t
	return _aim + breath


func _fire() -> void:
	var cross := _crosshair()
	var power := 1.0
	var flight := 0.18
	var drift := _wind * 26.0
	var drop := 0.0
	if _use_bow:
		power = clampf(_draw_t, 0.25, 1.0)
		flight = 0.6 - 0.25 * power
		drift = _wind * 110.0 * (1.2 - 0.5 * power)
		drop = (1.0 - power) * 140.0 + 22.0
	else:
		if _ammo <= 0 or _reload > 0.0:
			return
		_ammo -= 1
		if _ammo == 0:
			_reload = 1.3
		_cooldown = 0.35
	_shots += 1
	_arrows.append({"from": _muzzle(), "to": cross + Vector2(drift, drop), "t": 0.0, "dur": flight, "bow": _use_bow})
	_draw_t = 0.0
	_drawing = false


func _land(a: Dictionary) -> void:
	var p: Vector2 = a["to"]
	var best := -1
	var best_d := 1e9
	for i in _bottles.size():
		var b: Dictionary = _bottles[i]
		if float(b["fall"]) >= 0.0:
			continue
		var d := p.distance_to((b["pos"] as Vector2) + Vector2(0, -34))
		if d < 34.0 and d < best_d:
			best = i
			best_d = d
	if best < 0:
		_spray(p, Color(0.7, 0.55, 0.35), 4)
		_flash = "Missed - check the wind!"
		_flash_t = 0.7
		return
	var b: Dictionary = _bottles[best]
	var kind: Dictionary = KINDS[b["kind"]]
	b["hp"] = int(b["hp"]) - 1
	_hits += 1
	_spray(p, Color.html(kind["liquid"]), 14)
	if int(b["hp"]) <= 0:
		b["fall"] = 0.0
		_score += int(kind["pts"])
		_flash = "%s bottle!  +%d" % [kind["name"], int(kind["pts"])]
	else:
		_flash = "The sand bottle is heavy - hit it again!"
	_flash_t = 0.9


func _spray(p: Vector2, c: Color, n: int) -> void:
	for i in n:
		_fx.append({"pos": p, "vel": Vector2(randf_range(-160, 160), randf_range(-260, -40)), "life": randf_range(0.4, 0.8), "color": c})


func _on_input(event: InputEvent) -> void:
	var mm := event as InputEventMouseMotion
	if mm != null:
		_aim = Vector2(clampf(mm.position.x, 260.0, size.x - 20.0), clampf(mm.position.y, 120.0, size.y - 60.0))
		return
	if event.is_action_pressed("swap_item"):      # TAB / Q / LB
		_use_bow = not _use_bow
		_drawing = false
		_draw_t = 0.0
		get_viewport().set_input_as_handled()
		return
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo:
		if key.keycode == KEY_1 or key.keycode == KEY_2:
			if key.keycode == KEY_1:
				_use_bow = true
			elif key.keycode == KEY_2:
				_use_bow = false
			else:
				_use_bow = not _use_bow
			_drawing = false
			_draw_t = 0.0
			get_viewport().set_input_as_handled()
			return
	var mb := event as InputEventMouseButton
	var down := false
	var up := false
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
		down = mb.pressed
		up = not mb.pressed
		_aim = Vector2(clampf(mb.position.x, 260.0, size.x - 20.0), clampf(mb.position.y, 120.0, size.y - 60.0))
	elif event.is_action_pressed("ui_accept"):
		down = true
	elif event.is_action_released("ui_accept"):
		up = true
	if _use_bow:
		if down and _cooldown <= 0.0:
			_drawing = true
			_draw_t = 0.0
		elif up and _drawing:
			_fire()
			_cooldown = 0.25
	elif down and _cooldown <= 0.0:
		_fire()


func _draw_bottle(b: Dictionary) -> void:
	var kind: Dictionary = KINDS[b["kind"]]
	var p: Vector2 = b["pos"]
	var alpha := 1.0
	var rot := 0.0
	if float(b["fall"]) >= 0.0:
		var t: float = b["fall"]
		p += Vector2(40.0 * t * (1.0 if _wind >= 0.0 else -1.0) + 30.0 * t, -90.0 * t + 420.0 * t * t)
		rot = float(b["spin"])
		alpha = clampf(1.0 - (t - 1.4) / 0.8, 0.0, 1.0)
	draw_set_transform(p, rot, Vector2.ONE)
	var glass := Color(0.9, 0.95, 1.0, 0.55 * alpha)
	draw_rect(Rect2(-14, -62, 28, 62), glass)
	draw_rect(Rect2(-5, -80, 10, 20), glass)
	var liquid := Color.html(kind["liquid"])
	liquid.a = alpha
	draw_rect(Rect2(-12, -52, 24, 50), liquid)
	if b["kind"] == "sand":
		for i in 6:
			draw_circle(Vector2(-7 + (i % 3) * 7, -12 - (i / 3) * 14), 1.6, Color(1, 1, 1, 0.35 * alpha))
	var lab := Color.html(kind["label"])
	lab.a = alpha
	draw_rect(Rect2(-12, -34, 24, 14), lab)
	draw_rect(Rect2(-6, -86, 12, 8), Color(0.9, 0.9, 0.9, alpha) if b["kind"] != "cola" else Color(0.8, 0.1, 0.1, alpha))
	if int(b["hp"]) < int(kind["hp"]) and float(b["fall"]) < 0.0:   # cracked sand bottle
		draw_line(Vector2(-10, -50), Vector2(6, -20), Color(1, 1, 1, 0.9), 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_game() -> void:
	if not running:
		return
	# scenery: dunes, fence, ground
	draw_rect(Rect2(0, size.y * 0.78, size.x, size.y * 0.22), Color.html("d4a373"))
	draw_colored_polygon(PackedVector2Array([Vector2(0, size.y * 0.78), Vector2(240, size.y * 0.6), Vector2(520, size.y * 0.78)]), Color.html("e9c46a"))
	draw_colored_polygon(PackedVector2Array([Vector2(700, size.y * 0.78), Vector2(1000, size.y * 0.66), Vector2(size.x, size.y * 0.78)]), Color.html("e9c46a"))
	for row in 2:
		var y := _shelf_y(row)
		draw_rect(Rect2(size.x * 0.52 - 40 + row * 24.0, y, 540, 14), Color.html("8b5e34"))
		draw_rect(Rect2(size.x * 0.52 - 30 + row * 24.0, y + 14, 10, size.y * 0.78 - y - 14 if row == 1 else 120), Color.html("6f4518"))
		draw_rect(Rect2(size.x * 0.52 + 480 + row * 24.0, y + 14, 10, size.y * 0.78 - y - 14 if row == 1 else 120), Color.html("6f4518"))
	for b: Dictionary in _bottles:
		_draw_bottle(b)
	# HUD
	text(Vector2(24, 40), "Time %d   Points %d   Hits %d/%d" % [maxi(0, ceili(_time_left)), _score, _hits, _shots], 28, Color.html("023e8a"))
	text(Vector2(24, 72), "TAB / LB / 1 / 2 switch weapon:  %s" % ("BOW (hold to draw, release to shoot)" if _use_bow else "AIR RIFLE (click)"), 20, Color.html("023e8a"))
	_draw_wind()
	if _flash_t > 0.0:
		text_c(Vector2(size.x * 0.5, 120), _flash, 30, Color.html("3d2c00"))
	# shooter: the chosen sister, her animal at her feet
	var feet := Vector2(150.0, size.y - 40.0)
	_Art.draw_sister(self, Game.character_id, feet, 0.78)
	_Art.draw_animal(self, Game.animal_id, feet + Vector2(-90, 8), 0.5)
	var m := _muzzle()
	var cross := _crosshair()
	var dir := (cross - m).normalized()
	if _use_bow:
		var pull := _draw_t * 26.0 if _drawing else 0.0
		var ang := dir.angle()
		draw_set_transform(m, ang, Vector2.ONE)
		draw_arc(Vector2(0, 0), 52.0, -1.1, 1.1, 18, Color.html("6f4518"), 7.0)
		var tip_a := Vector2(cos(1.1), sin(1.1)) * 52.0
		var tip_b := Vector2(cos(-1.1), sin(-1.1)) * 52.0
		draw_line(tip_a, Vector2(-pull, 0), Color.WHITE, 2.0)
		draw_line(tip_b, Vector2(-pull, 0), Color.WHITE, 2.0)
		if _drawing or _cooldown <= 0.0:
			draw_line(Vector2(-pull, 0), Vector2(60, 0), Color.html("ced4da"), 3.0)
			draw_colored_polygon(PackedVector2Array([Vector2(60, 0), Vector2(48, -5), Vector2(48, 5)]), Color.html("e63946"))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if _drawing:   # draw power meter
			draw_rect(Rect2(m.x - 60, m.y + 70, 120, 12), Color.html("264653"))
			draw_rect(Rect2(m.x - 60, m.y + 70, 120 * _draw_t, 12), Color.html("80b918") if _draw_t > 0.9 else Color.html("ffd166"))
	else:
		draw_set_transform(m - dir * 20.0, dir.angle() - (0.12 if _cooldown > 0.2 else 0.0), Vector2.ONE)
		draw_rect(Rect2(0, -6, 96, 12), Color.html("5c3d2e"))
		draw_rect(Rect2(60, -9, 70, 7), Color.html("343a40"))
		draw_rect(Rect2(14, 4, 20, 14), Color.html("5c3d2e"))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		text(Vector2(24, size.y - 14), "Air rifle  %s" % ("reloading..." if _reload > 0.0 else "%d / %d" % [_ammo, MAG]), 22, Color.html("3d2c00"))
	for a: Dictionary in _arrows:
		var f := float(a["t"]) / float(a["dur"])
		var from: Vector2 = a["from"]
		var to: Vector2 = a["to"]
		var p := from.lerp(to, f) + Vector2(0, -sin(f * PI) * (40.0 if a["bow"] else 4.0))
		var back := from.lerp(to, maxf(0.0, f - 0.12)) + Vector2(0, -sin(maxf(0.0, f - 0.12) * PI) * (40.0 if a["bow"] else 4.0))
		draw_line(back, p, Color.html("e63946") if a["bow"] else Color.html("ffd60a"), 4.0 if a["bow"] else 3.0)
	for f: Dictionary in _fx:
		draw_circle(f["pos"], 3.5, f["color"])
	# crosshair
	var cc := Color(1, 0.1, 0.1, 0.9)
	draw_arc(cross, 18.0, 0, TAU, 20, cc, 2.5)
	draw_line(cross + Vector2(-26, 0), cross + Vector2(-8, 0), cc, 2.5)
	draw_line(cross + Vector2(26, 0), cross + Vector2(8, 0), cc, 2.5)
	draw_line(cross + Vector2(0, -26), cross + Vector2(0, -8), cc, 2.5)
	draw_line(cross + Vector2(0, 26), cross + Vector2(0, 8), cc, 2.5)


func _draw_wind() -> void:
	var base := Vector2(size.x - 130.0, 130.0)
	draw_rect(Rect2(base.x - 90, base.y - 70, 180, 120), Color(0, 0, 0, 0.28))
	draw_line(base + Vector2(0, 40), base + Vector2(0, -50), Color.html("495057"), 5.0)
	# the flag streams with the wind, flapping
	var dirn := signf(_wind) if absf(_wind) > 0.03 else 0.0
	var flen := 14.0 + absf(_wind) * 54.0
	var pts := PackedVector2Array([base + Vector2(0, -50)])
	for i in 6:
		var u := float(i + 1) / 6.0
		pts.append(base + Vector2(dirn * flen * u, -50.0 + sin(_anim * 9.0 + u * 5.0) * 5.0 * absf(_wind) + u * 8.0 * (1.0 - absf(_wind))))
	for i in range(pts.size() - 1):
		draw_line(pts[i], pts[i + 1], Color.html("e63946"), 14.0)
	var arrow := "<<" if _wind < -0.03 else (">>" if _wind > 0.03 else "--")
	text_c(base + Vector2(0, 76), "WIND %s %d km/h" % [arrow, _wind_kmh()], 22, Color.html("ffffff"))
