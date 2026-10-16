extends MiniGameBase

const _Art := preload("res://scripts/ui/avatar_art.gd")
## Baqalah Snack Run (Frogger-style): Dad is waiting in the car! Dash across the busy
## forecourt to the shop, grab the snack on the list, then dash back to the car before a
## car hits you. Each safe delivery = 1 trip. Sarah has long legs (faster), Daniah gets
## slower traffic.

const GAME_TIME := 60.0
const LANES := 3
const SNACKS := ["Dates", "Juice", "Chips", "Biscuits", "Water", "Laban", "Chocolate", "Popcorn"]
const CAR_COLORS := ["e63946", "f1faee", "457b9d", "ffb703", "2a9d8f", "8d99ae", "f4a261", "9b5de5"]

var _cars: Array = []          # {"x", "lane", "w", "speed", "color"}
var _p: Vector2 = Vector2.ZERO
var _face: float = 1.0
var _walk_t: float = 0.0
var _carrying: bool = false
var _target: String = ""
var _trips: int = 0
var _time_left: float = 0.0
var _stun: float = 0.0
var _lane_top: float = 0.0
var _lane_h: float = 84.0
var _shop_y: float = 0.0
var _car_y: float = 0.0
var _msg: String = ""
var _msg_t: float = 0.0


func _ready() -> void:
	bg_color = Color.html("8d99ae")
	super()


func _on_start() -> void:
	_time_left = GAME_TIME + float(Game.mod("extra_time", 0.0))
	_lane_top = 240.0
	_shop_y = 170.0
	_car_y = size.y - 100.0
	_p = Vector2(size.x * 0.5, _car_y)
	_trips = 0
	_carrying = false
	_stun = 0.0
	_target = SNACKS[randi() % SNACKS.size()]
	_cars.clear()
	for lane in LANES:
		var dir := 1.0 if lane % 2 == 0 else -1.0
		var spd := dir * randf_range(70.0, 130.0)      # slow, friendly traffic
		var x := randf_range(0.0, 200.0)
		while x < size.x + 200.0:
			_cars.append({"x": x, "lane": lane, "w": randf_range(80.0, 110.0), "speed": spd, "color": Color.html(CAR_COLORS[randi() % CAR_COLORS.size()])})
			x += randf_range(480.0, 760.0)      # big gaps to cross


func _lane_y(l: int) -> float:
	return _lane_top + l * _lane_h


func _tick(delta: float) -> void:
	_time_left -= delta
	_msg_t = maxf(0.0, _msg_t - delta)
	_stun = maxf(0.0, _stun - delta)
	var traffic := float(Game.mod("slow_fall", 1.0))
	for c: Dictionary in _cars:
		c["x"] += float(c["speed"]) * traffic * delta
		if c["speed"] > 0.0 and c["x"] > size.x + 160.0:
			c["x"] = -float(c["w"]) - randf_range(0.0, 120.0)
		elif c["speed"] < 0.0 and c["x"] < -float(c["w"]) - 160.0:
			c["x"] = size.x + randf_range(0.0, 120.0)
	if _stun <= 0.0:
		var v := Input.get_vector("steer_left", "steer_right", "accelerate", "brake")
		if v.length() > 0.05:
			_walk_t += delta * 10.0
			if absf(v.x) > 0.1:
				_face = signf(v.x)
		var sp := 300.0 * float(Game.mod("reach", 1.0))
		_p += v * sp * delta
		_p.x = clampf(_p.x, 30.0, size.x - 30.0)
		_p.y = clampf(_p.y, _shop_y - 6.0, _car_y + 10.0)
		# hit by a car?
		var body := Rect2(_p.x - 9.0, _p.y - 28.0, 18.0, 30.0)     # small hit box: near misses are fine
		for c: Dictionary in _cars:
			var cy := _lane_y(c["lane"]) + 8.0
			if body.intersects(Rect2(float(c["x"]), cy, float(c["w"]), _lane_h - 16.0)):
				_stun = 0.6
				_say("Oops! Watch the car")     # no penalty: you keep your snack
				_p.y = _lane_top + LANES * _lane_h + 8.0 if _p.y > _lane_y(c["lane"]) + _lane_h * 0.5 else _lane_top - 8.0
				break
	# reach the shop / the car
	if not _carrying and _p.y < _shop_y + 24.0:
		_carrying = true
		_say("Got the %s! Back to the car!" % _target)
	elif _carrying and _p.y > _car_y - 24.0:
		_carrying = false
		_trips += 1
		_target = SNACKS[randi() % SNACKS.size()]
		_say("Delivered! +1 trip")
	if _time_left <= 0.0:
		complete(maxi(1, stars_from(_trips, 2, 4, 6)))


