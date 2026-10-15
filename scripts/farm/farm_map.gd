class_name FarmMap
extends Control
## Top-right mini map of the farm. M toggles a big map with the name of every game.

const ICONS := {
	"farm_swim": ["Pool", Color("48cae4")],
	"farm_pingpong": ["Ping Pong", Color("ef476f")],
	"farm_cornhole": ["Cornhole", Color("f4a261")],
	"farm_basketball": ["Basketball", Color("fcbf49")],
	"farm_archery": ["Archery", Color("9b5de5")],
	"farm_swing": ["Swing", Color("f15bb5")],
	"farm_moto": ["Motorbike", Color("fb5607")],
	"barn": ["Barn", Color("a98467")],
	"farm_exit": ["Exit / Car", Color("ffd166")],
}

var world: FarmWorld
var big: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_M:
		big = not big


func _process(_d: float) -> void:
	queue_redraw()


func _draw() -> void:
	if world == null or world.animal == null:
		return
	var view := get_viewport_rect().size
	var area := Rect2()
	if big:
		var w := minf(view.x - 160.0, (view.y - 160.0) * FarmWorld.SIZE.x / FarmWorld.SIZE.y)
		area = Rect2((view.x - w) * 0.5, 90.0, w, w * FarmWorld.SIZE.y / FarmWorld.SIZE.x)
		draw_rect(Rect2(Vector2.ZERO, view), Color(0, 0, 0, 0.45))
	else:
		area = Rect2(view.x - 262.0, 16.0, 246.0, 246.0 * FarmWorld.SIZE.y / FarmWorld.SIZE.x)
	var k := area.size.x / FarmWorld.SIZE.x
	var f := func(p: Vector2) -> Vector2: return area.position + p * k
	draw_rect(area.grow(6.0), Color(0.1, 0.1, 0.1, 0.8))
	draw_rect(area, Color.html("5d8f43"))
	# paths, pool, court, barn
	var sand := Color.html("dcc89f")
	for r: Rect2 in [Rect2(87.5, 50, 5, 80), Rect2(34, 71.5, 56, 5), Rect2(90, 71.5, 56, 5), Rect2(90, 39.5, 60, 5), Rect2(147.5, 36, 5, 28), Rect2(87.5, 21, 5, 30)]:
		draw_rect(Rect2(f.call(r.position), r.size * k), sand)
	draw_rect(Rect2(f.call(Vector2(22, 50)), Vector2(26, 16) * k), Color("48cae4"))
	draw_rect(Rect2(f.call(Vector2(78, 92.5)), Vector2(24, 15) * k), Color("c9783b"))
	draw_rect(Rect2(f.call(Vector2(134, 14)), Vector2(34, 22) * k), Color("c9a66b"))
	draw_rect(Rect2(f.call(Vector2(112, 108)), Vector2(26, 8) * k), Color("b08968"))
	draw_rect(area, Color(1, 1, 1, 0.9), false, 2.0)
	var fs := 18 if big else 11
	for id: String in FarmWorld.STATIONS:
		var info: Array = ICONS[id]
		var p: Vector2 = f.call(FarmWorld.STATIONS[id])
		draw_circle(p, 8.0 if big else 5.0, Color.BLACK)
		draw_circle(p, 6.5 if big else 3.8, info[1])
		if big:
			var w := ThemeDB.fallback_font.get_string_size(info[0], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			draw_string(ThemeDB.fallback_font, p + Vector2(-w * 0.5, -14.0), info[0], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
	for fam: FarmFamily in world.families:
		draw_circle(f.call(Vector2(fam.global_position.x, fam.global_position.z)), 3.0 if big else 2.0, Color("f8f9fa"))
	# you: an arrow
	var me: Vector2 = f.call(Vector2(world.animal.global_position.x, world.animal.global_position.z))
	var yaw: float = world.animal.rotation.y
	var fwd := Vector2(sin(yaw), cos(yaw))
	var side := Vector2(-fwd.y, fwd.x)
	var sz := 9.0 if big else 6.0
	draw_colored_polygon(PackedVector2Array([me + fwd * sz * 1.4, me - fwd * sz + side * sz * 0.8, me - fwd * sz - side * sz * 0.8]), Color("ff006e"))
	draw_string(ThemeDB.fallback_font, area.position + Vector2(0, -12 if big else area.size.y + 20), "MAP  (M = %s)" % ("close" if big else "big map"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18 if big else 14, Color.WHITE)
	if big:
		draw_string(ThemeDB.fallback_font, area.position + Vector2(area.size.x * 0.5 - 70.0, area.size.y + 34.0), "pink arrow = you   white dots = families", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
