extends MiniGameBase

const _Art := preload("res://scripts/ui/avatar_art.gd")
## Feed the goats: every goat shows the food it wants. Choose a food (1 / 2 / 3 or tap the tray),
## aim at a goat and click / tap / SPACE to throw it. Right food = +2, wrong food = grumpy goat.

const GAME_TIME := 40.0
const FOODS := ["hay", "carrot", "apple"]

var _time_left: float = 0.0
var _score: int = 0
var _food: int = 0
var _goats: Array = []     # {x, dir, y, want, mood(0 normal,1 happy,2 sad), mood_t, patience}
var _shots: Array = []     # {from, to, t, goat, food}
var _t: float = 0.0
var _flash: String = ""
var _flash_t: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	bg_color = Color.html("bde0fe")
	super()


func _on_start() -> void:
	_rng.randomize()
	_time_left = GAME_TIME
	_score = 0
	_food = 0
	_shots.clear()
	_goats.clear()
	for i in 4:
		_goats.append({"x": 200.0 + i * 280.0, "dir": 1.0 if i % 2 == 0 else -1.0, "y": 440.0 + (i % 2) * 40.0,
				"want": _rng.randi() % 3, "mood": 0, "mood_t": 0.0, "patience": 9.0})


func _tray_pos(i: int) -> Vector2:
	return Vector2(size.x * 0.5 + (i - 1) * 140.0, size.y - 68.0)


func _tick(delta: float) -> void:
	_t += delta
	_time_left -= delta
	_flash_t = maxf(0.0, _flash_t - delta)
	pointer_move(delta)
	var speed := 36.0
	for g: Dictionary in _goats:
		g["x"] = float(g["x"]) + float(g["dir"]) * speed * delta * (0.4 if int(g["mood"]) == 1 else 1.0)
		if float(g["x"]) < 120.0 or float(g["x"]) > size.x - 120.0:
			g["dir"] = -float(g["dir"])
		if float(g["mood_t"]) > 0.0:
			g["mood_t"] = float(g["mood_t"]) - delta
			if float(g["mood_t"]) <= 0.0:
				g["mood"] = 0
				if int(g["mood"]) == 0:
					g["want"] = _rng.randi() % 3
					g["patience"] = 9.0
		else:
			g["patience"] = float(g["patience"]) - delta
			if float(g["patience"]) <= 0.0:   # got bored: wants something else
				g["want"] = _rng.randi() % 3
				g["patience"] = 9.0
	for i in range(_shots.size() - 1, -1, -1):
		var s: Dictionary = _shots[i]
		s["t"] = float(s["t"]) + delta * 2.6
		if float(s["t"]) >= 1.0:
			_hit(s)
			_shots.remove_at(i)
	if _time_left <= 0.0 and running:
		complete(maxi(1, stars_from(_score, 8, 16, 24)))


func _hit(s: Dictionary) -> void:
	var g: Dictionary = _goats[int(s["goat"])]
	if int(g["mood"]) != 0:
		return
	if int(s["food"]) == int(g["want"]):
		_score += 2
		g["mood"] = 1
		g["mood_t"] = 1.4
		_flash = "Yum! +2"
	else:
		g["mood"] = 2
		g["mood_t"] = 1.2
		_flash = "Bleh! Wrong food"
	_flash_t = 0.8


func _on_input(event: InputEvent) -> void:
	pointer_event(event)
	var d := digit_of(event)
	if d >= 1 and d <= 3:
		_food = d - 1
		return
	if event.is_action_pressed("steer_right") and not (event is InputEventMouse):
		_food = (_food + 1) % 3
		return
	if not is_confirm(event):
		return
	for i in 3:                                   # tapped the food tray?
		if pointer.distance_to(_tray_pos(i)) < 56.0:
			_food = i
			return
	var best := -1
	var best_d := 90.0
	for i in _goats.size():
		var g: Dictionary = _goats[i]
		var d2 := pointer.distance_to(Vector2(g["x"], float(g["y"]) - 50.0))
		if d2 < best_d:
			best_d = d2
			best = i
	if best >= 0:
		var g: Dictionary = _goats[best]
		_shots.append({"from": _tray_pos(_food), "to": Vector2(g["x"], float(g["y"]) - 60.0), "t": 0.0, "goat": best, "food": _food})


