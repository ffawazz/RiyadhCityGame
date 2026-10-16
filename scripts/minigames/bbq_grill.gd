extends MiniGameBase

const _Art := preload("res://scripts/ui/avatar_art.gd")
## Camping BBQ: kebabs cook on the grill. Click one while it is golden brown (green ring) for 2
## points; a bit early or late is 1; a burnt one costs a point. 40 seconds.

const GAME_TIME := 40.0
const COOK := 7.0

var _time_left: float = 0.0
var _score: int = 0
var _slots: Array = []      # {pos, age(-1 empty), kind, smoke}
var _spawn: float = 0.0
var _flash: String = ""
var _flash_t: float = 0.0
var _t: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	bg_color = Color.html("264653")
	super()


func _on_start() -> void:
	_rng.randomize()
	_time_left = GAME_TIME
	_score = 0
	_spawn = 0.4
	_slots.clear()
	for row in 2:
		for col in 4:
			_slots.append({"pos": Vector2(330.0 + col * 160.0, 250.0 + row * 140.0), "age": -1.0, "kind": 0, "smoke": 0.0})


func _tick(delta: float) -> void:
	_t += delta
	_time_left -= delta
	_flash_t = maxf(0.0, _flash_t - delta)
	pointer_move(delta)
	_spawn -= delta
	if _spawn <= 0.0:
		_spawn = _rng.randf_range(0.8, 1.5)
		var free: Array = _slots.filter(func(sl: Dictionary) -> bool: return float(sl["age"]) < 0.0)
		if not free.is_empty():
			var sl: Dictionary = free[_rng.randi() % free.size()]
			sl["age"] = 0.0
			sl["kind"] = _rng.randi() % 3
	for sl: Dictionary in _slots:
		sl["smoke"] = maxf(0.0, float(sl["smoke"]) - delta)
		if float(sl["age"]) >= 0.0:
			sl["age"] = float(sl["age"]) + delta
			if float(sl["age"]) > COOK + 3.0:       # a black cinder falls off the grill
				sl["age"] = -1.0
				_score = maxi(0, _score - 1)
				_say("Burnt to a crisp! -1")
	if _time_left <= 0.0 and running:
		complete(maxi(1, stars_from(_score, 10, 18, 26)))


func _say(s: String) -> void:
	_flash = s
	_flash_t = 0.9


func _on_input(event: InputEvent) -> void:
	pointer_event(event)
	if not is_confirm(event):
		return
	for sl: Dictionary in _slots:
		if float(sl["age"]) >= 0.0 and pointer.distance_to(sl["pos"]) < 56.0:
			var a := float(sl["age"])
			if a >= 4.2 and a <= 5.8:
				_score += 2
				_say("Perfect! +2")
			elif a >= 3.0 and a < 4.2 or a > 5.8 and a <= 7.0:
				_score += 1
				_say("Not bad! +1")
			elif a < 3.0:
				_score = maxi(0, _score - 1)
				_say("Still raw! -1")
			else:
				_score = maxi(0, _score - 1)
				_say("Too burnt! -1")
			sl["age"] = -1.0
			sl["smoke"] = 0.6
			return


func _meat_color(a: float, kind: int) -> Color:
	var raw := [Color.html("e5989b"), Color.html("ffb4a2"), Color.html("d68c6e")][kind] as Color
	var gold := Color.html("b5651d")
	var black := Color.html("2b2118")
	if a < 4.2:
		return raw.lerp(gold, clampf(a / 4.2, 0.0, 1.0))
	if a < 5.8:
		return gold
	return gold.lerp(black, clampf((a - 5.8) / 3.0, 0.0, 1.0))


func _draw_game() -> void:
	if not running:
		return
	# desert evening: tent behind, grill in front
	draw_rect(Rect2(0, 0, size.x, 180), Color.html("f4a261"))
	draw_colored_polygon(PackedVector2Array([Vector2(60, 220), Vector2(200, 60), Vector2(340, 220)]), Color.html("e63946"))
	draw_colored_polygon(PackedVector2Array([Vector2(900, 220), Vector2(1020, 90), Vector2(1140, 220)]), Color.html("2a9d8f"))
	draw_rect(Rect2(0, 220, size.x, size.y - 220), Color.html("3d2c1e"))
	# the grill
	draw_rect(Rect2(280, 200, 720, 340), Color.html("343a40"))
	draw_rect(Rect2(296, 214, 688, 312), Color.html("ff7b00") if int(_t * 6.0) % 2 == 0 else Color.html("ff9f1c"))
	for i in 12:
		draw_circle(Vector2(320 + i * 58.0, 250.0 + sin(_t * 4.0 + i) * 6.0), 12.0, Color(1, 0.3, 0.1, 0.6))
		draw_circle(Vector2(340 + i * 56.0, 400.0 + cos(_t * 3.0 + i) * 6.0), 12.0, Color(1, 0.3, 0.1, 0.6))
	for i in 9:
		draw_line(Vector2(296, 230 + i * 36.0), Vector2(984, 230 + i * 36.0), Color.html("495057"), 5.0)
	for sl: Dictionary in _slots:
		var p: Vector2 = sl["pos"]
		var a := float(sl["age"])
		if a >= 0.0:
			draw_rect(Rect2(p + Vector2(-48, -5), Vector2(96, 10)), Color.html("c9ada7"))        # the skewer
			for k in 3:
				draw_circle(p + Vector2(-26 + k * 26.0, 0), 20.0, _meat_color(a, int(sl["kind"])))
			# cooking ring
			var frac := clampf(a / (COOK + 3.0), 0.0, 1.0)
			var gold := a >= 4.2 and a <= 5.8
			draw_arc(p, 40.0, -PI / 2.0, -PI / 2.0 + TAU * frac, 24, Color.html("80b918") if gold else Color(1, 1, 1, 0.7), 5.0)
			if gold:
				draw_arc(p, 48.0, 0, TAU, 24, Color.html("80b918"), 3.0)
			if a > 5.8:
				for k in 3:
					draw_circle(p + Vector2(-14 + k * 14.0, -30 - fmod(_t * 40.0 + k * 20.0, 40.0)), 5.0, Color(0.3, 0.3, 0.3, 0.5))
		elif float(sl["smoke"]) > 0.0:
			draw_circle(p + Vector2(0, -20), 16.0 * float(sl["smoke"]) + 4.0, Color(1, 1, 1, 0.4))
	_Art.draw_sister(self, Game.character_id, Vector2(150, size.y - 10), 0.95)
	_Art.draw_animal(self, Game.animal_id, Vector2(size.x - 100, size.y - 14), 0.7, -1.0)
	text(Vector2(24, 40), "Time %d    Points %d" % [maxi(0, ceili(_time_left)), _score], 30, Color.WHITE)
	text(Vector2(24, 72), "click a kebab when its ring turns GREEN (golden brown)", 20, Color.WHITE)
	if _flash_t > 0.0:
		text_c(Vector2(size.x * 0.5, 130), _flash, 38, Color.WHITE)
	draw_pointer()
