extends MiniGameBase

const _Art := preload("res://scripts/ui/avatar_art.gd")
## Kitchen Rush (Overcooked-style): family orders sandwiches! Walk with WASD, use E / Space.
## Grab ingredients from the crates, chop the tomato, fry the egg, build the plate - the order
## is served automatically when your plate matches. Don't burn the egg!

const GAME_TIME := 70.0
const PLAYER_R := 15.0
const RECIPES := {
	"Cheese sandwich": ["bread", "cheese"],
	"Tomato sandwich": ["bread", "tomato_sliced"],
	"Egg sandwich": ["bread", "egg_fried"],
}
const NAMES := {"bread": "Bread", "cheese": "Cheese", "tomato": "Tomato", "egg": "Egg",
		"tomato_sliced": "Sliced tomato", "egg_fried": "Fried egg", "egg_burnt": "Burnt egg"}

var _room: Rect2
var _stations: Array = []     # {"id": String, "rect": Rect2, "kind": String, "item": String, "t": float}
var _p: Vector2 = Vector2.ZERO
var _held: String = ""
var _plate: Array = []
var _orders: Array = []       # {"name": String, "left": float}
var _order_timer: float = 0.0
var _time_left: float = 0.0
var _served: int = 0
var _msg: String = ""
var _msg_t: float = 0.0
var _walk_t: float = 0.0
var _face: float = 1.0


func _ready() -> void:
	bg_color = Color.html("2b2d42")
	super()


func _on_start() -> void:
	_time_left = GAME_TIME + float(Game.mod("extra_time", 0.0))
	_room = Rect2(40, 150, size.x - 80, size.y - 190)
	_stations.clear()
	var names := ["bread", "cheese", "tomato", "egg"]
	for i in 4:
		_stations.append({"id": names[i], "kind": "crate", "item": names[i], "t": 0.0,
				"rect": Rect2(_room.position.x + 40 + i * 150, _room.position.y, 120, 64)})
	_stations.append({"id": "board", "kind": "board", "item": "", "t": 0.0, "rect": Rect2(_room.end.x - 150, _room.position.y + 110, 120, 80)})
	_stations.append({"id": "stove", "kind": "stove", "item": "", "t": 0.0, "rect": Rect2(_room.end.x - 150, _room.position.y + 230, 120, 80)})
	_stations.append({"id": "plate", "kind": "plate", "item": "", "t": 0.0, "rect": Rect2(size.x * 0.5 - 100, _room.end.y - 90, 200, 70)})
	_stations.append({"id": "trash", "kind": "trash", "item": "", "t": 0.0, "rect": Rect2(_room.position.x + 20, _room.end.y - 90, 90, 70)})
	_p = Vector2(size.x * 0.5, _room.get_center().y)
	_held = ""
	_plate.clear()
	_orders.clear()
	_served = 0
	_order_timer = 0.0


func _tick(delta: float) -> void:
	_time_left -= delta
	_msg_t = maxf(0.0, _msg_t - delta)
	var v := Input.get_vector("steer_left", "steer_right", "accelerate", "brake")
	if v.length() > 0.05:
		_walk_t += delta * 10.0
		if absf(v.x) > 0.1:
			_face = signf(v.x)
	var step := v * 240.0 * delta
	if _can_stand(_p + Vector2(step.x, 0.0)):
		_p.x += step.x
	if _can_stand(_p + Vector2(0.0, step.y)):
		_p.y += step.y
	for st: Dictionary in _stations:     # cooking
		if st["kind"] == "board" and st["item"] == "tomato":
			st["t"] += delta
			if st["t"] >= 1.6:
				st["item"] = "tomato_sliced"
		elif st["kind"] == "stove" and (st["item"] == "egg" or st["item"] == "egg_fried"):
			st["t"] += delta
			if st["item"] == "egg" and st["t"] >= 3.0:
				st["item"] = "egg_fried"
			elif st["item"] == "egg_fried" and st["t"] >= 7.5:
				st["item"] = "egg_burnt"
				_say("The egg burnt!")
	_order_timer -= delta
	if _order_timer <= 0.0 and _orders.size() < 3:
		_order_timer = 9.0
		var keys := RECIPES.keys()
		_orders.append({"name": keys[randi() % keys.size()], "left": 34.0})
	for o: Dictionary in _orders:
		o["left"] -= delta
	_orders = _orders.filter(func(o: Dictionary) -> bool: return o["left"] > 0.0)
	if _time_left <= 0.0:
		complete(maxi(1, stars_from(_served, 3, 6, 9)))


