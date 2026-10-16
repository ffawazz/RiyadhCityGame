extends MiniGameBase

const _Art := preload("res://scripts/ui/avatar_art.gd")
## Sand digging: five treasures are buried in the sandpit. Dig with the shovel; the colour of the
## sand shows how close the nearest treasure is (red = hot, blue = cold). Crabs pinch: -3 seconds.
## The hedgehog "dig" perk widens the warm area.

const COLS := 10
const ROWS := 6
const CELL := 88.0
const ORIGIN := Vector2(200.0, 130.0)
const GAME_TIME := 45.0
const TREASURES := ["Shell", "Gold coin", "Dino bone", "Toy car", "Crown"]

var _time_left: float = 0.0
var _found: int = 0
var _cells: Dictionary = {}     # Vector2i -> {"dug": bool, "item": "", "kind": "empty|treasure|crab"}
var _flash: String = ""
var _flash_t: float = 0.0
var _t: float = 0.0
var _digs: int = 0
var _pinch_t: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	bg_color = Color.html("8ecae6")
	super()


func _on_start() -> void:
	_rng.randomize()
	_time_left = GAME_TIME
	_found = 0
	_digs = 0
	_cells.clear()
	for x in COLS:
		for y in ROWS:
			_cells[Vector2i(x, y)] = {"dug": false, "item": "", "kind": "empty"}
	var placed := 0
	while placed < 5:
		var c := Vector2i(_rng.randi() % COLS, _rng.randi() % ROWS)
		if _cells[c]["kind"] == "empty":
			_cells[c]["kind"] = "treasure"
			_cells[c]["item"] = TREASURES[placed]
			placed += 1
	placed = 0
	while placed < 4:
		var c := Vector2i(_rng.randi() % COLS, _rng.randi() % ROWS)
		if _cells[c]["kind"] == "empty":
			_cells[c]["kind"] = "crab"
			placed += 1


func _cell_at(p: Vector2) -> Vector2i:
	var q := (p - ORIGIN) / CELL
	return Vector2i(floori(q.x), floori(q.y))


func _nearest_treasure(c: Vector2i) -> int:
	var best := 99
	for k: Vector2i in _cells:
		var d: Dictionary = _cells[k]
		if d["kind"] == "treasure" and not d["dug"]:
			best = mini(best, absi(k.x - c.x) + absi(k.y - c.y))
	return best


func _tick(delta: float) -> void:
	_t += delta
	_time_left -= delta
	_flash_t = maxf(0.0, _flash_t - delta)
	_pinch_t = maxf(0.0, _pinch_t - delta)
	pointer_move(delta)
	if (_time_left <= 0.0 or _found >= 5) and running:
		var stars := 1
		if _found >= 5 and _time_left > 12.0:
			stars = 3
		elif _found >= 5 or (_found >= 4):
			stars = 2
		complete(stars)


func _on_input(event: InputEvent) -> void:
	pointer_event(event)
	if not is_confirm(event):
		return
	var c := _cell_at(pointer)
	if not _cells.has(c) or _cells[c]["dug"]:
		return
	var d: Dictionary = _cells[c]
	d["dug"] = true
	_digs += 1
	match d["kind"]:
		"treasure":
			_found += 1
			_flash = "You found a %s!" % d["item"]
		"crab":
			_time_left -= 3.0
			_pinch_t = 0.8
			_flash = "Ouch! A crab pinched you  -3s"
		_:
			_flash = "Just sand..."
	_flash_t = 1.0


func _heat(c: Vector2i) -> Color:
	var d := _nearest_treasure(c)
	var reach := float(Game.mod("dig", 1.0))
	var f := float(d) / reach
	if f < 0.5:
		return Color(1.0, 0.05, 0.05, 0.8)        # right here!
	if f <= 1.0:
		return Color(1.0, 0.45, 0.1, 0.65)
	if f <= 2.0:
		return Color(1.0, 0.85, 0.2, 0.5)
	if f <= 3.5:
		return Color(0.6, 0.85, 1.0, 0.45)
	return Color(0.2, 0.4, 1.0, 0.55)


