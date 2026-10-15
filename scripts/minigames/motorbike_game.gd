extends MiniGameBase

const _Art := preload("res://scripts/ui/avatar_art.gd")
## Farm dirt-bike track, side view. D / Right = gas, A / Left = brake, W / S tilt in the air.
## Jump the ramps, land on both wheels, grab stars. 40 seconds; distance + stars = score.

const GAME_TIME := 40.0
const TRACK_LEN := 14000.0
const GRAVITY := 1500.0

var _x: float = 0.0          # world x of the bike
var _h: float = 0.0          # height above the ground (0 = on the ground)
var _vh: float = 0.0
var _speed: float = 0.0
var _tilt: float = 0.0        # rotation in radians (positive = nose down)
var _air: bool = false
var _time_left: float = 0.0
var _stars: int = 0
var _crash_t: float = 0.0
var _flash: String = ""
var _flash_t: float = 0.0
var _t: float = 0.0
var _ramps: Array = []
var _pickups: Array = []     # {x, y, got}
var _flips: float = 0.0
var _air_rot: float = 0.0


func _ready() -> void:
	bg_color = Color.html("f2cc8f")
	super()


func _on_start() -> void:
	_x = 0.0
	_h = 0.0
	_speed = 0.0
	_tilt = 0.0
	_time_left = GAME_TIME
	_stars = 0
	_crash_t = 0.0
	_ramps.clear()
	_pickups.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var x := 700.0
	while x < TRACK_LEN:
		_ramps.append(x)
		for i in 4:
			_pickups.append({"x": x + 80.0 + i * 60.0, "y": 90.0 + sin(float(i) / 3.0 * PI) * 140.0, "got": false})
		for i in 3:
			_pickups.append({"x": x - 420.0 + i * 70.0, "y": 20.0, "got": false})
		x += rng.randf_range(650.0, 900.0)


func _ramp_height(x: float) -> float:
	for r: float in _ramps:
		var d := x - r
		if d >= 0.0 and d <= 150.0:
			return d * 0.55          # up the ramp
	return 0.0


func _tick(delta: float) -> void:
	_t += delta
	_flash_t = maxf(0.0, _flash_t - delta)
	if _crash_t > 0.0:
		_crash_t -= delta
		_speed = 0.0
		_h = 0.0
		_tilt = lerpf(_tilt, 0.0, 6.0 * delta)
		if _crash_t <= 0.0:
			_air = false
		return
	_time_left -= delta
	var gas := Input.is_action_pressed("steer_right") or Input.is_action_pressed("ui_right")
	var brake := Input.is_action_pressed("steer_left") or Input.is_action_pressed("ui_left")
	var up := Input.is_action_pressed("accelerate")
	var down := Input.is_action_pressed("brake")
	if gas:
		_speed = minf(620.0, _speed + 380.0 * delta)
	elif brake:
		_speed = maxf(0.0, _speed - 700.0 * delta)
	else:
		_speed = maxf(0.0, _speed - 120.0 * delta)
	var prev_x := _x
	_x += _speed * delta
	if not _air:
		var ground_now := _ramp_height(_x)
		var ground_prev := _ramp_height(prev_x)
		# leave the top of a ramp: launch
		if ground_prev > 20.0 and ground_now <= 0.0 and _speed > 80.0:
			_air = true
			_h = ground_prev
			_vh = _speed * 0.55
			_air_rot = 0.0
		else:
			_h = ground_now
			var slope := atan(0.55) if ground_now > 0.0 else 0.0
			_tilt = lerpf(_tilt, -slope, 10.0 * delta)
			# wheelie with W when on the ground and fast
			if up and gas and ground_now <= 0.0:
				_tilt = lerpf(_tilt, -0.5, 6.0 * delta)
	else:
		_vh -= GRAVITY * delta
		_h += _vh * delta
		var spin := 0.0
		if up:
			spin -= 3.2
		if down:
			spin += 3.2
		_tilt += spin * delta
		_air_rot += spin * delta
		if _h <= _ramp_height(_x) and _vh < 0.0:
			_h = _ramp_height(_x)
			_air = false
			_land()
	for pk: Dictionary in _pickups:
		if not pk["got"] and absf(float(pk["x"]) - _x) < 36.0 and absf(float(pk["y"]) - _h) < 70.0:
			pk["got"] = true
			_stars += 1
	if _x >= TRACK_LEN or _time_left <= 0.0:
		var score := _x / 200.0 + _stars
		complete(maxi(1, stars_from(score, 30.0, 55.0, 80.0)))


func _land() -> void:
	var rot := absf(fposmod(_tilt + PI, TAU) - PI)
	if rot > 0.9:
		_crash_t = 1.2
		_flash = "Wipe-out! Keep the nose level"
		_flash_t = 1.2
		_speed = 0.0
	else:
		_tilt = 0.0
		if absf(_air_rot) > TAU - 0.9:
			_stars += 5
			_flash = "FLIP!  +5 stars"
			_flash_t = 1.2
		elif rot < 0.35:
			_stars += 1
			_flash = "Smooth landing +1"
			_flash_t = 0.9
	_air_rot = 0.0


func _sx(wx: float) -> float:
	return 300.0 + (wx - _x)


func _gy() -> float:
	return size.y - 150.0