func _can_stand(c: Vector2) -> bool:
	if not _room.grow(-PLAYER_R).has_point(c):
		return false
	for st: Dictionary in _stations:
		if circle_hits_rect(c, PLAYER_R, st["rect"]):
			return false
	return true


func _near_station() -> Dictionary:
	var best: Dictionary = {}
	var best_d := 52.0
	for st: Dictionary in _stations:
		var r: Rect2 = st["rect"]
		var nearest := Vector2(clampf(_p.x, r.position.x, r.end.x), clampf(_p.y, r.position.y, r.end.y))
		var d := nearest.distance_to(_p)
		if d < best_d:
			best_d = d
			best = st
	return best


func _say(t: String) -> void:
	_msg = t
	_msg_t = 1.6


func _on_input(event: InputEvent) -> void:
	if not is_use(event):
		return
	var st := _near_station()
	if st.is_empty():
		return
	match st["kind"]:
		"crate":
			if _held == "":
				_held = st["item"]
		"board":
			if _held == "tomato" and st["item"] == "":
				st["item"] = "tomato"
				st["t"] = 0.0
				_held = ""
			elif _held == "" and st["item"] == "tomato_sliced":
				_held = "tomato_sliced"
				st["item"] = ""
		"stove":
			if _held == "egg" and st["item"] == "":
				st["item"] = "egg"
				st["t"] = 0.0
				_held = ""
			elif _held == "" and st["item"] != "":
				_held = st["item"]
				st["item"] = ""
		"trash":
			if _held != "":
				_held = ""
			elif not _plate.is_empty():
				_plate.clear()
				_say("Plate cleared")
		"plate":
			if _held != "" and _plate.size() < 2:
				_plate.append(_held)
				_held = ""
				_try_serve()
			elif _held == "" and not _plate.is_empty():
				_held = _plate.pop_back()


func _try_serve() -> void:
	var mine := _plate.duplicate()
	mine.sort()
	for i in _orders.size():
		var want: Array = (RECIPES[_orders[i]["name"]] as Array).duplicate()
		want.sort()
		if want == mine:
			_orders.remove_at(i)
			_plate.clear()
			_served += 1
			_say("Served! +1")
			return


func _draw_item(id: String, pos: Vector2, s: float = 1.0) -> void:
	match id:
		"bread":
			draw_rect(Rect2(pos - Vector2(18, 12) * s, Vector2(36, 24) * s), Color.html("d9a066"))
			draw_rect(Rect2(pos - Vector2(18, 12) * s, Vector2(36, 8) * s), Color.html("f0c58f"))
		"cheese":
			draw_colored_polygon(PackedVector2Array([pos + Vector2(-16, 10) * s, pos + Vector2(16, 10) * s, pos + Vector2(10, -12) * s]), Color.html("ffd23f"))
		"tomato":
			draw_circle(pos, 14.0 * s, Color.html("e63946"))
			draw_circle(pos + Vector2(0, -12) * s, 4.0 * s, Color.html("2d6a4f"))
		"egg":
			draw_circle(pos, 13.0 * s, Color.html("f8f4e3"))
		"tomato_sliced":
			draw_circle(pos, 15.0 * s, Color.html("e63946"))
			draw_circle(pos, 8.0 * s, Color.html("ff8a8a"))
		"egg_fried":
			draw_circle(pos, 16.0 * s, Color.html("ffffff"))
			draw_circle(pos, 7.0 * s, Color.html("ffb703"))
		"egg_burnt":
			draw_circle(pos, 16.0 * s, Color.html("3a3a3a"))


