class_name UIKit
extends RefCounted
## Tiny helpers so menu scenes can be built in code (keeps .tscn files trivial).


## Adds an optional background plus a centred vertical column, returns the column.
static func centered_column(root: Control, bg: Color = Color.TRANSPARENT) -> VBoxContainer:
	if bg.a > 0.0:
		var rect := ColorRect.new()
		rect.color = bg
		rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(rect)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 14)
	center.add_child(col)
	return col


static func label(text: String, font_size: int = 24, color: Color = Color.WHITE,
		wrap_width: float = 0.0) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("outline_size", 4)
	if wrap_width > 0.0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = wrap_width
	return l


static func button(text: String, callback: Callable, min_size: Vector2 = Vector2(280, 60)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", 24)
	b.pressed.connect(callback)
	return b


static func stars_text(minigame_id: String) -> String:
	return "%d/3 stars" % Game.stars_for(minigame_id)