func _draw_game() -> void:
	if not running:
		return
	var gy := _gy()
	# far dunes (parallax) and the farm wall
	for i in 6:
		var bx := fposmod(i * 360.0 - _x * 0.2, size.x + 400.0) - 200.0
		draw_colored_polygon(PackedVector2Array([Vector2(bx - 260, gy), Vector2(bx, gy - 150 - (i % 3) * 30.0), Vector2(bx + 260, gy)]), Color.html("e5b86a"))
	for i in 5:
		var px := fposmod(i * 330.0 - _x * 0.5, size.x + 300.0) - 100.0
		draw_rect(Rect2(px, gy - 130, 10, 130), Color.html("7f5539"))
		draw_circle(Vector2(px + 5, gy - 140), 40.0, Color.html("2d6a4f"))
	draw_rect(Rect2(0, gy, size.x, size.y - gy), Color.html("c68b59"))
	draw_rect(Rect2(0, gy, size.x, 10), Color.html("a66a3b"))
	# ramps
	for r: float in _ramps:
		var sx := _sx(r)
		if sx > -300.0 and sx < size.x + 100.0:
			draw_colored_polygon(PackedVector2Array([Vector2(sx, gy), Vector2(sx + 150, gy - 82.5), Vector2(sx + 150, gy)]), Color.html("8b5e34"))
			draw_line(Vector2(sx, gy), Vector2(sx + 150, gy - 82.5), Color.html("5c3d2e"), 5.0)
	# finish line + stars
	var fx := _sx(TRACK_LEN)
	for k in 8:
		draw_rect(Rect2(fx + (k % 2) * 20.0, gy - 160 + k * 20.0, 20, 20), Color.WHITE if (k % 2 == 0) else Color.BLACK)
	for pk: Dictionary in _pickups:
		if pk["got"]:
			continue
		var p := Vector2(_sx(float(pk["x"])), gy - float(pk["y"]) - 20.0)
		if p.x > -30.0 and p.x < size.x + 30.0:
			_star(p, 15.0 + sin(_t * 6.0) * 2.0)
	# the bike + rider: back wheel at the bike position
	var bike := Vector2(300.0, gy - _h)
	_bike(bike, _tilt)
	text(Vector2(24, 40), "Time %d    Stars %d    %d m" % [maxi(0, ceili(_time_left)), _stars, int(_x / 10.0)], 28, Color.html("3d2c00"))
	text(Vector2(24, 72), "D / Right = gas    A / Left = brake    W / S = tilt in the air", 20, Color.html("3d2c00"))
	# progress bar
	draw_rect(Rect2(size.x - 320, 28, 280, 12), Color.html("3d2c00"))
	draw_circle(Vector2(size.x - 320 + 280.0 * clampf(_x / TRACK_LEN, 0.0, 1.0), 34), 10.0, Color.html("e63946"))
	# speedometer
	text(Vector2(size.x - 200, size.y - 24), "%d km/h" % int(_speed * 0.2), 34, Color.html("3d2c00"))
	if _flash_t > 0.0:
		text_c(Vector2(size.x * 0.5, 160), _flash, 44, Color.html("3d2c00"))
	if _crash_t > 0.0:
		text_c(Vector2(size.x * 0.5, 230), "Ouch!", 40, Color.html("9d0208"))


func _star(p: Vector2, r: float) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + i * PI / 5.0
		var rr := r if i % 2 == 0 else r * 0.45
		pts.append(p + Vector2(cos(a), sin(a)) * rr)
	draw_colored_polygon(pts, Color.html("ffd60a"))


func _bike(back: Vector2, rot: float) -> void:
	draw_set_transform(back + Vector2(40, -24), rot, Vector2.ONE)
	# wheels (local: back wheel at -40, front +40)
	var spin := _x * 0.06
	for wx: float in [-40.0, 40.0]:
		draw_circle(Vector2(wx, 0), 24.0, Color.html("212529"))
		draw_circle(Vector2(wx, 0), 14.0, Color.html("adb5bd"))
		draw_line(Vector2(wx, 0) + Vector2(cos(spin), sin(spin)) * 14.0, Vector2(wx, 0) - Vector2(cos(spin), sin(spin)) * 14.0, Color.html("495057"), 3.0)
	# frame, tank, fork, seat, exhaust
	draw_line(Vector2(-40, 0), Vector2(-4, -26), Color.html("e63946"), 7.0)
	draw_line(Vector2(-4, -26), Vector2(40, 0), Color.html("e63946"), 7.0)
	draw_line(Vector2(34, -4), Vector2(30, -42), Color.html("adb5bd"), 6.0)
	draw_line(Vector2(22, -44), Vector2(42, -46), Color.html("212529"), 5.0)
	draw_rect(Rect2(-6, -42, 34, 16), Color.html("e63946"))
	draw_rect(Rect2(-34, -34, 34, 9), Color.html("212529"))
	draw_line(Vector2(-14, -12), Vector2(-60, -22), Color.html("6c757d"), 6.0)
	# rider: the chosen sister, leaning forward, helmet in her hair colour
	var d: Dictionary = Game.CHARACTERS[Game.character_id]
	var dress := Color.html(d["color"])
	var hair := Color.html(d["hair"])
	var skin := Color("e8b98a")
	var hip := Vector2(-18, -38)
	var shoulder := Vector2(0, -78)
	var head := Vector2(8, -102)
	draw_line(hip, Vector2(10, -14), skin, 10.0)               # leg
	draw_line(hip, shoulder, dress, 22.0)                      # body
	draw_line(shoulder, Vector2(36, -50), skin, 8.0)           # arm to handlebar
	draw_circle(head + Vector2(-10, 8), 17.0, hair)            # hair behind
	draw_circle(head, 17.0, skin)
	draw_arc(head, 19.0, PI * 0.95, PI * 2.0, 14, Color.html("f4a261"), 9.0)      # helmet
	draw_circle(head + Vector2(8, -1), 2.5, Color.BLACK)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _speed > 60.0 and _h < 5.0:
		for i in 3:
			draw_circle(back + Vector2(-20 - i * 16 - randf() * 6.0, -6 - randf() * 8.0), 4.0 + i, Color(0.8, 0.65, 0.45, 0.6))
