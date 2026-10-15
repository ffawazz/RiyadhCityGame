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


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel_layer = CenterContainer.new()
	_panel_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel_layer)
	_show_panel(info.get("title", "Mini-game"),
			"%s\n\nPlaying as %s\n(Esc to skip)" % [info.get("instructions", ""), Game.character()["name"]],
			"Start!", _begin)


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
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_finish(0)
	elif running:
		_on_input(event)


func _clear_panel() -> void:
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
	col.add_child(UIKit.label(body, 22, Color.WHITE, 560.0))
	var btn := UIKit.button(button_text, callback, Vector2(220, 56))
	col.add_child(btn)
	_panel_layer.add_child(panel)
	btn.grab_focus()