func _draw_game() -> void:
	if not running:
		return
	draw_rect(Rect2(ORIGIN - Vector2(14, 14), Vector2(COLS * CELL + 28, ROWS * CELL + 28)), Color.html("8b5e34"))
	for k: Vector2i in _cells:
		var d: Dictionary = _cells[k]
		var r := Rect2(ORIGIN + Vector2(k) * CELL, Vector2(CELL, CELL))
		if d["dug"]:
			draw_rect(r.grow(-2), Color.html("b08968"))
			draw_circle(r.get_center(), 28.0, Color.html("8b6b4a"))
			var c := r.get_center()
			match d["kind"]:
				"treasure":
					_draw_treasure(str(d["item"]), c)
				"crab":
					draw_circle(c, 18.0, Color.html("e63946"))
					draw_circle(c + Vector2(-22, -8), 8.0, Color.html("e63946"))
					draw_circle(c + Vector2(22, -8), 8.0, Color.html("e63946"))
					draw_circle(c + Vector2(-6, -16), 3.0, Color.WHITE)
					draw_circle(c + Vector2(6, -16), 3.0, Color.WHITE)
		else:
			draw_rect(r.grow(-2), Color.html("e9c46a"))
			if k == _cell_at(pointer):
				draw_rect(r.grow(-2), _heat(k))
	# collected list
	text(Vector2(24, 40), "Time %d    Treasures %d / 5" % [maxi(0, ceili(_time_left)), _found], 30, Color.html("023e8a"))
	text(Vector2(24, 72), "hover a square: RED = dig here!  orange = very close  yellow = near  blue = cold", 20, Color.html("023e8a"))
	if _flash_t > 0.0:
		text_c(Vector2(size.x * 0.5, 110), _flash, 34, Color.html("3d2c00"))
	_Art.draw_sister(self, Game.character_id, Vector2(100, size.y - 14), 0.75)
	_Art.draw_animal(self, Game.animal_id, Vector2(size.x - 90, size.y - 16), 0.65, -1.0, absf(sin(_t * 9.0)) * 10.0 if _pinch_t > 0.0 else 0.0)
	# shovel as the pointer
	var hover := _cell_at(pointer)
	if _cells.has(hover):
		draw_rect(Rect2(ORIGIN + Vector2(hover) * CELL, Vector2(CELL, CELL)), Color(1, 1, 1, 0.9), false, 3.0)
	draw_line(pointer + Vector2(30, -50), pointer + Vector2(4, -6), Color.html("6f4518"), 7.0)
	draw_colored_polygon(PackedVector2Array([pointer + Vector2(-12, -4), pointer + Vector2(14, -8), pointer + Vector2(8, 16), pointer + Vector2(-8, 16)]), Color.html("adb5bd"))


func _draw_treasure(item: String, c: Vector2) -> void:
	match item:
		"Shell":
			draw_circle(c, 20.0, Color.html("ffb4a2"))
			for i in 4:
				draw_line(c + Vector2(0, 18), c + Vector2(-16 + i * 11, -14), Color.html("e5989b"), 3.0)
		"Gold coin":
			draw_circle(c, 20.0, Color.html("ffc300"))
			draw_circle(c, 13.0, Color.html("ffd60a"))
			text_c(c + Vector2(0, 8), "$", 20, Color.html("a47e00"))
		"Dino bone":
			draw_line(c + Vector2(-20, 0), c + Vector2(20, 0), Color.html("f8f9fa"), 9.0)
			for p: Vector2 in [Vector2(-22, -6), Vector2(-22, 6), Vector2(22, -6), Vector2(22, 6)]:
				draw_circle(c + p, 7.0, Color.html("f8f9fa"))
		"Toy car":
			draw_rect(Rect2(c + Vector2(-22, -8), Vector2(44, 16)), Color.html("3a86ff"))
			draw_rect(Rect2(c + Vector2(-12, -18), Vector2(22, 12)), Color.html("a2d2ff"))
			draw_circle(c + Vector2(-13, 10), 6.0, Color.BLACK)
			draw_circle(c + Vector2(13, 10), 6.0, Color.BLACK)
		_:
			draw_colored_polygon(PackedVector2Array([c + Vector2(-22, 14), c + Vector2(-22, -10), c + Vector2(-10, 0), c + Vector2(0, -16), c + Vector2(10, 0), c + Vector2(22, -10), c + Vector2(22, 14)]), Color.html("ffc300"))
