extends MiniGameBase

const _Art := preload("res://scripts/ui/avatar_art.gd")
## Kite flying: steer the kite with the mouse / finger / WASD. The desert wind pushes it around.
## Fly through golden rings (+1), avoid the birds (-1).

const GAME_TIME := 35.0

var _time_left: float = 0.0
var _score: int = 0
var _kite: Vector2 = Vector2(640, 300)
var _vel: Vector2 = Vector2.ZERO
var _wind: float = 0.0
var _wind_t: float = 0.0
var _rings: Array = []
var _birds: Array = []
var _spawn: float = 0.0
var _flash: String = ""
var _flash_t: float = 0.0
var _hit_t: float = 0.0
var _t: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	bg_color = Color.html("48cae4")
	super()


func _on_start() -> void:
	_rng.randomize()
	_time_left = GAME_TIME
	_score = 0
	_kite = Vector2(640, 300)
	_vel = Vector2.ZERO
	pointer = Vector2(640, 300)
	_rings.clear()
	_birds.clear()
	_spawn = 0.3


func _tick(delta: float) -> void:
	_t += delta
	_time_left -= delta
	_flash_t = maxf(0.0, _flash_t - delta)
	_hit_t = maxf(0.0, _hit_t - delta)
	pointer_move(delta)
	_wind_t -= delta
	if _wind_t <= 0.0:
		_wind_t = _rng.randf_range(1.5, 3.0)
		_wind = _rng.randf_range(-170.0, 170.0)
	# kite chases the pointer, wind pushes it sideways
	var to := pointer - _kite
	_vel = _vel.lerp(to * 4.0 + Vector2(_wind, sin(_t * 2.0) * 40.0), 1.0 - exp(-4.0 * delta))
	_kite += _vel * delta
	_kite = _kite.clamp(Vector2(60, 70), Vector2(size.x - 60, size.y - 160))
	_spawn -= delta
	if _spawn <= 0.0:
		_spawn = _rng.randf_range(0.7, 1.3)
		if _rng.randf() < 0.65:
			_rings.append({"pos": Vector2(size.x + 40, _rng.randf_range(100, 460)), "got": false})
		else:
			_birds.append({"pos": Vector2(size.x + 40, _rng.randf_range(100, 460)), "hit": false})
	var speed := 190.0
	for r: Dictionary in _rings:
		r["pos"] = (r["pos"] as Vector2) + Vector2(-speed * delta, 0)
		if not r["got"] and (r["pos"] as Vector2).distance_to(_kite) < 52.0:
			r["got"] = true
			_score += 1
			_flash = "+1"
			_flash_t = 0.5
	for b: Dictionary in _birds:
		b["pos"] = (b["pos"] as Vector2) + Vector2(-speed * 1.5 * delta, sin(_t * 5.0 + float((b["pos"] as Vector2).y)) * 40.0 * delta)
		if not b["hit"] and (b["pos"] as Vector2).distance_to(_kite) < 44.0:
			b["hit"] = true
			_score = maxi(0, _score - 1)
			_hit_t = 0.6
			_flash = "Bird! -1"
			_flash_t = 0.7
	_rings = _rings.filter(func(r: Dictionary) -> bool: return (r["pos"] as Vector2).x > -60.0 and not r["got"])
	_birds = _birds.filter(func(b: Dictionary) -> bool: return (b["pos"] as Vector2).x > -60.0)
	if _time_left <= 0.0 and running:
		complete(maxi(1, stars_from(_score, 8, 14, 20)))


func _draw_game() -> void:
	if not running:
		return
	var gy := size.y - 130.0
	draw_rect(Rect2(0, gy, size.x, size.y - gy), Color.html("e9c46a"))
	draw_colored_polygon(PackedVector2Array([Vector2(0, gy), Vector2(260, gy - 70), Vector2(560, gy)]), Color.html("f4d58d"))
	draw_colored_polygon(PackedVector2Array([Vector2(700, gy), Vector2(980, gy - 90), Vector2(1280, gy)]), Color.html("f4d58d"))
	for i in 4:
		var cx := fposmod(i * 360.0 - _t * 20.0, size.x + 200.0) - 100.0
		draw_circle(Vector2(cx, 120.0 + (i % 2) * 70.0), 46.0, Color(1, 1, 1, 0.85))
		draw_circle(Vector2(cx + 40, 130.0 + (i % 2) * 70.0), 36.0, Color(1, 1, 1, 0.85))
	# the string (a sagging curve) from the child's hand to the kite
	var hand := Vector2(210, gy - 70)
	var pts := PackedVector2Array()
	for i in 21:
		var f := float(i) / 20.0
		pts.append(hand.lerp(_kite, f) + Vector2(0, sin(f * PI) * 40.0))
	draw_polyline(pts, Color.html("f8f9fa"), 2.0)
	for r: Dictionary in _rings:
		draw_arc(r["pos"], 32.0, 0, TAU, 24, Color.html("ffd60a"), 8.0)
	for b: Dictionary in _birds:
		var p: Vector2 = b["pos"]
		var flap := sin(_t * 14.0) * 12.0
		draw_line(p + Vector2(-20, flap), p, Color.html("212529"), 5.0)
		draw_line(p, p + Vector2(20, flap), Color.html("212529"), 5.0)
		draw_circle(p, 6.0, Color.html("212529"))
	# the kite: a diamond with a tail of ribbons
	var kc := Color.html("e63946") if _hit_t <= 0.0 else Color.html("6c757d")
	draw_colored_polygon(PackedVector2Array([_kite + Vector2(0, -42), _kite + Vector2(30, 0), _kite + Vector2(0, 52), _kite + Vector2(-30, 0)]), kc)
	draw_line(_kite + Vector2(0, -42), _kite + Vector2(0, 52), Color.html("ffd60a"), 3.0)
	draw_line(_kite + Vector2(-30, 0), _kite + Vector2(30, 0), Color.html("ffd60a"), 3.0)
	for i in 5:
		var tp := _kite + Vector2(sin(_t * 6.0 + i) * 14.0, 56.0 + i * 16.0)
		draw_rect(Rect2(tp + Vector2(-5, -4), Vector2(10, 8)), [Color.html("ffd60a"), Color.html("3a86ff"), Color.html("06d6a0"), Color.html("ff5d8f"), Color.html("9b5de5")][i])
	_Art.draw_sister(self, Game.character_id, Vector2(180, size.y - 10), 0.85)
	_Art.draw_animal(self, Game.animal_id, Vector2(60, size.y - 14), 0.55)
	# wind indicator
	text(Vector2(24, 40), "Time %d    Rings %d" % [maxi(0, ceili(_time_left)), _score], 30, Color.html("023e8a"))
	var arrow := ">>" if _wind > 20.0 else ("<<" if _wind < -20.0 else "--")
	text(Vector2(24, 72), "Wind %s  %d km/h" % [arrow, int(absf(_wind) / 6.0)], 22, Color.html("023e8a"))
	if _flash_t > 0.0:
		text_c(Vector2(size.x * 0.5, 130), _flash, 40, Color.html("3d2c00"))
