extends MiniGameBase

const _Art := preload("res://scripts/ui/avatar_art.gd")
## Slide: whoosh down a big slide. A / D change lane, SPACE jumps the toys, grab stars,
## and splash into the pool at the bottom.

const GAME_TIME := 25.0
const HORIZON := 150.0

var _lane: int = 1
var _lane_x: float = 1.0       # smoothed lane position 0..2
var _jump: float = 0.0
var _time_left: float = 0.0
var _speed: float = 0.5
var _items: Array = []         # {z, lane, kind}
var _spawn: float = 0.0
var _points: int = 0
var _stars: int = 0
var _hits: int = 0
var _hit_t: float = 0.0
var _flash: String = ""
var _flash_t: float = 0.0
var _t: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	bg_color = Color.html("a2d2ff")
	super()


func _on_start() -> void:
	_rng.randomize()
	_time_left = GAME_TIME
	_lane = 1
	_lane_x = 1.0
	_speed = 0.5
	_items.clear()
	_points = 0
	_stars = 0
	_hits = 0


func _lane_pos(lane_f: float, z: float) -> float:
	# screen x for a lane at depth z (0 far .. 1 near)
	var half := lerpf(70.0, 520.0, z)
	return size.x * 0.5 + (lane_f - 1.0) * half * 0.62


func _z_y(z: float) -> float:
	return lerpf(HORIZON, size.y - 70.0, z * z * 0.5 + z * 0.5)


func _tick(delta: float) -> void:
	_t += delta
	_time_left -= delta
	_flash_t = maxf(0.0, _flash_t - delta)
	_hit_t = maxf(0.0, _hit_t - delta)
	_jump = maxf(0.0, _jump - delta)
	_lane_x = lerpf(_lane_x, float(_lane), 1.0 - exp(-14.0 * delta))
	_speed = minf(1.1, _speed + 0.02 * delta)
	_spawn -= delta
	if _spawn <= 0.0:
		_spawn = 0.5
		var lane_star := _rng.randi() % 3
		_items.append({"z": 0.0, "lane": lane_star, "kind": "star"})
		if _rng.randf() < 0.55:
			var l2 := (lane_star + 1 + _rng.randi() % 2) % 3
			_items.append({"z": 0.0, "lane": l2, "kind": "toy"})
	for i in range(_items.size() - 1, -1, -1):
		var it: Dictionary = _items[i]
		it["z"] = float(it["z"]) + _speed * delta * 0.9
		if float(it["z"]) >= 0.86 and float(it["z"]) <= 0.97 and int(it["lane"]) == _lane:
			if it["kind"] == "star":
				_stars += 1
				_points += 2
				_items.remove_at(i)
				continue
			elif _jump <= 0.0 and _hit_t <= 0.0:
				_hits += 1
				_points = maxi(0, _points - 2)
				_hit_t = 0.8
				_speed = maxf(0.4, _speed - 0.2)
				_flash = "Bonk!"
				_flash_t = 0.7
				_items.remove_at(i)
				continue
		if float(it["z"]) > 1.1:
			_items.remove_at(i)
	if _time_left <= 0.0 and running:
		complete(maxi(1, stars_from(_points, 14, 26, 38)))


func _on_input(event: InputEvent) -> void:
	if event.is_action_pressed("steer_left"):
		_lane = maxi(0, _lane - 1)
	elif event.is_action_pressed("steer_right"):
		_lane = mini(2, _lane + 1)
	elif is_confirm(event) and _jump <= 0.0:
		_jump = 0.6


