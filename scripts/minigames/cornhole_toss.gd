extends MiniGameBase

const _Art := preload("res://scripts/ui/avatar_art.gd")
## Cornhole match vs Dad, 4 bags each, taking turns, in perspective. SPACE locks the aim, SPACE
## again locks the throw power (the green band is the board). Hole = 3, board = 1. Bags stay on
## the board, and a bag that lands near the hole may slide in. Beat Dad for 2 stars, win by 3+ for 3.
## Hassan the goat's strong legs widen the hole a little.

const BAGS := 4
const CX := 640.0
const BOARD_TOP := 120.0
const BOARD_BOT := 300.0
const HOLE := Vector2(640.0, 168.0)

var _round: int = 0
var _turn: String = "me"        # me | dad
var _phase: String = "aim"      # aim | power | fly | result
var _t: float = 0.0
var _aim: float = 0.0
var _power: float = 0.0
var _from: Vector2 = Vector2.ZERO
var _land: Vector2 = Vector2.ZERO
var _fly: float = 0.0
var _slide: float = 0.0
var _slide_to_hole: bool = false
var _gain: int = 0
var _msg: String = ""
var _result_t: float = 0.0
var _wait: float = 0.0
var _my_pts: int = 0
var _dad_pts: int = 0
var _bags: Array = []    # {pos, rot, who, in_hole}
var _throwing: float = 0.0


func _ready() -> void:
	bg_color = Color.html("8ecae6")
	super()


func _on_start() -> void:
	_round = 0
	_turn = "me"
	_phase = "aim"
	_t = 0.0
	_my_pts = 0
	_dad_pts = 0
	_bags.clear()


func _board_poly() -> PackedVector2Array:
	return PackedVector2Array([Vector2(CX - 118, BOARD_TOP), Vector2(CX + 118, BOARD_TOP), Vector2(CX + 160, BOARD_BOT), Vector2(CX - 160, BOARD_BOT)])


func _start_pos() -> Vector2:
	return Vector2(CX - 20.0, size.y - 170.0)


func _persp(y: float) -> float:
	return lerpf(1.15, 0.5, clampf((size.y - 150.0 - y) / 440.0, 0.0, 1.0))


func _swing(speed: float) -> float:
	return sin(_t * speed)


func _tick(delta: float) -> void:
	_throwing = maxf(0.0, _throwing - delta * 2.5)
	match _phase:
		"aim", "power":
			_t += delta
			if _turn == "dad":
				_wait -= delta
				if _wait <= 0.0:
					_dad_throw()
		"fly":
			_fly += delta / 0.85
			if _fly >= 1.0:
				_score_bag()
		"result":
			if _slide < 1.0 and _slide_to_hole:
				_slide = minf(1.0, _slide + delta * 2.2)
				_bags[-1]["pos"] = _land.lerp(HOLE, _slide)
			_result_t -= delta
			if _result_t <= 0.0:
				_next_turn()


func _next_turn() -> void:
	if _turn == "me":
		_turn = "dad"
		_wait = 0.9
	else:
		_turn = "me"
		_round += 1
		if _round >= BAGS:
			var margin := _my_pts - _dad_pts
			complete(1 if margin <= 0 else (2 if margin < 3 else 3))
			return
	_phase = "aim"
	_t = 0.0


func _score_bag() -> void:
	var slack := (float(Game.mod("jump", 1.0)) - 1.0) * 14.0 if _turn == "me" else 0.0
	var dist := _land.distance_to(HOLE)
	_gain = 0
	_slide_to_hole = false
	var on_board := Geometry2D.is_point_in_polygon(_land, _board_poly())
	if dist <= 17.0 + slack:
		_gain = 3
		_msg = "IN THE HOLE!"
	elif on_board:
		_gain = 1
		_msg = "On the board!"
		if dist < 52.0 + slack and randf() < 0.5:
			_gain = 3
			_slide_to_hole = true
			_slide = 0.0
			_msg = "It slid in!"
	else:
		_msg = "Miss!"
	if _turn == "me":
		_my_pts += _gain
	else:
		_dad_pts += _gain
	_bags.append({"pos": _land, "rot": randf() * TAU, "who": _turn, "in_hole": _gain == 3})
	_phase = "result"
	_result_t = 1.1


