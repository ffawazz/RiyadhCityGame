extends MiniGameBase
## Living Room Dash: run around the messy room, grab toys (carry up to 3) and dump them in
## the toy box before Mama gets home. Beware the robot vacuum (stuns you and drops your toys)
## and the cheeky cat (steals a toy and knocks new ones off the shelf).
## Perks: Sarah = longer reach, Lamia = animal friend (the cat never steals from her).

const GAME_TIME := 50.0
const PLAYER_R := 16.0
const CARRY_MAX := 3
const TOY_COLORS := ["ef476f", "ffd166", "06d6a0", "118ab2", "9b5de5", "f78c6b"]

var _room: Rect2
var _box: Rect2
var _blocks: Array = []        # furniture rectangles
var _toys: Array = []          # {"pos": Vector2, "kind": int, "color": Color}
var _carry: Array = []         # carried toys (same dictionaries)
var _p: Vector2 = Vector2.ZERO
var _face: float = 1.0
var _walk_t: float = 0.0
var _stored: int = 0
var _time_left: float = 0.0
var _stun: float = 0.0
var _cat_pos: Vector2 = Vector2.ZERO
var _cat_target: Vector2 = Vector2.ZERO
var _cat_timer: float = 0.0
var _cat_cool: float = 0.0
var _vac_pos: Vector2 = Vector2.ZERO
var _vac_dir: Vector2 = Vector2.RIGHT
var _knock_timer: float = 4.0
var _sparks: Array = []        # {"pos", "vel", "life", "color"}
var _msg: String = ""
var _msg_t: float = 0.0


func _ready() -> void:
	bg_color = Color.html("3b2f2f")
	super()


func _on_start() -> void:
	_time_left = GAME_TIME + float(Game.mod("extra_time", 0.0))
	_room = Rect2(40, 84, size.x - 80, size.y - 120)
	_box = Rect2(_room.end.x - 170, _room.end.y - 96, 130, 76)
	_blocks = [
		Rect2(_room.position.x + 30, _room.position.y + 16, 280, 92),                 # sofa
		Rect2(size.x * 0.5 - 90, size.y * 0.5 - 30, 180, 80),                         # coffee table
		Rect2(_room.end.x - 300, _room.position.y + 8, 240, 54),                      # TV unit
		Rect2(_room.position.x + 4, _room.position.y + 250, 44, 180),                # bookshelf
		Rect2(_room.end.x - 80, _room.end.y - 250, 46, 46)]                           # plant
	_p = Vector2(size.x * 0.5, _room.end.y - 60)
	_toys.clear()
	_carry.clear()
	_stored = 0
	_stun = 0.0
	for i in 12:
		_spawn_toy(_free_spot())
	_cat_pos = Vector2(_room.position.x + 120, _room.end.y - 120)
	_cat_target = _cat_pos
	_vac_pos = Vector2(_room.position.x + 200, _room.position.y + 330)
	_vac_dir = Vector2(1, 0.6).normalized()


func _free_spot() -> Vector2:
	for i in 40:
		var c := Vector2(randf_range(_room.position.x + 40, _room.end.x - 40), randf_range(_room.position.y + 40, _room.end.y - 40))
		var ok := not _box.grow(50).has_point(c)
		for b: Rect2 in _blocks:
			if b.grow(26).has_point(c):
				ok = false
		if ok:
			return c
	return _room.get_center() + Vector2(0, 150)


func _spawn_toy(pos: Vector2) -> void:
	_toys.append({"pos": pos, "kind": randi() % 4, "color": Color.html(TOY_COLORS[randi() % TOY_COLORS.size()])})


func _say(t: String) -> void:
	_msg = t
	_msg_t = 1.4


func _sparkle(pos: Vector2, color: Color, n: int = 8) -> void:
	for i in n:
		_sparks.append({"pos": pos, "vel": Vector2.from_angle(randf() * TAU) * randf_range(60, 190), "life": 0.5, "color": color})


func _tick(delta: float) -> void:
	_time_left -= delta
	_msg_t = maxf(0.0, _msg_t - delta)
	_stun = maxf(0.0, _stun - delta)
	_cat_cool = maxf(0.0, _cat_cool - delta)
	_move_player(delta)
	_update_cat(delta)
	_update_vacuum(delta)
	_pickups_and_drops()
	for sp in _sparks:
		sp["pos"] += sp["vel"] * delta
		sp["life"] -= delta
	_sparks = _sparks.filter(func(sp: Dictionary) -> bool: return sp["life"] > 0.0)
	if _time_left <= 0.0:
		complete(maxi(1, stars_from(_stored, 6, 12, 18)))


