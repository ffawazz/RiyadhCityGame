extends MiniGameBase
## Stand-in for mini-games that are not built yet: mash SPACE to fill a meter.
## Always awards at least one star so the loop is fully playable end to end.

const TIME_LIMIT := 8.0

var _taps: int = 0
var _time_left: float = TIME_LIMIT


func _on_start() -> void:
	_taps = 0
	_time_left = TIME_LIMIT + float(Game.mod("extra_time", 0.0))


func _tick(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		complete(maxi(1, 3 if _taps >= 30 else (2 if _taps >= 20 else (1 if _taps >= 10 else 0))))


func _on_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_taps += 1


func _draw_game() -> void:
	if not running:
		return
	var font := ThemeDB.fallback_font
	var bar := Rect2(size.x * 0.25, size.y * 0.5, size.x * 0.5, 50)
	draw_rect(bar, Color.html("1d3557"))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(_taps / 30.0, 0.0, 1.0), bar.size.y)),
			Color.html("ffd166"))
	draw_string(font, Vector2(bar.position.x, bar.position.y - 60), "PLACEHOLDER - mash SPACE!",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color.WHITE)
	draw_string(font, Vector2(bar.position.x, bar.end.y + 50), "Time: %.1f" % maxf(_time_left, 0.0),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color.WHITE)
