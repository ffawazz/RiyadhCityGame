extends MiniGameBase
## Farm pool: switch lanes with W/S or Up/Down, collect rings, avoid floaties.
## Duck's swim_speed makes the water rush by faster, so more rings arrive.

const GAME_TIME := 25.0
const LANES := 4
const PLAYER_X := 160.0

var _time_left: float = 0.0
var _lane: int = 1
var _rings: int = 0
var _objs: Array = []   # {"x": float, "lane": int, "ring": bool}
var _spawn: float = 0.0
var _hit_flash: float = 0.0
var _bob: float = 0.0


func _ready() -> void:
	bg_color = Color.html("48cae4")
	super()


func _on_start() -> void:
	_time_left = GAME_TIME
	_lane = 1
	_rings = 0
	_objs.clear()
	_spawn = 0.0


func _lane_y(l: int) -> float:
	var top := 130.0
	return top + (size.y - top - 40.0) * (l + 0.5) / LANES


func _tick(delta: float) -> void:
	_time_left -= delta
	_bob += delta
	_hit_flash = maxf(0.0, _hit_flash - delta)
	var speed := 280.0 * float(Game.mod("swim_speed", 1.0))
	_spawn -= delta
	if _spawn <= 0.0:
		_spawn = 0.45 / float(Game.mod("swim_speed", 1.0))
		_objs.append({"x": size.x + 40.0, "lane": randi() % LANES, "ring": randf() < 0.72})
	for i in range(_objs.size() - 1, -1, -1):
		var o: Dictionary = _objs[i]
		o["x"] = float(o["x"]) - speed * delta
		if absf(float(o["x"]) - PLAYER_X) < 40.0 and int(o["lane"]) == _lane:
			if o["ring"]:
				_rings += 1
			else:
				_rings = maxi(0, _rings - 1)
				_hit_flash = 0.3
			_objs.remove_at(i)
		elif float(o["x"]) < -40.0:
			_objs.remove_at(i)
	if _time_left <= 0.0 and running:
		complete(maxi(1, stars_from(_rings, 8, 14, 20)))


func _on_input(event: InputEvent) -> void:
	if event.is_action_pressed("accelerate"):
		_lane = maxi(0, _lane - 1)
	elif event.is_action_pressed("brake"):
		_lane = mini(LANES - 1, _lane + 1)


func _draw_game() -> void:
	if not running:
		return
	for l in LANES + 1:
		draw_line(Vector2(0, 130.0 + (size.y - 170.0) * l / LANES), Vector2(size.x, 130.0 + (size.y - 170.0) * l / LANES),
				Color(1, 1, 1, 0.35), 3.0)
	text(Vector2(24, 40), "Time %d    Rings %d" % [maxi(0, ceili(_time_left)), _rings], 28, Color.html("023e8a"))
	text(Vector2(24, 80), "Swimming as the %s - W/S to change lane" % Game.animal()["name"], 22, Color.html("023e8a"))
	for o: Dictionary in _objs:
		var p := Vector2(float(o["x"]), _lane_y(int(o["lane"])) + sin(_bob * 4.0 + float(o["x"]) * 0.02) * 4.0)
		if o["ring"]:
			draw_arc(p, 20.0, 0, TAU, 24, Color.html("ffd60a"), 8.0)
		else:
			draw_circle(p, 24.0, Color.html("ff006e"))
			draw_circle(p, 10.0, Color.html("48cae4"))
	var me := Vector2(PLAYER_X, _lane_y(_lane))
	draw_circle(me, 30.0, Color.html("ffd60a") if _hit_flash <= 0.0 else Color.html("ff0054"))
	draw_circle(me + Vector2(26, -6), 16.0, Color.html("ffd60a"))
	draw_colored_polygon(PackedVector2Array([me + Vector2(40, -8), me + Vector2(58, -2), me + Vector2(40, 2)]), Color.html("ff7b00"))
