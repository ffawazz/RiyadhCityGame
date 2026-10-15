extends MiniGameBase

const _Art := preload("res://scripts/ui/avatar_art.gd")
## Basketball: stop the swinging power meter on the green zone.
## 5 shots; a power meter swings back and forth, stop it inside the green zone.
## Goat's jump perk widens the green zone.

const SHOTS := 5
const SWEET := 0.75

var _shot: int = 0
var _makes: int = 0
var _t: float = 0.0
var _phase: String = "aim"     # aim | fly | result
var _power: float = 0.0
var _fly: float = 0.0
var _made: bool = false
var _result_t: float = 0.0


func _ready() -> void:
	bg_color = Color.html("fcbf49")
	super()


func _on_start() -> void:
	_shot = 0
	_makes = 0
	_phase = "aim"
	_t = 0.0


func _zone() -> float:
	return 0.07 * float(Game.mod("jump", 1.0))


func _meter() -> float:
	return absf(fposmod(_t * 0.9, 2.0) - 1.0)


func _hoop() -> Vector2:
	return Vector2(size.x * 0.78, size.y * 0.35)


func _tick(delta: float) -> void:
	match _phase:
		"aim":
			_t += delta
		"fly":
			_fly += delta / 0.9
			if _fly >= 1.0:
				_phase = "result"
				_result_t = 0.9
		"result":
			_result_t -= delta
			if _result_t <= 0.0:
				_shot += 1
				if _shot >= SHOTS:
					complete(maxi(1, stars_from(_makes, 2, 3, 4)))
				else:
					_phase = "aim"


func _on_input(event: InputEvent) -> void:
	if _phase == "aim" and is_confirm(event):
		_power = _meter()
		_made = absf(_power - SWEET) <= _zone()
		if _made:
			_makes += 1
		_phase = "fly"
		_fly = 0.0


func _draw_game() -> void:
	if not running:
		return
	text(Vector2(24, 40), "Shot %d / %d    Baskets %d" % [mini(_shot + 1, SHOTS), SHOTS, _makes], 28, Color.html("3d2c00"))
	var hoop := _hoop()
	draw_rect(Rect2(hoop.x + 30, hoop.y - 120, 14, 200), Color.html("6c584c"))   # pole
	draw_rect(Rect2(hoop.x + 14, hoop.y - 90, 30, 110), Color.html("f8f9fa"))    # backboard
	draw_arc(hoop, 36.0, 0, PI, 20, Color.html("e63946"), 6.0)                  # rim/net
	draw_line(hoop + Vector2(-34, 0), hoop + Vector2(34, 0), Color.html("e63946"), 6.0)
	var start := Vector2(size.x * 0.2, size.y * 0.8)
	draw_rect(Rect2(0, size.y - 80, size.x, 80), Color.html("bc6c25"))           # court
	_Art.draw_animal(self, Game.animal_id, start + Vector2(-70, 50), 0.85, 1.0, 0.0, 0.0)
	var ball := start
	if _phase != "aim":
		var end := hoop + Vector2((_power - SWEET) * 700.0, 0.0)
		if _made:
			end = hoop
		ball = start.lerp(end, _fly) + Vector2(0, -sin(_fly * PI) * 260.0)
	draw_circle(ball, 20.0, Color.html("e76f51"))
	# power meter
	var bar := Rect2(size.x * 0.5 - 200, size.y - 60, 400, 28)
	draw_rect(bar, Color.html("264653"))
	var z := _zone()
	draw_rect(Rect2(bar.position.x + bar.size.x * (SWEET - z), bar.position.y, bar.size.x * 2.0 * z, bar.size.y), Color.html("80b918"))
	var m := _meter() if _phase == "aim" else _power
	draw_rect(Rect2(bar.position.x + bar.size.x * m - 4, bar.position.y - 8, 8, bar.size.y + 16), Color.WHITE)
	if _phase == "aim":
		text_c(Vector2(size.x * 0.5, size.y - 80), "Press SPACE in the green zone!", 24, Color.html("3d2c00"))
	elif _phase == "result":
		text_c(Vector2(size.x * 0.5, 160), "SWISH!" if _made else "So close!", 56, Color.html("3d2c00"))
