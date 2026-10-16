class_name MiniGameBase
extends Control
## Base class for every mini-game. Handles intro -> play -> results panels so
## a concrete game only implements the actual play:
##   _on_start()          called when the player presses Start
##   _tick(delta)         called every frame while running
##   _draw_game()         draw the playfield (called every redraw)
##   _on_input(event)     optional input while running
## ...and calls complete(stars) when done (0-3 stars; never a "game over").
## `info` is the registry entry (title, instructions) set by MiniGameRegistry.

signal finished(stars: int)

var info: Dictionary = {}
var running: bool = false
var bg_color: Color = Color.html("264653")

var _panel_layer: CenterContainer
var _done: bool = false
var _on_button: Callable = Callable()   # what E / Space / Enter does while a panel is up


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE # let clicks reach _unhandled_input
	_panel_layer = CenterContainer.new()
	_panel_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel_layer)
	_show_panel(info.get("title", "Mini-game"),
			Hints.adapt("%s\n\nPlaying as %s\n(Esc to skip)" % [info.get("instructions", ""), Game.character()["name"]]),
			"Start!", _begin)


# --- shared pointer (mouse / finger / WASD) for "point and pick" games --------

var pointer: Vector2 = Vector2(640, 360)
const POINTER_SPEED := 480.0


## Call from _on_input: follows the mouse / finger.
func pointer_event(event: InputEvent) -> void:
	var mm := event as InputEventMouseMotion
	if mm != null:
		pointer = mm.position
		return
	var mb := event as InputEventMouseButton
	if mb != null:
		pointer = mb.position


## Call from _tick: WASD / stick moves the pointer too.
func pointer_move(delta: float) -> void:
	var kb := Input.get_vector("steer_left", "steer_right", "accelerate", "brake")
	if kb != Vector2.ZERO:
		pointer += kb * POINTER_SPEED * delta
		pointer = pointer.clamp(Vector2(10, 10), size - Vector2(10, 10))


func draw_pointer(color: Color = Color(1, 1, 1, 0.95)) -> void:
	draw_arc(pointer, 20.0, 0, TAU, 24, Color.BLACK, 6.0)
	draw_arc(pointer, 20.0, 0, TAU, 24, color, 3.0)
	draw_line(pointer + Vector2(-30, 0), pointer + Vector2(-10, 0), color, 3.0)
	draw_line(pointer + Vector2(30, 0), pointer + Vector2(10, 0), color, 3.0)
	draw_line(pointer + Vector2(0, -30), pointer + Vector2(0, -10), color, 3.0)
	draw_line(pointer + Vector2(0, 30), pointer + Vector2(0, 10), color, 3.0)


# --- hooks for concrete games ---------------------------------------------

func _on_start() -> void:
	pass


func _tick(_delta: float) -> void:
	pass


func _draw_game() -> void:
	pass


func _on_input(_event: InputEvent) -> void:
	pass


## Finish with 0-3 stars; shows the results panel, then emits `finished`.
func complete(stars: int) -> void:
	if _done:
		return
	running = false
	var s := clampi(stars, 0, 3)
	_show_panel("Great job, %s!" % Game.character()["name"],
			"You earned %d / 3 stars" % s, "Continue", func() -> void: _finish(s))


## 3 / 2 / 1 / 0 stars from a score and three ascending thresholds.
func stars_from(value: float, one: float, two: float, three: float) -> int:
	if value >= three:
		return 3
	if value >= two:
		return 2
	if value >= one:
		return 1
	return 0


## 1-9 for number keys (main row or keypad), otherwise -1.
func digit_of(event: InputEvent) -> int:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return -1
	if key.keycode >= KEY_1 and key.keycode <= KEY_9:
		return key.keycode - KEY_0
	if key.keycode >= KEY_KP_1 and key.keycode <= KEY_KP_9:
		return key.keycode - KEY_KP_0
	return -1


## True for a left click or a tap of Space / Enter.
func is_confirm(event: InputEvent) -> bool:
	var mb := event as InputEventMouseButton
	if mb != null:
		return mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
	return event.is_action_pressed("ui_accept")


## True for the "use" keys (E / Enter), Space, or a left click.
func is_use(event: InputEvent) -> bool:
	return event.is_action_pressed("interact") or is_confirm(event)


## Circle vs rectangle overlap.
func circle_hits_rect(c: Vector2, r: float, rect: Rect2) -> bool:
	var nearest := Vector2(clampf(c.x, rect.position.x, rect.end.x), clampf(c.y, rect.position.y, rect.end.y))
	return nearest.distance_to(c) < r


func text(pos: Vector2, s: String, font_size: int = 24, color: Color = Color.WHITE) -> void:
	draw_string(ThemeDB.fallback_font, pos, Hints.adapt(s), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


## Text centred horizontally on pos.x (pos.y is the baseline).
func text_c(pos: Vector2, s: String, font_size: int = 24, color: Color = Color.WHITE) -> void:
	s = Hints.adapt(s)
	var w := ThemeDB.fallback_font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(ThemeDB.fallback_font, pos - Vector2(w * 0.5, 0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


# --- internals ------------------------------------------------------------

func _begin() -> void:
	_clear_panel()
	running = true
	_on_start()


func _finish(stars: int) -> void:
	if _done:
		return
	_done = true
	finished.emit(stars)


func _process(delta: float) -> void:
	if running:
		_tick(delta)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), bg_color)
	_draw_game()


func _unhandled_input(event: InputEvent) -> void:
	# a start / continue panel is showing: E, Space, Enter or a click presses its button
	if _on_button.is_valid() and not running and (event.is_action_pressed("interact") or is_confirm(event)):
		get_viewport().set_input_as_handled()
		var cb := _on_button
		_on_button = Callable()
		cb.call()
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_finish(0)
	elif running:
		_on_input(event)


func _clear_panel() -> void:
	_on_button = Callable()
	for child in _panel_layer.get_children():
		child.queue_free()


func _show_panel(title: String, body: String, button_text: String, callback: Callable) -> void:
	_clear_panel()
	var panel := PanelContainer.new()
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	panel.add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 16)
	margin.add_child(col)
	col.add_child(UIKit.label(title, 36))
	col.add_child(UIKit.label(Hints.adapt(body), 22, Color.WHITE, 560.0))
	_on_button = callback
	var btn := UIKit.button(button_text + "   (%s)" % Hints.btn("confirm"), callback, Vector2(300, 56))
	col.add_child(btn)
	_panel_layer.add_child(panel)
	btn.grab_focus()
