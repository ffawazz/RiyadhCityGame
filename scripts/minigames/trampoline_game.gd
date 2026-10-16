extends MiniGameBase

const _Art := preload("res://scripts/ui/avatar_art.gd")
## Trampoline: press SPACE just before you land to bounce higher (perfect timing = +power).
## In the air hold A / D to flip (W = tuck for faster spins) and land upright to score the flips.

const GAME_TIME := 30.0
const GRAVITY := 1900.0
const MAT_Y := 560.0

var _h: float = 0.0
var _vy: float = 0.0
var _power: float = 0.8
var _rot: float = 0.0
var _total_rot: float = 0.0
var _press_t: float = 0.0
var _cooldown: float = 0.0
var _time_left: float = 0.0
var _score: int = 0
var _flips: int = 0
var _squash: float = 0.0
var _flash: String = ""
var _flash_t: float = 0.0
var _fall_t: float = 0.0
var _t: float = 0.0


func _ready() -> void:
	bg_color = Color.html("a2d2ff")
	super()


func _on_start() -> void:
	_time_left = GAME_TIME
	_h = 0.0
	_vy = 1000.0
	_power = 0.8
	_rot = 0.0
	_score = 0
	_flips = 0


func _tick(delta: float) -> void:
	_t += delta
	_time_left -= delta
	_flash_t = maxf(0.0, _flash_t - delta)
	_press_t = maxf(0.0, _press_t - delta)
	_cooldown = maxf(0.0, _cooldown - delta)
	_squash = maxf(0.0, _squash - delta * 5.0)
	if _fall_t > 0.0:
		_fall_t -= delta
		_h = 0.0
		_vy = 0.0
		if _fall_t <= 0.0:
			_vy = 800.0
			_rot = 0.0
		if _time_left <= 0.0 and running:
			_end()
		return
	_vy -= GRAVITY * delta
	_h += _vy * delta
	var spin := 0.0
	if Input.is_action_pressed("steer_left"):
		spin -= 1.0
	if Input.is_action_pressed("steer_right"):
		spin += 1.0
	var rate := 6.5 * (1.5 if Input.is_action_pressed("accelerate") else 1.0)
	_rot += spin * rate * delta
	_total_rot += spin * rate * delta
	if _h <= 0.0 and _vy < 0.0:
		_land()
	if _time_left <= 0.0 and running and _h < 40.0:
		_end()


func _end() -> void:
	complete(maxi(1, stars_from(_score, 50, 110, 180)))


func _land() -> void:
	_h = 0.0
	_squash = 1.0
	var off := absf(fposmod(_rot + PI, TAU) - PI)
	var flips := int(roundf(absf(_total_rot) / TAU))
	if off > 0.8:
		_flash = "Oops! Land on your feet"
		_flash_t = 1.0
		_power = 0.6
		_fall_t = 0.7
		_total_rot = 0.0
		return
	_rot = 0.0
	_total_rot = 0.0
	if flips > 0:
		var pts := 10 * flips * flips
		_score += pts
		_flips += flips
		_flash = "%s  +%d" % [["", "FLIP!", "DOUBLE FLIP!", "TRIPLE FLIP!!"][mini(flips, 3)], pts]
		_flash_t = 1.0
	var perfect := _press_t > 0.0
	if perfect:
		_power = minf(1.5 * float(Game.mod("jump", 1.0)) / 1.0, _power + 0.14)
		_score += 2
		if flips == 0:
			_flash = "Perfect bounce! +2"
			_flash_t = 0.7
	else:
		_power = maxf(0.55, _power * 0.88)
	_press_t = 0.0
	_vy = 1150.0 * _power


func _on_input(event: InputEvent) -> void:
	if is_confirm(event) and _cooldown <= 0.0:
		if _h < 220.0 and _vy < 0.0:
			_press_t = 0.3
		else:
			_cooldown = 0.35        # mashing too early costs a moment
			_press_t = 0.0


func _draw_game() -> void:
	if not running:
		return
	draw_rect(Rect2(0, MAT_Y + 80, size.x, size.y - MAT_Y - 80), Color.html("90be6d"))
	draw_circle(Vector2(1100, 120), 60.0, Color.html("ffe66d"))
	for i in 3:
		draw_circle(Vector2(200 + i * 360, 160 + (i % 2) * 50), 50.0, Color(1, 1, 1, 0.8))
	# frame, springs, mat
	var sag := _squash * 24.0
	draw_rect(Rect2(380, MAT_Y + 20, 14, 140), Color.html("495057"))
	draw_rect(Rect2(size.x - 394, MAT_Y + 20, 14, 140), Color.html("495057"))
	draw_colored_polygon(PackedVector2Array([Vector2(360, MAT_Y), Vector2(size.x - 360, MAT_Y), Vector2(size.x - 380, MAT_Y + 22 + sag), Vector2(380, MAT_Y + 22 + sag)]), Color.html("3a86ff"))
	draw_line(Vector2(360, MAT_Y), Vector2(size.x - 360, MAT_Y + sag * 0.3), Color.html("1d3557"), 6.0)
	# the jumper: flips about her middle
	var s := 0.7
	var centre := Vector2(size.x * 0.5, MAT_Y - _h * 0.8 - 60.0 * s + sag * 0.3)
	var feet := centre + Vector2(0, 55.0 * s).rotated(_rot)
	_Art.draw_sister(self, Game.character_id, feet, s, 1.0, 0.0, _rot)
	_Art.draw_animal(self, Game.animal_id, Vector2(180, size.y - 20), 0.7, 1.0, absf(sin(_t * 5.0)) * 10.0 if _h > 80.0 else 0.0)
	# shadow + height meter
	draw_circle(Vector2(size.x * 0.5, MAT_Y + 14), maxf(8.0, 52.0 - _h * 0.08), Color(0, 0, 0, 0.25))
	text(Vector2(24, 40), "Time %d    Points %d    Flips %d" % [maxi(0, ceili(_time_left)), _score, _flips], 28, Color.html("1d3557"))
	text(Vector2(24, 72), "SPACE just before landing = higher bounce    A / D = flip    W = tuck", 20, Color.html("1d3557"))
	draw_rect(Rect2(size.x - 60, 120, 24, 400), Color(0, 0, 0, 0.25))
	draw_rect(Rect2(size.x - 60, 520 - 400.0 * clampf(_power / 1.5, 0.0, 1.0), 24, 400.0 * clampf(_power / 1.5, 0.0, 1.0)), Color.html("80b918"))
	text_c(Vector2(size.x - 48, 110), "power", 18, Color.html("1d3557"))
	if _flash_t > 0.0:
		text_c(Vector2(size.x * 0.5, 190), _flash, 44, Color.html("3d2c00"))