func _say(t: String) -> void:
	_msg = t
	_msg_t = 1.4


func _draw_game() -> void:
	if not running:
		return
	# shop at the top
	draw_rect(Rect2(0, 0, size.x, _shop_y), Color.html("e9c46a"))
	for i in 8:
		draw_rect(Rect2(40 + i * 150, 70, 110, 64), Color.html("f4a261"))
		draw_rect(Rect2(52 + i * 150, 80, 28, 22), Color.html(CAR_COLORS[i % CAR_COLORS.size()]))
		draw_rect(Rect2(88 + i * 150, 80, 28, 22), Color.html(CAR_COLORS[(i + 3) % CAR_COLORS.size()]))
	draw_rect(Rect2(0, 0, size.x, 56), Color.html("2a9d8f"))
	text_c(Vector2(size.x * 0.5 + 60.0, 40), "BAQALAH  -  grab: %s" % _target, 32, Color.WHITE)
	text(Vector2(24, 40), "Time %d    Trips %d" % [maxi(0, ceili(_time_left)), _trips], 26, Color.WHITE)
	# forecourt lanes
	for l in LANES:
		var y := _lane_y(l)
		draw_rect(Rect2(0, y, size.x, _lane_h), Color.html("3a3d42"))
		for k in range(0, int(size.x), 80):
			draw_line(Vector2(k, y + _lane_h - 2), Vector2(k + 40, y + _lane_h - 2), Color.html("f4f1de"), 3.0)
	draw_rect(Rect2(0, _lane_top + LANES * _lane_h, size.x, size.y - (_lane_top + LANES * _lane_h)), Color.html("a8a29e"))
	draw_rect(Rect2(0, _shop_y, size.x, _lane_top - _shop_y), Color.html("a8a29e"))
	# the family CX-9 waiting at the bottom
	var cx := size.x * 0.5
	draw_rect(Rect2(cx - 70, _car_y - 10, 140, 50), Color.html("1f4fa3"))
	draw_rect(Rect2(cx - 40, _car_y - 34, 80, 28), Color.html("6a9bd1"))
	draw_circle(Vector2(cx - 42, _car_y + 40), 11.0, Color.html("1a1a1c"))
	draw_circle(Vector2(cx + 42, _car_y + 40), 11.0, Color.html("1a1a1c"))
	text_c(Vector2(cx, _car_y + 72), "Dad's car", 18, Color.WHITE)
	# traffic
	for c: Dictionary in _cars:
		var cy := _lane_y(c["lane"]) + 10.0
		var x: float = c["x"]
		var w: float = c["w"]
		draw_rect(Rect2(x, cy, w, _lane_h - 20.0), c["color"])
		draw_rect(Rect2(x + w * 0.25, cy + 4.0, w * 0.5, _lane_h - 28.0), Color(0.1, 0.15, 0.2, 0.8))
		draw_circle(Vector2(x + w * 0.2, cy + _lane_h - 20.0), 7.0, Color.BLACK)
		draw_circle(Vector2(x + w * 0.8, cy + _lane_h - 20.0), 7.0, Color.BLACK)
	# the sister
	var flash := _stun > 0.0 and int(_stun * 12.0) % 2 == 0
	if not flash:
		_Art.draw_sister(self, Game.character_id, _p + Vector2(0, 4), 0.42, _face, absf(sin(_walk_t)) * 4.0, sin(_walk_t * 0.5) * 0.05)
		if _carrying:
			draw_rect(Rect2(_p.x - 12, _p.y - 112, 24, 24), Color.html("ffd166"))
			draw_rect(Rect2(_p.x - 12, _p.y - 112, 24, 24), Color.html("c77d00"), false, 2.0)
	if _msg_t > 0.0:
		text_c(Vector2(size.x * 0.5, _lane_top - 10.0), _msg, 28, Color.html("fff3b0"))
