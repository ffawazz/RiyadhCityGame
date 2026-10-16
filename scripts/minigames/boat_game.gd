extends MiniGameBase

const _Art := preload("res://scripts/ui/avatar_art.gd")
## Boat ride on Al-Kharrarah lake (the seasonal rain lake): W / Up = motor, S / Down = slow, A / D steer.
## Collect floating buoys (golden = 3), steer round the rocks, and meet the ducks.

const GAME_TIME := 50.0
const LAKE_C := Vector2(640.0, 390.0)
const LAKE_R := Vector2(570.0, 290.0)
const MAX_SPEED := 270.0

var _pos: Vector2 = LAKE_C
var _heading: float = 0.0           # radians, 0 = up (north), clockwise
var _vel: Vector2 = Vector2.ZERO
var _speed: float = 0.0
var _time_left: float = 0.0
var _score: int = 0
var _buoys: Array = []              # {pos, golden}
var _rocks: Array = []
var _ducks: Array = []              # {pos, dir, ph}
var _wake: Array = []
var _bump_t: float = 0.0
var _flash: String = ""
var _flash_t: float = 0.0
var _t: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	bg_color = Color.html("e9c46a")
	super()


func _on_start() -> void:
	_rng.randomize()
	_time_left = GAME_TIME
	_score = 0
	_pos = LAKE_C + Vector2(0, 150)
	_heading = 0.0
	_vel = Vector2.ZERO
	_speed = 0.0
	_buoys.clear()
	_rocks.clear()
	_ducks.clear()
	_wake.clear()
	for i in 7:
		var a := float(i) / 7.0 * TAU + 0.4
		var d := 0.35 + 0.4 * fposmod(float(i) * 0.37, 1.0)
		_rocks.append(LAKE_C + Vector2(cos(a) * LAKE_R.x * d, sin(a) * LAKE_R.y * d))
	for i in 4:
		_ducks.append({"pos": LAKE_C + Vector2(_rng.randf_range(-350, 350), _rng.randf_range(-170, 170)), "dir": 1.0 if i % 2 == 0 else -1.0, "ph": float(i)})
	for i in 3:
		_spawn_buoy()


func _spawn_buoy() -> void:
	for tries in 20:
		var a := _rng.randf() * TAU
		var d := sqrt(_rng.randf()) * 0.82
		var p := LAKE_C + Vector2(cos(a) * LAKE_R.x * d, sin(a) * LAKE_R.y * d)
		var ok := p.distance_to(_pos) > 150.0
		for r: Vector2 in _rocks:
			if r.distance_to(p) < 70.0:
				ok = false
		if ok:
			_buoys.append({"pos": p, "golden": _rng.randf() < 0.12})
			return


func _inside(p: Vector2, margin: float = 0.0) -> bool:
	var q := (p - LAKE_C) / (LAKE_R - Vector2(margin, margin))
	return q.length() < 1.0


func _tick(delta: float) -> void:
	_t += delta
	_time_left -= delta
	_flash_t = maxf(0.0, _flash_t - delta)
	_bump_t = maxf(0.0, _bump_t - delta)
	var throttle := Input.get_action_strength("accelerate")
	var brake := Input.get_action_strength("brake")
	var steer := Input.get_axis("steer_left", "steer_right")
	if throttle > 0.0:
		_speed = move_toward(_speed, MAX_SPEED * throttle, 300.0 * delta)
	elif brake > 0.0:
		_speed = move_toward(_speed, -80.0 * brake, 380.0 * delta)
	else:
		_speed = move_toward(_speed, 0.0, 90.0 * delta)
	_heading += steer * (1.1 + 1.7 * clampf(absf(_speed) / 120.0, 0.0, 1.0)) * delta * (1.0 if _speed >= 0.0 else -1.0) * clampf(absf(_speed) / 40.0, 0.35, 1.0)
	var want := Vector2(sin(_heading), -cos(_heading)) * _speed
	_vel = _vel.lerp(want, 1.0 - exp(-3.2 * delta))          # boats slide a little
	var np := _pos + _vel * delta
	var hit := false
	for r: Vector2 in _rocks:
		var d := np.distance_to(r)
		if d < 52.0:
			np = r + (np - r).normalized() * 52.0
			hit = true
	if not _inside(np, 30.0):
		var out := (np - LAKE_C)
		np = LAKE_C + out / (out / (LAKE_R - Vector2(32, 32))).length() * 0.995
		hit = true
	if hit and _bump_t <= 0.0:
		_bump_t = 0.6
		_speed *= 0.3
		_vel *= 0.3
		_say("Bump!")
	_pos = np
	_wake.append({"p": _pos - Vector2(sin(_heading), -cos(_heading)) * 26.0, "life": 1.2})
	for w: Dictionary in _wake:
		w["life"] = float(w["life"]) - delta
	_wake = _wake.filter(func(w: Dictionary) -> bool: return float(w["life"]) > 0.0)
	for d: Dictionary in _ducks:
		d["pos"] = (d["pos"] as Vector2) + Vector2(float(d["dir"]) * 26.0, sin(_t + float(d["ph"])) * 8.0) * delta
		if not _inside(d["pos"], 60.0):
			d["dir"] = -float(d["dir"])
		if (d["pos"] as Vector2).distance_to(_pos) < 46.0 and _bump_t <= 0.0:
			_bump_t = 0.6
			_speed *= 0.5
			_say("Quack! Careful, ducks!")
	for i in range(_buoys.size() - 1, -1, -1):
		var b: Dictionary = _buoys[i]
		if (b["pos"] as Vector2).distance_to(_pos) < 44.0:
			_score += 3 if b["golden"] else 1
			_say("Golden buoy! +3" if b["golden"] else "Got it! +1")
			_buoys.remove_at(i)
			_spawn_buoy()
	if _time_left <= 0.0 and running:
		complete(maxi(1, stars_from(_score, 9, 15, 22)))