func _move_player(delta: float) -> void:
	if _stun > 0.0:
		return
	var v := Input.get_vector("steer_left", "steer_right", "accelerate", "brake")
	if v.length() > 0.05:
		_walk_t += delta * 10.0
		if absf(v.x) > 0.1:
			_face = signf(v.x)
	var step := v * 250.0 * (1.0 - 0.06 * _carry.size()) * delta
	var nx := _p + Vector2(step.x, 0.0)
	if _free(nx):
		_p = nx
	var ny := _p + Vector2(0.0, step.y)
	if _free(ny):
		_p = ny


func _free(c: Vector2) -> bool:
	if not _room.grow(-PLAYER_R).has_point(c):
		return false
	for b: Rect2 in _blocks:
		if circle_hits_rect(c, PLAYER_R, b):
			return false
	return true


func _update_cat(delta: float) -> void:
	_cat_timer -= delta
	if _cat_timer <= 0.0:
		_cat_timer = randf_range(1.0, 2.2)
		_cat_target = _free_spot() if randf() < 0.7 else _p
	var to := _cat_target - _cat_pos
	if to.length() > 6.0:
		var np := _cat_pos + to.normalized() * 120.0 * delta
		if _room.grow(-18).has_point(np):
			_cat_pos = np
	_knock_timer -= delta
	if _knock_timer <= 0.0:
		_knock_timer = randf_range(3.5, 5.5)
		_spawn_toy(_cat_pos + Vector2(0, 26))
		_say("The cat knocked a toy off!")
	# the cat steals from you - unless you are the animal-friend sister
	var friendly := float(Game.mod("animal_bonus", 1.0)) > 1.0
	if not friendly and _cat_cool <= 0.0 and not _carry.is_empty() and _cat_pos.distance_to(_p) < 42.0:
		var stolen: Dictionary = _carry.pop_back()
		stolen["pos"] = _cat_pos + Vector2(randf_range(-60, 60), 60)
		_toys.append(stolen)
		_cat_cool = 3.0
		_say("The cat stole a toy!")
		_sparkle(_cat_pos, Color.html("ffd166"))


func _update_vacuum(delta: float) -> void:
	var np := _vac_pos + _vac_dir * 130.0 * delta
	var hit := not _room.grow(-30).has_point(np)
	for b: Rect2 in _blocks:
		if circle_hits_rect(np, 28.0, b):
			hit = true
	if hit:
		_vac_dir = Vector2.from_angle(randf() * TAU)
	else:
		_vac_pos = np
	for i in range(_toys.size() - 1, -1, -1):          # it gobbles toys it rolls over
		if (_toys[i]["pos"] as Vector2).distance_to(_vac_pos) < 26.0:
			_sparkle(_toys[i]["pos"], Color.html("adb5bd"), 4)
			_toys.remove_at(i)
			_say("The vacuum ate a toy!")
	if _stun <= 0.0 and _vac_pos.distance_to(_p) < 40.0:
		_stun = 1.0
		for toy in _carry:
			toy["pos"] = _p + Vector2.from_angle(randf() * TAU) * randf_range(30, 80)
			_toys.append(toy)
		_carry.clear()
		_p += (_p - _vac_pos).normalized() * 40.0
		_say("Bumped by the vacuum!")
		_sparkle(_p, Color.html("ef476f"), 10)


func _pickups_and_drops() -> void:
	if _stun > 0.0:
		return
	var reach := (PLAYER_R + 16.0) * float(Game.mod("reach", 1.0))
	for i in range(_toys.size() - 1, -1, -1):
		if _carry.size() >= CARRY_MAX:
			break
		if (_toys[i]["pos"] as Vector2).distance_to(_p) < reach:
			_carry.append(_toys[i])
			_sparkle(_toys[i]["pos"], _toys[i]["color"], 4)
			_toys.remove_at(i)
	if not _carry.is_empty() and _box.grow(34).has_point(_p):
		_stored += _carry.size()
		_say("+%d toys tidied!" % _carry.size())
		_sparkle(_box.get_center(), Color.html("ffd166"), 14)
		_carry.clear()


func _draw_toy(pos: Vector2, kind: int, color: Color, s: float = 1.0) -> void:
	match kind:
		0:
			draw_circle(pos, 12.0 * s, color)
			draw_arc(pos, 12.0 * s, 0.4, 2.4, 10, Color(1, 1, 1, 0.6), 2.0)
		1:
			draw_rect(Rect2(pos - Vector2(11, 11) * s, Vector2(22, 22) * s), color)
			draw_rect(Rect2(pos - Vector2(11, 11) * s, Vector2(22, 22) * s), Color(0, 0, 0, 0.3), false, 2.0)
		2:
			draw_rect(Rect2(pos - Vector2(15, 7) * s, Vector2(30, 12) * s), color)
			draw_circle(pos + Vector2(-8, 6) * s, 4.0 * s, Color.BLACK)
			draw_circle(pos + Vector2(8, 6) * s, 4.0 * s, Color.BLACK)
		_:
			var pts := PackedVector2Array()
			for k in 10:
				var a := -PI / 2.0 + k * TAU / 10.0
				pts.append(pos + Vector2.from_angle(a) * (13.0 if k % 2 == 0 else 6.0) * s)
			draw_colored_polygon(pts, color)


