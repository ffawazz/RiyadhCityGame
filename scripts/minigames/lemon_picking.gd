extends MiniGameBase

const _Art := preload("res://scripts/ui/avatar_art.gd")
## Lemon grove: pick the ripe yellow lemons, golden ones are worth 3, green ones are not ready (-1).
## Hedgehog / cat "grab" perks add a few seconds.

const BASE_TIME := 30.0
const SLOTS := 18

var _time_left: float = 0.0
var _score: int = 0
var _lemons: Array = []     # {pos, kind, regrow, shake, fly(-1 or progress), from}
var _flash: String = ""
var _flash_t: float = 0.0
var _t: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	bg_color = Color.html("a9def9")
	super()


func _on_start() -> void:
	_rng.randomize()
	_time_left = BASE_TIME * float(Game.mod("grab", 1.0))
	_score = 0
	_lemons.clear()
	for i in SLOTS:
		var a := TAU * float(i) / SLOTS * 2.3 + float(i) * 0.5
		var r := 60.0 + fmod(float(i) * 53.0, 190.0)
		_lemons.append({"pos": Vector2(640.0 + cos(a) * r * 1.25, 250.0 + sin(a) * r * 0.78), "kind": _roll(), "regrow": 0.0, "shake": 0.0, "fly": -1.0, "from": Vector2.ZERO})


func _roll() -> String:
	var r := _rng.randf()
	if r < 0.1:
		return "golden"
	if r < 0.32:
		return "green"
	return "ripe"


func _tick(delta: float) -> void:
	_t += delta
	_time_left -= delta
	_flash_t = maxf(0.0, _flash_t - delta)
	pointer_move(delta)
	for l: Dictionary in _lemons:
		l["shake"] = maxf(0.0, float(l["shake"]) - delta * 3.0)
		if float(l["fly"]) >= 0.0:
			l["fly"] = float(l["fly"]) + delta * 2.2
			if float(l["fly"]) >= 1.0:
				l["fly"] = -1.0
				l["regrow"] = 2.0
		elif float(l["regrow"]) > 0.0:
			l["regrow"] = float(l["regrow"]) - delta
			if float(l["regrow"]) <= 0.0:
				l["kind"] = _roll()
	if _time_left <= 0.0 and running:
		complete(maxi(1, stars_from(_score, 8, 14, 20)))


func _on_input(event: InputEvent) -> void:
	pointer_event(event)
	if not is_confirm(event):
		return
	var best := -1
	var best_d := 44.0
	for i in _lemons.size():
		var l: Dictionary = _lemons[i]
		if float(l["fly"]) >= 0.0 or float(l["regrow"]) > 0.0:
			continue
		var d := pointer.distance_to(l["pos"])
		if d < best_d:
			best_d = d
			best = i
	if best < 0:
		return
	var l: Dictionary = _lemons[best]
	match l["kind"]:
		"golden":
			_score += 3
			_say("Golden lemon! +3")
		"ripe":
			_score += 1
			_say("Yum! +1")
		_:
			_score = maxi(0, _score - 1)
			l["shake"] = 1.0
			_say("Not ripe yet! -1")
			return
	l["fly"] = 0.0
	l["from"] = l["pos"]


func _say(s: String) -> void:
	_flash = s
	_flash_t = 0.8


func _basket() -> Vector2:
	return Vector2(size.x * 0.5, size.y - 70.0)


func _draw_lemon(p: Vector2, kind: String, sc: float = 1.0) -> void:
	var col := {"ripe": Color.html("ffe14d"), "golden": Color.html("ffc300"), "green": Color.html("8ac926")}[kind] as Color
	draw_set_transform(p, 0.0, Vector2(1.25 * sc, sc))
	draw_circle(Vector2.ZERO, 22.0, col.darkened(0.2))
	draw_circle(Vector2(-2, -2), 19.0, col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(p + Vector2(26 * sc, 0), 5.0 * sc, col.darkened(0.2))
	draw_circle(p + Vector2(-26 * sc, 0), 5.0 * sc, col.darkened(0.2))
	if kind == "golden":
		draw_circle(p + Vector2(-8, -8), 4.0, Color(1, 1, 1, 0.85))
		draw_circle(p + Vector2(9 + sin(_t * 6.0) * 2.0, 6), 3.0, Color(1, 1, 1, 0.7))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_game() -> void:
	if not running:
		return
	draw_rect(Rect2(0, size.y - 140, size.x, 140), Color.html("90be6d"))
	draw_rect(Rect2(610, 330, 60, size.y - 440), Color.html("7f5539"))                 # trunk
	for c: Array in [[640.0, 240.0, 330.0, "2d6a4f"], [500.0, 290.0, 210.0, "40916c"], [790.0, 290.0, 210.0, "40916c"], [640.0, 170.0, 220.0, "52b788"]]:
		draw_set_transform(Vector2(c[0], c[1]), 0.0, Vector2(1.25, 0.8))
		draw_circle(Vector2.ZERO, c[2] * 0.62, Color.html(c[3]))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for l: Dictionary in _lemons:
		if float(l["regrow"]) > 0.0:
			continue
		var p: Vector2 = l["pos"]
		if float(l["fly"]) >= 0.0:
			var f := float(l["fly"])
			p = (l["from"] as Vector2).lerp(_basket(), f) + Vector2(0, -sin(f * PI) * 80.0)
		else:
			p += Vector2(sin(_t * 40.0) * 5.0 * float(l["shake"]), 0)
		_draw_lemon(p, l["kind"])
	# basket + helpers
	draw_rect(Rect2(_basket() + Vector2(-60, -10), Vector2(120, 55)), Color.html("a47148"))
	draw_rect(Rect2(_basket() + Vector2(-60, -10), Vector2(120, 12)), Color.html("c38e5b"))
	_Art.draw_sister(self, Game.character_id, Vector2(150, size.y - 20), 0.9)
	_Art.draw_animal(self, Game.animal_id, Vector2(size.x - 130, size.y - 22), 0.8, -1.0)
	text(Vector2(24, 40), "Time %d    Lemons %d" % [maxi(0, ceili(_time_left)), _score], 30, Color.html("1d3557"))
	if _flash_t > 0.0:
		text_c(Vector2(size.x * 0.5, 100), _flash, 38, Color.html("1d3557"))
	draw_pointer(Color.html("ffffff"))