func _say(s: String) -> void:
	_flash = s
	_flash_t = 0.8


func _draw_game() -> void:
	if not running:
		return
	# shore: sand with reeds, a few trees
	for i in 14:
		var rx := 40.0 + i * 92.0
		draw_line(Vector2(rx, 60), Vector2(rx + 10, 20 + (i % 3) * 8), Color.html("6a994e"), 4.0)
	draw_circle(Vector2(90, 700), 50.0, Color.html("6f8a3d"))
	draw_circle(Vector2(1190, 690), 56.0, Color.html("6f8a3d"))
	# the lake: turquoise "liquid light" with a lighter rim
	var pts := PackedVector2Array()
	var rim := PackedVector2Array()
	for i in 72:
		var a := TAU * float(i) / 72.0
		pts.append(LAKE_C + Vector2(cos(a) * LAKE_R.x, sin(a) * LAKE_R.y))
		rim.append(LAKE_C + Vector2(cos(a) * (LAKE_R.x + 14.0), sin(a) * (LAKE_R.y + 14.0)))
	draw_colored_polygon(rim, Color.html("d4b483"))
	draw_colored_polygon(pts, Color.html("2ec4b6"))
	for i in 6:
		var rr := 1.0 - float(i) * 0.15
		draw_arc(LAKE_C, LAKE_R.x * rr * 0.7, 0, TAU, 40, Color(1, 1, 1, 0.12), 3.0)
	for i in 12:
		var a := float(i) * 0.9 + _t * 0.2
		draw_arc(LAKE_C + Vector2(cos(a) * 300.0, sin(a) * 150.0), 18.0, 0.3, 2.6, 8, Color(1, 1, 1, 0.35), 2.0)
	for w: Dictionary in _wake:
		draw_circle(w["p"], 8.0 + (1.2 - float(w["life"])) * 14.0, Color(1, 1, 1, float(w["life"]) * 0.28))
	for r: Vector2 in _rocks:
		draw_circle(r + Vector2(4, 6), 36.0, Color(0, 0.2, 0.2, 0.25))
		draw_circle(r, 34.0, Color.html("6c757d"))
		draw_circle(r + Vector2(-8, -8), 20.0, Color.html("8d99ae"))
	for d: Dictionary in _ducks:
		_Art.draw_animal(self, "duck", (d["pos"] as Vector2) + Vector2(0, 16), 0.3, float(d["dir"]))
	for b: Dictionary in _buoys:
		var p: Vector2 = b["pos"]
		var bob := sin(_t * 3.0 + p.x) * 3.0
		draw_circle(p + Vector2(0, bob), 24.0, Color.html("ffd60a") if b["golden"] else Color.html("e63946"))
		draw_circle(p + Vector2(0, bob), 14.0, Color.html("fff3b0") if b["golden"] else Color.WHITE)
		draw_arc(p + Vector2(0, bob), 30.0, 0, TAU, 20, Color(1, 1, 1, 0.5), 2.0)
	# the boat (rotates with its heading), then the sister and her animal sit in it
	draw_set_transform(_pos, _heading, Vector2.ONE)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -44), Vector2(22, -14), Vector2(20, 34), Vector2(-20, 34), Vector2(-22, -14)]), Color.html("f94144"))
	draw_colored_polygon(PackedVector2Array([Vector2(0, -34), Vector2(15, -12), Vector2(14, 28), Vector2(-14, 28), Vector2(-15, -12)]), Color.html("ffe8d6"))
	draw_rect(Rect2(-18, 30, 36, 8), Color.html("495057"))                # outboard motor
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_Art.draw_sister(self, Game.character_id, _pos + Vector2(0, 34), 0.3)
	_Art.draw_animal(self, Game.animal_id, _pos + Vector2(14, 40), 0.2)
	# hud
	text(Vector2(24, 40), "Time %d    Buoys %d" % [maxi(0, ceili(_time_left)), _score], 30, Color.html("3d2c00"))
	text(Vector2(24, 72), "W motor   S slow   A / D steer", 20, Color.html("3d2c00"))
	text_c(Vector2(size.x * 0.5, 36), "بحيرة الخرارة", 30, Color.html("3d2c00"))
	if _flash_t > 0.0:
		text_c(Vector2(size.x * 0.5, 130), _flash, 38, Color.html("3d2c00"))
