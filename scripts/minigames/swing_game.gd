extends MiniGameBase

const _Art := preload("res://scripts/ui/avatar_art.gd")
const _Pose := preload("res://scripts/ui/pose_art.gd")
## Swing set. A pendulum: press SPACE as the swing starts to move FORWARD to pump it higher
## (a late or early press kills some height). When it is high, press UP / W at the front
## peak to jump off and fly - the further you land, the more stars. 3 jumps.

const JUMPS := 3
const ROPE := 300.0

var _angle: float = 0.5
var _vel: float = 0.0
var _jump_no: int = 0
var _best: float = 0.0
var _total: float = 0.0
var _phase: String = "swing"    # swing | fly | landed
var _fp: Vector2 = Vector2.ZERO
var _fv: Vector2 = Vector2.ZERO
var _land_x: float = 0.0
var _flash: String = ""
var _flash_t: float = 0.0
var _t: float = 0.0
var _result_t: float = 0.0
var _time_left: float = 0.0
var _pumped: bool = false


func _ready() -> void:
	bg_color = Color.html("a2d2ff")
	super()


func _on_start() -> void:
	_new_swing()
	_jump_no = 0
	_total = 0.0
	_best = 0.0


func _new_swing() -> void:
	_angle = 0.35
	_vel = 0.0
	_phase = "swing"
	_time_left = 25.0


func _pivot() -> Vector2:
	return Vector2(260.0, 110.0)


func _seat() -> Vector2:
	return _pivot() + Vector2(sin(_angle), cos(_angle)) * ROPE


func _tick(delta: float) -> void:
	_t += delta
	_flash_t = maxf(0.0, _flash_t - delta)
	match _phase:
		"swing":
			_time_left -= delta
			# gentle pendulum with a little drag
			var acc := -22.0 * sin(_angle) / (ROPE / 100.0) * 1.0
			_vel += acc * delta
			_vel *= 1.0 - 0.18 * delta
			_angle += _vel * delta
			if _vel < 0.0:
				_pumped = false
			_angle = clampf(_angle, -1.25, 1.25)
			if _time_left <= 0.0:
				_jump(false)
		"fly":
			_fv.y += 900.0 * delta
			_fp += _fv * delta
			if _fp.y >= _ground_y():
				_fp.y = _ground_y()
				_phase = "landed"
				_land_x = _fp.x - (_pivot().x + ROPE * sin(0.0))
				var metres := maxf(0.0, (_fp.x - _pivot().x) / 40.0)
				_total += metres
				_best = maxf(_best, metres)
				_flash = "%.1f m!" % metres
				_flash_t = 1.6
				_result_t = 1.6
		"landed":
			_result_t -= delta
			if _result_t <= 0.0:
				_jump_no += 1
				if _jump_no >= JUMPS:
					complete(maxi(1, stars_from(_best, 6.0, 9.0, 12.0)))
				else:
					_new_swing()


func _ground_y() -> float:
	return size.y - 90.0


func _jump(good: bool) -> void:
	var seat := _seat()
	var tangent := Vector2(cos(_angle), -sin(_angle)) * _vel * ROPE   # velocity of the seat
	_fp = seat + Vector2(0, -40.0)
	_fv = tangent * 1.0 + Vector2(40.0, -120.0)
	if not good:
		_fv *= 0.7
	_phase = "fly"


func _on_input(event: InputEvent) -> void:
	if _phase != "swing":
		return
	if is_confirm(event):
		# pump: only helps when pressed while moving forward (right) and low to mid height
		if _vel > 0.05 and not _pumped:
			_pumped = true
			_vel += 0.8 * clampf(1.35 - absf(_angle), 0.15, 1.0)
			_flash = "Nice pump!"
		elif _vel <= 0.05:
			_vel *= 0.8
			_flash = "Wrong time - press as it swings FORWARD"
		_flash_t = 0.6
	elif event.is_action_pressed("accelerate"):
		_jump(_angle > 0.4 and _vel > 0.0)


func _draw_game() -> void:
	if not running:
		return
	var gy := _ground_y()
	draw_rect(Rect2(0, gy, size.x, size.y - gy), Color.html("90be6d"))
	draw_rect(Rect2(0, gy + 30, size.x, size.y - gy - 30), Color.html("84a959"))
	# distance marks
	for m in range(0, 20, 2):
		var x := _pivot().x + m * 40.0
		if x < size.x:
			draw_line(Vector2(x, gy), Vector2(x, gy + 22), Color.WHITE, 3.0)
			text_c(Vector2(x, gy + 48), "%d m" % m, 18, Color.WHITE)
	# frame
	var piv := _pivot()
	draw_line(piv + Vector2(-110, 0), Vector2(piv.x - 190, gy), Color.html("6c757d"), 14.0)
	draw_line(piv + Vector2(110, 0), Vector2(piv.x + 190, gy), Color.html("6c757d"), 14.0)
	draw_line(piv + Vector2(-130, 0), piv + Vector2(130, 0), Color.html("495057"), 16.0)
	text(Vector2(24, 40), "Jump %d / %d    Best %.1f m" % [mini(_jump_no + 1, JUMPS), JUMPS, _best], 28, Color.html("023e8a"))
	if _phase == "swing":
		text(Vector2(24, 72), "SPACE = pump when it swings forward   UP / W = jump off at the top   (%d s)" % maxi(0, ceili(_time_left)), 20, Color.html("023e8a"))
		# height meter
		var h := absf(_angle) / 1.25
		draw_rect(Rect2(24, 96, 200, 16), Color.html("264653"))
		draw_rect(Rect2(24, 96, 200 * h, 16), Color.html("80b918") if h > 0.55 else Color.html("ffd166"))
	var seat := _seat()
	if _phase == "swing":
		draw_line(piv + Vector2(-14, 0), seat + Vector2(-16, 0), Color.html("343a40"), 3.0)
		draw_line(piv + Vector2(14, 0), seat + Vector2(16, 0), Color.html("343a40"), 3.0)
		draw_rect(Rect2(seat + Vector2(-26, -4), Vector2(60, 9)), Color.html("e76f51"))
		_Pose.swinger(self, Game.character_id, seat, clampf(_vel / 1.6, -1.0, 1.0), 1.3)
	else:
		draw_line(piv + Vector2(-14, 0), _seat() + Vector2(-16, 0), Color.html("343a40"), 3.0)
		draw_line(piv + Vector2(14, 0), _seat() + Vector2(16, 0), Color.html("343a40"), 3.0)
		draw_rect(Rect2(_seat() + Vector2(-26, -4), Vector2(60, 9)), Color.html("e76f51"))
		var tumble := sin(_t * 8.0) * 0.1 if _phase == "fly" else 0.0
		_Art.draw_sister(self, Game.character_id, _fp + Vector2(0, 40), 0.55, 1.0, 0.0, tumble)
	# the animal cheers from the grass
	_Art.draw_animal(self, Game.animal_id, Vector2(size.x - 90, gy + 60), 0.6, -1.0, absf(sin(_t * 5.0)) * 8.0 if _phase == "landed" else 0.0)
	if _flash_t > 0.0:
		text_c(Vector2(size.x * 0.5, 170), _flash, 44, Color.html("3d2c00"))
