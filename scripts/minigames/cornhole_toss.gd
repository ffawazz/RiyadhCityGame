extends MiniGameBase

const _Art := preload("res://scripts/ui/avatar_art.gd")
## Cornhole: SPACE locks the aim, SPACE again locks the power. 5 bags.
## In the hole = 3 points, on the board = 1. Goat's strong legs forgive sloppy aim.

const BAGS := 5

var _bag: int = 0
var _points: int = 0
var _t: float = 0.0
var _phase: String = "aim"   # aim | power | fly | result
var _aim: float = 0.0        # -1..1
var _power: float = 0.0      # 0..1
var _land: Vector2 = Vector2.ZERO
var _fly: float = 0.0
var _gain: int = 0
var _result_t: float = 0.0


func _ready() -> void:
	bg_color = Color.html("e9c46a")
	super()


func _on_start() -> void:
	_bag = 0
	_points = 0
	_phase = "aim"
	_t = 0.0


func _board() -> Rect2:
	return Rect2(size.x * 0.5 - 130, 110, 260, 190)


func _hole() -> Vector2:
	return _board().position + Vector2(130, 55)


func _start_pos() -> Vector2:
	return Vector2(size.x * 0.5, size.y - 90)


func _swing(speed: float) -> float:
	return sin(_t * speed)


func _tick(delta: float) -> void:
	match _phase:
		"aim", "power":
			_t += delta
		"fly":
			_fly += delta / 0.8
			if _fly >= 1.0:
				_score_bag()
		"result":
			_result_t -= delta
			if _result_t <= 0.0:
				_bag += 1
				if _bag >= BAGS:
					complete(maxi(1, stars_from(_points, 3, 6, 9)))
				else:
					_phase = "aim"
					_t = 0.0


func _score_bag() -> void:
	var slack := (float(Game.mod("jump", 1.0)) - 1.0) * 40.0
	if _land.distance_to(_hole()) <= 26.0 + slack:
		_gain = 3
	elif _board().grow(slack * 0.5).has_point(_land):
		_gain = 1
	else:
		_gain = 0
	_points += _gain
	_phase = "result"
	_result_t = 0.9


func _on_input(event: InputEvent) -> void:
	if not is_confirm(event):
		return
	if _phase == "aim":
		_aim = _swing(2.6)
		_phase = "power"
		_t = 0.0
	elif _phase == "power":
		_power = absf(_swing(2.0))
		# power 0.. 1 maps to landing short..long; the hole sits at ~0.8
		var y := lerpf(size.y - 160.0, 60.0, _power)
		_land = Vector2(size.x * 0.5 + _aim * 220.0, y)
		_phase = "fly"
		_fly = 0.0


func _draw_game() -> void:
	if not running:
		return
	text(Vector2(24, 40), "Bag %d / %d    Points %d" % [mini(_bag + 1, BAGS), BAGS, _points], 28, Color.html("3d2c00"))
	draw_rect(Rect2(0, 90, size.x, size.y - 90), Color.html("d4a373"))
	var board := _board()
	draw_rect(board, Color.html("6c584c"))
	draw_rect(board.grow(-8), Color.html("b08968"))
	draw_circle(_hole(), 26.0, Color.html("2b2d42"))
	var start := _start_pos()
	_Art.draw_animal(self, Game.animal_id, start + Vector2(-110, 50), 0.8)
	var bag_pos := start
	if _phase == "fly" or _phase == "result":
		bag_pos = start.lerp(_land, minf(_fly, 1.0)) + Vector2(0, -sin(minf(_fly, 1.0) * PI) * 120.0)
	draw_rect(Rect2(bag_pos - Vector2(18, 18), Vector2(36, 36)), Color.html("e63946"))
	if _phase == "aim":
		var ax := size.x * 0.5 + _swing(2.6) * 220.0
		draw_line(Vector2(ax, 100), Vector2(ax, size.y - 130), Color(1, 1, 1, 0.8), 4.0)
		text_c(Vector2(size.x * 0.5, size.y - 30), "SPACE to lock your aim", 26, Color.html("3d2c00"))
	elif _phase == "power":
		var bar := Rect2(size.x * 0.5 - 200, size.y - 60, 400, 28)
		draw_rect(bar, Color.html("264653"))
		draw_rect(Rect2(bar.position.x, bar.position.y, bar.size.x * absf(_swing(2.0)), bar.size.y), Color.html("ffd166"))
		text_c(Vector2(size.x * 0.5, size.y - 80), "SPACE to lock your power", 26, Color.html("3d2c00"))
	elif _phase == "result":
		text_c(Vector2(size.x * 0.5, 330), ["Miss!", "On the board!", "", "IN THE HOLE!"][_gain], 48, Color.html("3d2c00"))