func _draw_food(kind: int, p: Vector2, sc: float = 1.0) -> void:
	match FOODS[kind]:
		"hay":
			draw_rect(Rect2(p + Vector2(-22, -14) * sc, Vector2(44, 28) * sc), Color.html("e0b84c"))
			for i in 4:
				draw_line(p + Vector2(-18 + i * 12, -14) * sc, p + Vector2(-22 + i * 14, -24) * sc, Color.html("c99a2e"), 3.0)
		"carrot":
			draw_colored_polygon(PackedVector2Array([p + Vector2(-8, -14) * sc, p + Vector2(8, -14) * sc, p + Vector2(0, 22) * sc]), Color.html("ff8c42"))
			draw_rect(Rect2(p + Vector2(-8, -24) * sc, Vector2(16, 10) * sc), Color.html("52b788"))
		_:
			draw_circle(p, 17.0 * sc, Color.html("e63946"))
			draw_rect(Rect2(p + Vector2(-1, -24) * sc, Vector2(3, 10) * sc), Color.html("6b4f3a"))


func _draw_game() -> void:
	if not running:
		return
	draw_rect(Rect2(0, 330, size.x, size.y - 330), Color.html("90be6d"))
	draw_rect(Rect2(0, 400, size.x, 14), Color.html("8b5e34"))                       # fence rails
	draw_rect(Rect2(0, 430, size.x, 14), Color.html("8b5e34"))
	for i in 14:
		draw_rect(Rect2(40 + i * 92, 380, 12, 90), Color.html("6f4518"))
	for g: Dictionary in _goats:
		var p := Vector2(g["x"], g["y"])
		var sad := int(g["mood"]) == 2
		_Art.draw_animal(self, "goat", p, 0.75, 1.0 if float(g["dir"]) > 0.0 else -1.0, absf(sin(_t * 6.0)) * 12.0 if int(g["mood"]) == 1 else 0.0, 0.0)
		# speech bubble with the wanted food
		var b := p + Vector2(0, -160)
		draw_circle(b, 34.0, Color(1, 1, 1, 0.95))
		draw_circle(b + Vector2(0, 38), 8.0, Color(1, 1, 1, 0.95))
		if int(g["mood"]) == 0:
			_draw_food(int(g["want"]), b)
			var frac := clampf(float(g["patience"]) / 9.0, 0.0, 1.0)
			draw_arc(b, 38.0, -PI / 2.0, -PI / 2.0 + TAU * frac, 20, Color.html("80b918"), 4.0)
		else:
			text_c(b + Vector2(0, 10), "!!" if sad else "<3", 30, Color.html("c1121f") if sad else Color.html("e63946"))
	for s: Dictionary in _shots:
		var f := float(s["t"])
		_draw_food(int(s["food"]), (s["from"] as Vector2).lerp(s["to"], f) + Vector2(0, -sin(f * PI) * 90.0), 0.8)
	# tray
	draw_rect(Rect2(size.x * 0.5 - 250, size.y - 110, 500, 100), Color(0.3, 0.2, 0.1, 0.85))
	for i in 3:
		var p := _tray_pos(i)
		if i == _food:
			draw_arc(p, 46.0, 0, TAU, 24, Color.html("ffd60a"), 5.0)
		_draw_food(i, p)
		text_c(p + Vector2(0, 44), str(i + 1), 18, Color.WHITE)
	_Art.draw_sister(self, Game.character_id, Vector2(130, size.y - 15), 0.8)
	_Art.draw_animal(self, Game.animal_id, Vector2(size.x - 100, size.y - 20), 0.6, -1.0)
	text(Vector2(24, 40), "Time %d    Points %d" % [maxi(0, ceili(_time_left)), _score], 30, Color.html("1d3557"))
	text(Vector2(24, 72), "1 2 3 = pick food  -  click a goat to feed it", 20, Color.html("1d3557"))
	if _flash_t > 0.0:
		text_c(Vector2(size.x * 0.5, 120), _flash, 38, Color.html("1d3557"))
	draw_pointer()
