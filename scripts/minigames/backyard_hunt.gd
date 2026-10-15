extends MiniGameBase
## Backyard: find 5 hidden treasures. Move the shovel with WASD/arrows (or mouse),
## dig with Space / click. The "warmth" bar shows how close the nearest one is.
## Lamia's animal friends enlarge the dig radius.

const GAME_TIME := 40.0
const TREASURES := ["toy bone", "ball", "key", "feather", "coin"]
const SPEED := 360.0

var _time_left: float = 0.0
var _cursor: Vector2 = Vector2.ZERO
var _hidden: Array = []   # {"pos": Vector2, "name": String, "found": bool}
var _found: int = 0
var _dug: Array[Vector2] = []
var _cooldown: float = 0.0
var _msg: String = ""


func _ready() -> void:
	bg_color = Color.html("8ab17d")
	super()


func _on_start() -> void:
	_time_left = GAME_TIME + float(Game.mod("extra_time", 0.0))
	_found = 0
	_dug.clear()
	_cursor = size * 0.5
	_hidden.clear()
	for n in TREASURES:
		_hidden.append({"pos": Vector2(randf_range(80, size.x - 80), randf_range(130, size.y - 80)),
				"name": n, "found": false})


func _radius() -> float:
	return 55.0 * float(Game.mod("animal_bonus", 1.0))


func _nearest() -> float:
	var best := 99999.0
	for h: Dictionary in _hidden:
		if not h["found"]:
			best = minf(best, (h["pos"] as Vector2).distance_to(_cursor))
	return best


func _dig() -> void:
	if _cooldown > 0.0:
		return
	_cooldown = 0.35
	_dug.append(_cursor)
	for h: Dictionary in _hidden:
		if not h["found"] and (h["pos"] as Vector2).distance_to(_cursor) <= _radius():
			h["found"] = true
			_found += 1
			_msg = "Found a %s!" % h["name"]
			if _found >= _hidden.size():
				complete(3 if _time_left > 10.0 else 2)
			return
	_msg = "Nothing here..."


func _tick(delta: float) -> void:
	_time_left -= delta
	_cooldown = maxf(0.0, _cooldown - delta)
	var v := Input.get_vector("steer_left", "steer_right", "accelerate", "brake")
	_cursor = (_cursor + v * SPEED * delta).clamp(Vector2(20, 100), size - Vector2(20, 20))
	if _time_left <= 0.0 and running:
		complete(1 if _found < 3 else 2)


func _on_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_cursor = get_local_mouse_position().clamp(Vector2(20, 100), size - Vector2(20, 20))
	elif is_confirm(event):
		if event is InputEventMouseButton:
			_cursor = get_local_mouse_position().clamp(Vector2(20, 100), size - Vector2(20, 20))
		_dig()


func _draw_game() -> void:
	if not running:
		return
	text(Vector2(24, 40), "Time %d    Treasures %d / %d    %s" % [
			maxi(0, ceili(_time_left)), _found, _hidden.size(), _msg], 28, Color.WHITE)
	for p in _dug:
		draw_circle(p, 18.0, Color.html("6b4f2a"))
	for h: Dictionary in _hidden:
		if h["found"]:
			draw_circle(h["pos"], 20.0, Color.html("ffd166"))
	# warmth bar: red = hot, blue = cold
	var warm := clampf(1.0 - _nearest() / 600.0, 0.0, 1.0)
	var bar := Rect2(size.x - 260, 20, 220, 26)
	draw_rect(bar, Color.html("264653"))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * warm, bar.size.y)), Color.html("457b9d").lerp(Color.html("e63946"), warm))
	text(Vector2(bar.position.x - 100, 42), "Warmth", 22, Color.WHITE)
	draw_arc(_cursor, _radius(), 0, TAU, 32, Color(1, 1, 1, 0.7), 3.0)
	draw_line(_cursor + Vector2(-12, 0), _cursor + Vector2(12, 0), Color.WHITE, 3.0)
	draw_line(_cursor + Vector2(0, -12), _cursor + Vector2(0, 12), Color.WHITE, 3.0)