func _draw_game() -> void:
	if not running:
		return
	draw_rect(_room, Color.html("e9ecef"))
	for i in range(0, int(_room.size.x), 60):
		draw_line(Vector2(_room.position.x + i, _room.position.y), Vector2(_room.position.x + i, _room.end.y), Color(0, 0, 0, 0.05), 2.0)
	for st: Dictionary in _stations:
		var r: Rect2 = st["rect"]
		match st["kind"]:
			"crate":
				draw_rect(r, Color.html("a98467"))
				draw_rect(r, Color.html("6c584c"), false, 3.0)
				_draw_item(st["item"], r.get_center() + Vector2(0, -4), 1.3)
				text_c(Vector2(r.get_center().x, r.end.y - 6), NAMES[st["item"]], 16, Color.WHITE)
			"board":
				draw_rect(r, Color.html("c9a66b"))
				draw_rect(r, Color.html("8d6e3f"), false, 3.0)
				text_c(Vector2(r.get_center().x, r.position.y + 16), "CHOP", 14, Color.html("5c4a28"))
				if st["item"] != "":
					_draw_item(st["item"], r.get_center() + Vector2(0, 6), 1.4)
				if st["item"] == "tomato":
					draw_rect(Rect2(r.position.x + 8, r.end.y - 10, (r.size.x - 16) * clampf(float(st["t"]) / 1.6, 0.0, 1.0), 6), Color.html("70e000"))
			"stove":
				draw_rect(r, Color.html("495057"))
				draw_circle(r.get_center(), 28.0, Color.html("212529"))
				text_c(Vector2(r.get_center().x, r.position.y + 14), "FRY", 14, Color.WHITE)
				if st["item"] != "":
					_draw_item(st["item"], r.get_center(), 1.5)
					var burn := clampf((float(st["t"]) - 3.0) / 4.5, 0.0, 1.0)
					if st["item"] == "egg":
						draw_rect(Rect2(r.position.x + 8, r.end.y - 10, (r.size.x - 16) * clampf(float(st["t"]) / 3.0, 0.0, 1.0), 6), Color.html("ffd166"))
					elif st["item"] == "egg_fried":
						draw_rect(Rect2(r.position.x + 8, r.end.y - 10, (r.size.x - 16) * (1.0 - burn), 6), Color.html("ef476f"))
			"plate":
				draw_rect(r, Color.html("dee2e6"))
				draw_rect(r, Color.html("868e96"), false, 3.0)
				draw_circle(r.get_center(), 30.0, Color.WHITE)
				for i in _plate.size():
					_draw_item(_plate[i], r.get_center() + Vector2(-16 + i * 32, 0), 1.0)
				text_c(Vector2(r.get_center().x, r.end.y - 4), "PLATE", 14, Color.html("495057"))
			"trash":
				draw_rect(r, Color.html("6c757d"))
				text_c(r.get_center() + Vector2(0, 6), "TRASH", 18, Color.WHITE)
	var bob := absf(sin(_walk_t)) * 4.0
	_Art.draw_sister(self, Game.character_id, _p + Vector2(0, 26), 0.42, _face, bob, sin(_walk_t * 0.5) * 0.05)
	if _held != "":
		_draw_item(_held, _p + Vector2(_face * 28.0, -58.0), 1.2)
	# hud: orders
	text(Vector2(24, 40), "Time %d    Served %d" % [maxi(0, ceili(_time_left)), _served], 28, Color.WHITE)
	text(Vector2(24, 70), "WASD walk  -  E / Space use  -  hands: %s" % (NAMES[_held] if _held != "" else "empty"), 18, Color(1, 1, 1, 0.8))
	for i in _orders.size():
		var o: Dictionary = _orders[i]
		var box := Rect2(24 + i * 250, 84, 236, 56)
		draw_rect(box, Color.html("fff3b0"))
		draw_rect(Rect2(box.position.x, box.end.y - 6, box.size.x * clampf(float(o["left"]) / 34.0, 0.0, 1.0), 6), Color.html("ef476f") if o["left"] < 10.0 else Color.html("70e000"))
		text(box.position + Vector2(8, 22), o["name"], 18, Color.html("3d2c00"))
		var ing: Array = RECIPES[o["name"]]
		for k in ing.size():
			_draw_item(ing[k], box.position + Vector2(150 + k * 38, 30), 0.8)
	if _msg_t > 0.0:
		text_c(Vector2(size.x * 0.5, _room.end.y - 120), _msg, 30, Color.html("ffd166"))
