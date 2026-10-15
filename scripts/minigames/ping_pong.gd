extends MiniGameBase

const _Art := preload("res://scripts/ui/avatar_art.gd")
## Farm ping pong: W/S or Up/Down (or the mouse) moves your paddle. Return the
## ball as many times in a row as you can. Chicken's reflex = faster paddle.

const GAME_TIME := 30.0
const PADDLE_H := 120.0
const BALL_R := 12.0

var _time_left: float = 0.0
var _py: float = 0.0
var _ay: float = 0.0
var _ball: Vector2 = Vector2.ZERO
var _vel: Vector2 = Vector2.ZERO
var _rally: int = 0
var _best: int = 0


func _ready() -> void:
	bg_color = Color.html("1b4332")
	super()


func _on_start() -> void:
	_time_left = GAME_TIME
	_py = size.y * 0.5
	_ay = size.y * 0.5
	_rally = 0
	_best = 0
	_serve()


func _serve() -> void:
	_ball = size * 0.5
	var dir := Vector2(-1.0, randf_range(-0.4, 0.4)).normalized()
	_vel = dir * 380.0


func _tick(delta: float) -> void:
	_time_left -= delta
	var reflex := float(Game.mod("reflex", 1.0))
	_py = clampf(_py + Input.get_axis("accelerate", "brake") * 520.0 * reflex * delta, PADDLE_H * 0.5, size.y - PADDLE_H * 0.5)
	_ay = move_toward(_ay, _ball.y, 300.0 * delta)
	_ball += _vel * delta
	if _ball.y < BALL_R or _ball.y > size.y - BALL_R:
		_vel.y = -_vel.y
		_ball.y = clampf(_ball.y, BALL_R, size.y - BALL_R)
	var left_x := 70.0
	var right_x := size.x - 70.0
	if _vel.x < 0.0 and _ball.x - BALL_R <= left_x and _ball.x > left_x - 30.0 and absf(_ball.y - _py) <= PADDLE_H * 0.5 + BALL_R:
		_vel.x = absf(_vel.x) * 1.06
		_vel.y += (_ball.y - _py) * 4.0
		_rally += 1
		_best = maxi(_best, _rally)
	elif _vel.x > 0.0 and _ball.x + BALL_R >= right_x and _ball.x < right_x + 30.0 and absf(_ball.y - _ay) <= PADDLE_H * 0.5 + BALL_R:
		_vel.x = -absf(_vel.x)
		_vel.y += (_ball.y - _ay) * 4.0
	if _ball.x < -30.0:
		_rally = 0
		_serve()
	elif _ball.x > size.x + 30.0:
		_serve() # opponent missed: rally keeps going
	if _time_left <= 0.0 and running:
		complete(maxi(1, stars_from(_best, 3, 6, 10)))


func _on_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_py = clampf(get_local_mouse_position().y, PADDLE_H * 0.5, size.y - PADDLE_H * 0.5)


func _draw_game() -> void:
	if not running:
		return
	draw_rect(Rect2(40, 60, size.x - 80, size.y - 100), Color.html("2d6a4f"))
	draw_line(Vector2(size.x * 0.5, 60), Vector2(size.x * 0.5, size.y - 40), Color(1, 1, 1, 0.6), 4.0)
	text(Vector2(24, 40), "Time %d    Rally %d    Best %d" % [maxi(0, ceili(_time_left)), _rally, _best], 28, Color.WHITE)
	_Art.draw_animal(self, Game.animal_id, Vector2(36, _py + 70.0), 0.5)
	draw_rect(Rect2(60, _py - PADDLE_H * 0.5, 14, PADDLE_H), Color.html("ef476f"))
	draw_rect(Rect2(size.x - 74, _ay - PADDLE_H * 0.5, 14, PADDLE_H), Color.html("8d99ae"))
	draw_circle(_ball, BALL_R, Color.html("fff3b0"))
