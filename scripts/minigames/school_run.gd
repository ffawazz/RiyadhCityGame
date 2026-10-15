extends MiniGameBase

const _Art := preload("res://scripts/ui/avatar_art.gd")
## Run to Class! The bell is about to ring. Sprint down the school hallway, jump (W / Up /
## Space - tap again for a double jump, hold for height) over backpacks, chairs, wet-floor
## signs and puddles, and grab pencils (+1) and books (+3). Daniah floats a little, Sarah
## collects from further away, Lamia gets extra time.

const GAME_TIME := 35.0
const PLAYER_X := 230.0
const BASE_SPEED := 380.0
const MAX_SPEED := 580.0

var _ground: float = 0.0
var _dist: float = 0.0
var _speed: float = BASE_SPEED
var _py: float = 0.0           # height above the floor
var _vy: float = 0.0
var _jumps: int = 0
var _hit_cd: float = 0.0
var _score: int = 0
var _hits: int = 0
var _time_left: float = 0.0
var _next_spawn: float = 700.0
var _obstacles: Array = []     # {"x", "w", "h", "kind"}
var _items: Array = []         # {"x", "y", "kind", "taken"}
var _run_t: float = 0.0
var _msg: String = ""
var _msg_t: float = 0.0


func _ready() -> void:
	bg_color = Color.html("fdf0d5")
	super()


func _on_start() -> void:
	_ground = size.y - 150.0
	_time_left = GAME_TIME + float(Game.mod("extra_time", 0.0))
	_dist = 0.0
	_speed = BASE_SPEED
	_py = 0.0
	_vy = 0.0
	_jumps = 0
	_score = 0
	_hits = 0
	_hit_cd = 0.0
	_next_spawn = 700.0
	_obstacles.clear()
	_items.clear()


func _on_input(event: InputEvent) -> void:
	if event.is_action_pressed("accelerate") or event.is_action_pressed("ui_accept") or event.is_action_pressed("handbrake"):
		if _jumps < 2:
			_vy = 640.0 if _jumps == 0 else 560.0
			_jumps += 1


func _tick(delta: float) -> void:
	_time_left -= delta
	_msg_t = maxf(0.0, _msg_t - delta)
	_hit_cd = maxf(0.0, _hit_cd - delta)
	_run_t += delta * (_speed / 40.0)
	_speed = minf(_speed + 14.0 * delta, MAX_SPEED)
	_dist += _speed * delta
	# jump physics (hold to go higher)
	var holding := Input.is_action_pressed("accelerate") or Input.is_action_pressed("ui_accept") or Input.is_action_pressed("handbrake")
	var g := 1800.0 * float(Game.mod("slow_fall", 1.0))
	if not holding and _vy > 260.0:
		_vy = 260.0
	_vy -= g * delta
	_py += _vy * delta
	if _py <= 0.0:
		_py = 0.0
		_vy = 0.0
		_jumps = 0
	# spawn patterns ahead of the player
	while _next_spawn < _dist + size.x + 300.0:
		_spawn_pattern(_next_spawn)
		_next_spawn += randf_range(300.0, 440.0)
	# obstacles
	for o: Dictionary in _obstacles:
		var sx: float = PLAYER_X + float(o["x"]) - _dist
		if _hit_cd <= 0.0 and sx > PLAYER_X - 16.0 - float(o["w"]) and sx < PLAYER_X + 16.0 and _py < float(o["h"]) - 6.0:
			_hit_cd = 1.2
			_hits += 1
			_speed = maxf(_speed * 0.55, 240.0)
			_say("Oops!")
	# items
	var magnet := 34.0 * float(Game.mod("reach", 1.0))
	for it: Dictionary in _items:
		if it["taken"]:
			continue
		var sx2: float = PLAYER_X + float(it["x"]) - _dist
		if absf(sx2 - PLAYER_X) < magnet and absf(float(it["y"]) - (_py + 30.0)) < magnet + 14.0:
			it["taken"] = true
			_score += 3 if it["kind"] == "book" else 1
	_obstacles = _obstacles.filter(func(o: Dictionary) -> bool: return float(o["x"]) > _dist - 300.0)
	_items = _items.filter(func(it: Dictionary) -> bool: return float(it["x"]) > _dist - 300.0)
	if _time_left <= 0.0:
		complete(maxi(1, stars_from(_score, 18, 32, 48)))


func _spawn_pattern(x: float) -> void:
	var roll := randi() % 5
	var kind := ["bag", "chair", "sign", "puddle", "bag"][roll] as String
	var dims := {"bag": Vector2(38, 40), "chair": Vector2(46, 58), "sign": Vector2(38, 64), "puddle": Vector2(110, 8)}
	var dim: Vector2 = dims[kind]
	_obstacles.append({"x": x, "w": dim.x, "h": dim.y, "kind": kind})
	# an arc of pencils over the obstacle, and sometimes a book at the top
	for i in 5:
		var t := float(i) / 4.0
		_items.append({"x": x - 70.0 + t * (dim.x + 140.0), "y": 40.0 + sin(t * PI) * (dim.y + 50.0), "kind": "pencil", "taken": false})
	if randf() < 0.35:
		_items.append({"x": x + dim.x * 0.5, "y": dim.y + 110.0, "kind": "book", "taken": false})
	if randf() < 0.5:   # a ground row of pencils between obstacles
		for i in 4:
			_items.append({"x": x + 190.0 + i * 36.0, "y": 34.0, "kind": "pencil", "taken": false})


func _say(t: String) -> void:
	_msg = t
	_msg_t = 0.8