func _draw_game() -> void:
	if not running:
		return
	# sky, hills, grass
	draw_rect(Rect2(0, HORIZON - 20, size.x, size.y), Color.html("90be6d"))
	draw_colored_polygon(PackedVector2Array([Vector2(0, HORIZON), Vector2(300, HORIZON - 90), Vector2(620, HORIZON)]), Color.html("52b788"))
	draw_colored_polygon(PackedVector2Array([Vector2(500, HORIZON), Vector2(900, HORIZON - 110), Vector2(1280, HORIZON)]), Color.html("74c69d"))
	# the slide
	var top_l := Vector2(_lane_pos(-0.8, 0.0), HORIZON)
	var top_r := Vector2(_lane_pos(2.8, 0.0), HORIZON)
	var bot_l := Vector2(_lane_pos(-0.8, 1.0), size.y)
	var bot_r := Vector2(_lane_pos(2.8, 1.0), size.y)
	draw_colored_polygon(PackedVector2Array([top_l, top_r, bot_r, bot_l]), Color.html("f94144"))
	draw_colored_polygon(PackedVector2Array([Vector2(_lane_pos(-0.5, 0.0), HORIZON), Vector2(_lane_pos(2.5, 0.0), HORIZON), Vector2(_lane_pos(2.5, 1.0), size.y), Vector2(_lane_pos(-0.5, 1.0), size.y)]), Color.html("48cae4"))
	for k in [0.5, 1.5]:
		draw_line(Vector2(_lane_pos(k, 0.0), HORIZON), Vector2(_lane_pos(k, 1.0), size.y), Color(1, 1, 1, 0.5), 3.0)
	# moving stripes for the feeling of speed
	for i in 9:
		var z := fposmod(float(i) / 9.0 + _t * _speed * 0.9, 1.0)
		var y := _z_y(z)
		draw_line(Vector2(_lane_pos(-0.5, z), y), Vector2(_lane_pos(2.5, z), y), Color(1, 1, 1, 0.25), 2.0 + 4.0 * z)
	# items far to near
	var sorted := _items.duplicate()
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["z"]) < float(b["z"]))
	for it: Dictionary in sorted:
		var z: float = it["z"]
		var p := Vector2(_lane_pos(float(it["lane"]), z), _z_y(z))
		var sc := lerpf(0.25, 1.4, z)
		if it["kind"] == "star":
			var pts := PackedVector2Array()
			for i in 10:
				var a := -PI / 2.0 + i * PI / 5.0
				pts.append(p + Vector2(0, -22.0 * sc) + Vector2(cos(a), sin(a)) * (20.0 if i % 2 == 0 else 9.0) * sc)
			draw_colored_polygon(pts, Color.html("ffd60a"))
		else:
			draw_rect(Rect2(p + Vector2(-24, -44) * sc, Vector2(48, 44) * sc), Color.html("3a86ff"))
			draw_rect(Rect2(p + Vector2(-24, -44) * sc, Vector2(48, 12) * sc), Color.html("ffbe0b"))
			text_c(p + Vector2(0, -12) * sc, "A", int(26 * sc), Color.WHITE)
	# the rider
	var px := _lane_pos(_lane_x, 0.93)
	var py := _z_y(0.93) - (sin((0.6 - _jump) / 0.6 * PI) * 90.0 if _jump > 0.0 else 0.0)
	var lean := clampf((float(_lane) - _lane_x) * 0.35, -0.3, 0.3)
	draw_circle(Vector2(px, _z_y(0.93)), 34.0, Color(0, 0, 0, 0.22))
	_Art.draw_sister(self, Game.character_id, Vector2(px, py + 6.0), 0.62, 1.0, 0.0, lean + (sin(_t * 30.0) * 0.1 if _hit_t > 0.0 else 0.0))
	# splash pool at the very end
	if _time_left < 1.5:
		var f := 1.0 - _time_left / 1.5
		draw_rect(Rect2(0, size.y * (1.0 - f), size.x, size.y * f), Color(0.2, 0.7, 0.95, 0.6))
	_Art.draw_animal(self, Game.animal_id, Vector2(90, size.y - 14), 0.6)
	text(Vector2(24, 40), "Time %d    Stars %d    Points %d" % [maxi(0, ceili(_time_left)), _stars, _points], 28, Color.html("1d3557"))
	if _flash_t > 0.0:
		text_c(Vector2(size.x * 0.5, 120), _flash, 40, Color.html("3d2c00"))