func _dad_throw() -> void:
	var r := randf()
	var target: Vector2
	if r < 0.22:
		target = HOLE + Vector2(randf_range(-10, 10), randf_range(-8, 8))
	elif r < 0.7:
		target = Vector2(CX + randf_range(-100, 100), randf_range(BOARD_TOP + 15.0, BOARD_BOT - 20.0))
	else:
		target = Vector2(CX + randf_range(-230, 230), randf_range(BOARD_TOP - 50.0, BOARD_BOT + 60.0))
	_from = Vector2(CX + 190.0, size.y - 190.0)
	_land = target
	_phase = "fly"
	_fly = 0.0


func _on_input(event: InputEvent) -> void:
	if _turn != "me" or not is_confirm(event):
		return
	if _phase == "aim":
		_aim = _swing(2.6)
		_phase = "power"
		_t = 0.0
	elif _phase == "power":
		_power = absf(_swing(1.9))
		_from = _start_pos()
		var y := lerpf(size.y - 250.0, BOARD_TOP - 60.0, _power)
		_land = Vector2(CX + _aim * 250.0, y) + Vector2(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0))
		_phase = "fly"
		_fly = 0.0
		_throwing = 1.0


func _draw_bag(p: Vector2, rot: float, col: Color) -> void:
	var s := _persp(p.y)
	draw_set_transform(p, rot, Vector2(s, s))
	draw_rect(Rect2(-17, -17, 34, 34), col)
	draw_rect(Rect2(-17, -17, 34, 34), col.darkened(0.4), false, 3.0)
	draw_line(Vector2(-17, -17), Vector2(17, 17), col.darkened(0.25), 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_game() -> void:
	if not running:
		return
	var horizon := 110.0
	draw_rect(Rect2(0, horizon, size.x, size.y - horizon), Color.html("d4a373"))
	draw_rect(Rect2(0, horizon, size.x, 30), Color.html("e9c46a"))
	# lane markings in perspective
	for x: float in [-1.0, 1.0]:
		draw_line(Vector2(CX + x * 140.0, BOARD_BOT), Vector2(CX + x * 520.0, size.y), Color(1, 1, 1, 0.3), 4.0)
	# board: legs, deck, hole
	draw_colored_polygon(PackedVector2Array([Vector2(CX - 130, BOARD_BOT + 10), Vector2(CX + 130, BOARD_BOT + 10), Vector2(CX + 160, BOARD_BOT + 44), Vector2(CX - 160, BOARD_BOT + 44)]), Color.html("4a3728"))
	draw_colored_polygon(_board_poly(), Color.html("6c584c"))
	var inner := PackedVector2Array([Vector2(CX - 108, BOARD_TOP + 8), Vector2(CX + 108, BOARD_TOP + 8), Vector2(CX + 148, BOARD_BOT - 8), Vector2(CX - 148, BOARD_BOT - 8)])
	draw_colored_polygon(inner, Color.html("c9a37a"))
	draw_set_transform(HOLE, 0.0, Vector2(1.0, 0.6))
	draw_circle(Vector2.ZERO, 22.0, Color.html("2b2d42"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# bags resting on the board (the hole ones vanish)
	for b: Dictionary in _bags:
		if not (b["in_hole"] and (b["pos"] as Vector2).distance_to(HOLE) < 2.0):
			_draw_bag(b["pos"], b["rot"], Color.html("e63946") if b["who"] == "me" else Color.html("118ab2"))
	# HUD
	text(Vector2(24, 40), "Round %d / %d" % [mini(_round + 1, BAGS), BAGS], 28, Color.html("3d2c00"))
	text(Vector2(24, 76), "%s  %d" % [Game.character()["name"], _my_pts], 28, Color.html("9d0208"))
	text(Vector2(24, 110), "Dad  %d" % _dad_pts, 28, Color.html("0b6f92"))
	text_c(Vector2(CX, 385), "Your turn" if _turn == "me" else "Dad's turn...", 26, Color.html("3d2c00"))
	# players: the chosen sister (red bags) on the left, Dad on the right
	var tilt := -0.1 * _throwing
	_Art.draw_sister(self, Game.character_id, Vector2(CX - 150, size.y - 40), 0.8, 1.0, 0.0, tilt)
	_Art.draw_animal(self, Game.animal_id, Vector2(120, size.y - 36), 0.65, 1.0, absf(sin(_t * 7.0)) * 10.0 if _phase == "result" and _gain > 0 and _turn == "me" else 0.0)
	draw_rect(Rect2(CX + 160, size.y - 220, 46, 90), Color.html("f1faee"))              # Dad: thobe
	draw_circle(Vector2(CX + 183, size.y - 238), 24.0, Color("e8b98a"))
	draw_rect(Rect2(CX + 157, size.y - 264, 52, 18), Color.html("f8f9fa"))              # ghutra
	draw_rect(Rect2(CX + 162, size.y - 130, 14, 90), Color.html("f1faee"))
	draw_rect(Rect2(CX + 190, size.y - 130, 14, 90), Color.html("f1faee"))
	# the bag in hand / in flight
	if _phase == "aim" or _phase == "power":
		if _turn == "me":
			_draw_bag(_start_pos() + Vector2(0, -22), 0.3, Color.html("e63946"))
		else:
			_draw_bag(Vector2(CX + 190.0, size.y - 220.0), 0.3, Color.html("118ab2"))
	elif _phase == "fly":
		var f := minf(_fly, 1.0)
		var origin := _from
		var bag_pos := origin.lerp(_land, f) + Vector2(0, -sin(f * PI) * 150.0)
		draw_circle(origin.lerp(_land, f), 8.0 * _persp(_land.y), Color(0, 0, 0, 0.22))   # shadow
		_draw_bag(bag_pos, f * 9.0, Color.html("e63946") if _turn == "me" else Color.html("118ab2"))
	# controls
	if _turn == "me" and _phase == "aim":
		var ax := CX + _swing(2.6) * 250.0
		draw_line(Vector2(ax, BOARD_TOP - 30), Vector2(ax, BOARD_BOT + 40), Color(1, 1, 1, 0.9), 4.0)
		draw_circle(Vector2(ax, BOARD_TOP - 30), 8.0, Color(1, 1, 1, 0.9))
		text_c(Vector2(CX, size.y - 20), "SPACE to lock your aim", 26, Color.html("3d2c00"))
	elif _turn == "me" and _phase == "power":
		var ax2 := CX + _aim * 250.0
		draw_line(Vector2(ax2, BOARD_TOP - 30), Vector2(ax2, BOARD_BOT + 40), Color(1, 1, 1, 0.5), 3.0)
		var bar := Rect2(size.x - 120, 150, 36, 380)
		draw_rect(bar, Color.html("264653"))
		# the green band = board, gold line = hole
		var y_of := func(py: float) -> float: return bar.end.y - bar.size.y * py
		var board_lo := (size.y - 250.0 - BOARD_BOT) / (size.y - 250.0 - (BOARD_TOP - 60.0))
		var board_hi := (size.y - 250.0 - BOARD_TOP) / (size.y - 250.0 - (BOARD_TOP - 60.0))
		var hole_p := (size.y - 250.0 - HOLE.y) / (size.y - 250.0 - (BOARD_TOP - 60.0))
		draw_rect(Rect2(bar.position.x, y_of.call(board_hi), bar.size.x, bar.size.y * (board_hi - board_lo)), Color.html("80b918"))
		draw_rect(Rect2(bar.position.x - 6, y_of.call(hole_p) - 3, bar.size.x + 12, 6), Color.html("ffd60a"))
		var pw := absf(_swing(1.9))
		draw_rect(Rect2(bar.position.x - 10, y_of.call(pw) - 5, bar.size.x + 20, 10), Color.WHITE)
		text_c(Vector2(CX, size.y - 20), "SPACE to lock your power (green = board, gold = hole)", 26, Color.html("3d2c00"))
	if _phase == "result":
		text_c(Vector2(CX, 420), _msg, 52, Color.html("3d2c00"))