func _draw_game() -> void:
	if not running:
		return
	var floor_y := _ground + 8.0
	# hallway: wall, lockers (slow parallax), floor tiles
	draw_rect(Rect2(0, 0, size.x, floor_y), Color.html("f6e8c3"))
	var lock_off := fmod(_dist * 0.5, 80.0)
	for i in range(-1, int(size.x / 80.0) + 2):
		var lx := i * 80.0 - lock_off
		var col := Color.html(["457b9d", "2a9d8f", "e76f51", "e9c46a"][(i + int(_dist * 0.5 / 80.0)) % 4 if (i + int(_dist * 0.5 / 80.0)) >= 0 else 0])
		draw_rect(Rect2(lx + 6, floor_y - 250, 68, 240), col)
		draw_rect(Rect2(lx + 6, floor_y - 250, 68, 240), Color(0, 0, 0, 0.25), false, 3.0)
		draw_rect(Rect2(lx + 14, floor_y - 220, 8, 40), Color(1, 1, 1, 0.5))
	var win_off := fmod(_dist * 0.25, 260.0)
	for i in range(-1, int(size.x / 260.0) + 2):
		var wx := i * 260.0 - win_off
		draw_rect(Rect2(wx + 40, 90, 150, 110), Color.html("8ecae6"))
		draw_rect(Rect2(wx + 40, 90, 150, 110), Color.html("6c584c"), false, 6.0)
		draw_line(Vector2(wx + 115, 90), Vector2(wx + 115, 200), Color.html("6c584c"), 5.0)
	draw_rect(Rect2(0, 0, size.x, 60), Color.html("e5d3a1"))                    # ceiling
	var tile_off := fmod(_dist, 90.0)
	draw_rect(Rect2(0, floor_y, size.x, size.y - floor_y), Color.html("b7a37a"))
	for i in range(-1, int(size.x / 90.0) + 2):
		draw_line(Vector2(i * 90.0 - tile_off, floor_y), Vector2(i * 90.0 - tile_off - 30.0, size.y), Color(0, 0, 0, 0.15), 3.0)
	# obstacles
	for o: Dictionary in _obstacles:
		var sx: float = PLAYER_X + float(o["x"]) - _dist
		if sx < -150.0 or sx > size.x + 50.0:
			continue
		var w: float = o["w"]
		var h: float = o["h"]
		match o["kind"]:
			"bag":
				draw_rect(Rect2(sx, _ground - h + 8.0, w, h), Color.html("ef476f"))
				draw_rect(Rect2(sx + 8, _ground - h + 18.0, w - 16, 12), Color.html("ffd166"))
			"chair":
				draw_rect(Rect2(sx, _ground - 26.0, w, 8), Color.html("8d6e63"))
				draw_rect(Rect2(sx, _ground - h + 8.0, 8, h - 8.0), Color.html("8d6e63"))
				draw_rect(Rect2(sx + w - 6, _ground - 20.0, 6, 28), Color.html("5d4037"))
			"sign":
				draw_colored_polygon(PackedVector2Array([Vector2(sx, _ground + 8.0), Vector2(sx + w, _ground + 8.0), Vector2(sx + w * 0.5, _ground - h + 8.0)]), Color.html("ffd60a"))
				text_c(Vector2(sx + w * 0.5, _ground - 6.0), "!", 26, Color.BLACK)
			"puddle":
				draw_rect(Rect2(sx, _ground + 2.0, w, 8), Color(0.2, 0.55, 0.9, 0.9))
	# items
	for it: Dictionary in _items:
		if it["taken"]:
			continue
		var ix: float = PLAYER_X + float(it["x"]) - _dist
		if ix < -30.0 or ix > size.x + 30.0:
			continue
		var iy: float = _ground + 8.0 - float(it["y"])
		if it["kind"] == "book":
			draw_rect(Rect2(ix - 14, iy - 10, 28, 20), Color.html("457b9d"))
			draw_rect(Rect2(ix - 11, iy - 7, 22, 14), Color.html("f1faee"))
		else:
			draw_rect(Rect2(ix - 3, iy - 12, 6, 20), Color.html("ffd166"))
			draw_colored_polygon(PackedVector2Array([Vector2(ix - 3, iy - 12), Vector2(ix + 3, iy - 12), Vector2(ix, iy - 20)]), Color.html("ef476f"))
	# the sister
	var blink := _hit_cd > 0.0 and int(_hit_cd * 12.0) % 2 == 0
	if not blink:
		var bob := absf(sin(_run_t)) * 5.0 if _py <= 0.0 else 0.0
		_Art.draw_sister(self, Game.character_id, Vector2(PLAYER_X, _ground + 8.0), 0.5, 1.0, _py + bob, 0.12 + sin(_run_t) * 0.05)
	# finish: the classroom door slides in at the end
	if _time_left < 4.0:
		var dx := size.x - (4.0 - _time_left) / 4.0 * 360.0
		draw_rect(Rect2(dx, floor_y - 200, 110, 200), Color.html("6c584c"))
		text_c(Vector2(dx + 55, floor_y - 210), "CLASS", 26, Color.html("3d2c00"))
	text(Vector2(24, 40), "Bell in %d    Score %d" % [maxi(0, ceili(_time_left)), _score], 30, Color.html("264653"))
	text(Vector2(24, 72), "Jump: W / Up / Space (tap twice = double jump)", 18, Color.html("264653"))
	if _msg_t > 0.0:
		text_c(Vector2(PLAYER_X, _ground - 150.0), _msg, 30, Color.html("d62828"))
