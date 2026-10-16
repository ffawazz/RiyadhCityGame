extends MiniGameBase

const _Art := preload("res://scripts/ui/avatar_art.gd")
## Hen house: hens lay eggs in the nests. Collect each egg before it hatches into a chick (3.5 s).
## Golden eggs are worth 3.

const GAME_TIME := 35.0

var _time_left: float = 0.0
var _score: int = 0
var _missed: int = 0
var _nests: Array = []     # {pos, egg(-1 none else age), golden, cluck, chick}
var _spawn: float = 0.0
var _t: float = 0.0
var _flash: String = ""
var _flash_t: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	bg_color = Color.html("7f5539")
	super()


func _on_start() -> void:
	_rng.randomize()
	_time_left = GAME_TIME
	_score = 0
	_missed = 0
	_spawn = 0.6
	_nests.clear()
	for row in 2:
		for col in 4:
			_nests.append({"pos": Vector2(250.0 + col * 260.0, 250.0 + row * 210.0), "egg": -1.0, "golden": false, "cluck": 0.0, "chick": 0.0})


func _tick(delta: float) -> void:
	_t += delta
	_time_left -= delta
	_flash_t = maxf(0.0, _flash_t - delta)
	pointer_move(delta)
	_spawn -= delta
	if _spawn <= 0.0:
		_spawn = _rng.randf_range(0.5, 1.0)
		var free: Array = _nests.filter(func(n: Dictionary) -> bool: return float(n["egg"]) < 0.0 and float(n["chick"]) <= 0.0)
		if not free.is_empty():
			var n: Dictionary = free[_rng.randi() % free.size()]
			n["egg"] = 0.0
			n["golden"] = _rng.randf() < 0.15
			n["cluck"] = 1.0
	for n: Dictionary in _nests:
		n["cluck"] = maxf(0.0, float(n["cluck"]) - delta)
		n["chick"] = maxf(0.0, float(n["chick"]) - delta)
		if float(n["egg"]) >= 0.0:
			n["egg"] = float(n["egg"]) + delta
			if float(n["egg"]) > 3.5:
				n["egg"] = -1.0
				n["chick"] = 1.6
				_missed += 1
	if _time_left <= 0.0 and running:
		complete(maxi(1, stars_from(_score, 12, 22, 32)))


func _on_input(event: InputEvent) -> void:
	pointer_event(event)
	if not is_confirm(event):
		return
	for n: Dictionary in _nests:
		if float(n["egg"]) >= 0.0 and pointer.distance_to((n["pos"] as Vector2) + Vector2(0, -16)) < 48.0:
			_score += 3 if n["golden"] else 1
			_flash = "Golden egg! +3" if n["golden"] else "Got it! +1"
			_flash_t = 0.7
			n["egg"] = -1.0
			return


func _draw_egg(p: Vector2, golden: bool, wobble: float) -> void:
	draw_set_transform(p, sin(_t * 18.0) * wobble, Vector2(0.8, 1.0))
	var c := Color.html("ffd60a") if golden else Color.html("fff1e0")
	draw_circle(Vector2.ZERO, 24.0, c.darkened(0.15))
	draw_circle(Vector2(-3, -3), 21.0, c)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if golden:
		draw_circle(p + Vector2(-8, -10), 4.0, Color.WHITE)


func _draw_game() -> void:
	if not running:
		return
	# wooden wall + shelves
	for i in 12:
		draw_rect(Rect2(i * 110, 0, 108, size.y), Color.html("8d6a45") if i % 2 == 0 else Color.html("7f5d3b"))
	for row in 2:
		draw_rect(Rect2(60, 300 + row * 210, size.x - 120, 18), Color.html("4a3320"))
	for n: Dictionary in _nests:
		var p: Vector2 = n["pos"]
		# hen behind the nest
		var lift := absf(sin(_t * 10.0)) * 8.0 if float(n["cluck"]) > 0.0 else 0.0
		_Art.draw_animal(self, "chicken", p + Vector2(-60, 56), 0.5, 1.0, lift)
		draw_arc(p + Vector2(0, 30), 56.0, 0.15, PI - 0.15, 16, Color.html("e0b84c"), 14.0)   # straw nest
		if float(n["egg"]) >= 0.0:
			var urgent := float(n["egg"]) > 2.4
			_draw_egg(p + Vector2(0, -6), n["golden"], 0.15 if urgent else 0.0)
			var frac := 1.0 - float(n["egg"]) / 3.5
			draw_arc(p + Vector2(0, -6), 38.0, -PI / 2.0, -PI / 2.0 + TAU * frac, 16, Color.html("80b918") if not urgent else Color.html("e63946"), 4.0)
		if float(n["chick"]) > 0.0:
			draw_circle(p + Vector2(0, -2), 16.0, Color.html("ffd60a"))
			draw_circle(p + Vector2(10, -10), 3.0, Color.BLACK)
			text_c(p + Vector2(0, -34), "peep!", 18, Color.WHITE)
	# basket
	draw_rect(Rect2(size.x - 190, size.y - 90, 160, 70), Color.html("c38e5b"))
	text_c(Vector2(size.x - 110, size.y - 40), "x %d" % _score, 34, Color.html("3d2c00"))
	_Art.draw_sister(self, Game.character_id, Vector2(120, size.y - 10), 0.85)
	text(Vector2(24, 40), "Time %d    Eggs %d    Hatched %d" % [maxi(0, ceili(_time_left)), _score, _missed], 28, Color.WHITE)
	if _flash_t > 0.0:
		text_c(Vector2(size.x * 0.5, 110), _flash, 38, Color.WHITE)
	draw_pointer()