func _draw_game() -> void:
	if not running:
		return
	# floor, planks and rug
	draw_rect(_room, Color.html("b98a5e"))
	for i in range(0, int(_room.size.y), 36):
		draw_line(Vector2(_room.position.x, _room.position.y + i), Vector2(_room.end.x, _room.position.y + i), Color(0, 0, 0, 0.08), 2.0)
	var rug := Rect2(_room.get_center() - Vector2(260, 160), Vector2(520, 320))
	draw_rect(rug, Color.html("8d3b4a"))
	draw_rect(rug.grow(-14), Color.html("c9707e"), false, 6.0)
	# furniture
	draw_rect(_blocks[0], Color.html("3a6ea5"))                                    # sofa
	draw_rect(Rect2(_blocks[0].position, Vector2(_blocks[0].size.x, 26)), Color.html("2c5282"))
	for k in 3:
		draw_rect(Rect2(_blocks[0].position + Vector2(14 + k * 88, 34), Vector2(78, 46)), Color.html("5b8bc9"))
	draw_rect(_blocks[1], Color.html("6b4423"))                                    # table
	draw_rect(_blocks[1].grow(-8), Color.html("8b5a2b"))
	draw_rect(_blocks[2], Color.html("2d2d34"))                                    # TV
	draw_rect(_blocks[2].grow(-6), Color.html("5fb0e5"))
	draw_rect(_blocks[3], Color.html("6b4423"))                                    # bookshelf
	for k in 6:
		draw_rect(Rect2(_blocks[3].position + Vector2(6, 8 + k * 28), Vector2(32, 18)), Color.html(TOY_COLORS[k % TOY_COLORS.size()]))
	draw_circle(_blocks[4].get_center(), 26.0, Color.html("2d6a4f"))               # plant
	draw_rect(Rect2(_blocks[4].get_center() + Vector2(-12, 14), Vector2(24, 18)), Color.html("a0522d"))
	# toy box
	draw_rect(_box, Color.html("f4a261"))
	draw_rect(_box, Color.html("a86232"), false, 4.0)
	text_c(_box.get_center() + Vector2(0, 8), "TOY BOX", 20, Color.WHITE)
	# toys on the floor
	for t: Dictionary in _toys:
		_draw_toy(t["pos"], t["kind"], t["color"])
	# vacuum + cat
	draw_circle(_vac_pos, 28.0, Color.html("adb5bd"))
	draw_arc(_vac_pos, 28.0, 0, TAU, 24, Color.html("495057"), 4.0)
	draw_circle(_vac_pos + _vac_dir * 12.0, 6.0, Color.html("ef476f") if int(_time_left * 3.0) % 2 == 0 else Color.html("70e000"))
	draw_circle(_cat_pos, 15.0, Color.html("ff9f1c"))
	draw_circle(_cat_pos + Vector2(14, -8), 10.0, Color.html("ff9f1c"))
	draw_colored_polygon(PackedVector2Array([_cat_pos + Vector2(8, -15), _cat_pos + Vector2(12, -24), _cat_pos + Vector2(16, -14)]), Color.html("ff9f1c"))
	draw_colored_polygon(PackedVector2Array([_cat_pos + Vector2(17, -14), _cat_pos + Vector2(22, -22), _cat_pos + Vector2(24, -10)]), Color.html("ff9f1c"))
	draw_line(_cat_pos + Vector2(-14, 4), _cat_pos + Vector2(-30, -8 + sin(_time_left * 8.0) * 5.0), Color.html("ff9f1c"), 4.0)
	# the sister
	var bob := absf(sin(_walk_t)) * 4.0 if _stun <= 0.0 else 0.0
	AvatarArt.draw_sister(self, Game.character_id, _p + Vector2(0, 26), 0.42, _face, bob, sin(_walk_t * 0.5) * 0.05 + (0.3 if _stun > 0.0 else 0.0))
	for i in _carry.size():
		_draw_toy(_p + Vector2(-20 + i * 20, -104 - 4 * i), _carry[i]["kind"], _carry[i]["color"], 0.75)
	for sp: Dictionary in _sparks:
		draw_circle(sp["pos"], 3.0, sp["color"])
	text(Vector2(24, 40), "Time %d    Tidied %d    Carrying %d/%d" % [maxi(0, ceili(_time_left)), _stored, _carry.size(), CARRY_MAX], 28, Color.WHITE)
	text(Vector2(24, 70), "Walk over toys to grab them, drop them in the toy box. Dodge the vacuum!", 18, Color(1, 1, 1, 0.8))
	if _msg_t > 0.0:
		text_c(Vector2(size.x * 0.5, 130), _msg, 30, Color.html("ffd166"))
