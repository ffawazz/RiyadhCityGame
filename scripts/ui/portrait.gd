class_name Portrait
extends Control

const _Art := preload("res://scripts/ui/avatar_art.gd")
## Placeholder vector art for the three sisters and the three farm animals.
## Swap for real sprites/TextureRects once art exists; callers only use `kind`.

@export var kind: String = "daniah"
@export var min_size: Vector2 = Vector2(200, 260)


func _ready() -> void:
	custom_minimum_size = min_size


func _draw() -> void:
	var k := size.y / 260.0     # the art is drawn for a 260 px tall box and scaled to fit
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
	var cx := size.x * 0.5 / k
	var base_y := size.y / k - 10.0
	match kind:
		"daniah", "sarah", "lamia":
			var data: Dictionary = Game.CHARACTERS[kind]
			var height_scale := {"daniah": 0.8, "sarah": 1.0, "lamia": 0.62}[kind] as float
			_draw_girl(cx, base_y, height_scale, Color.html(data["color"]),
					Color.html(data["hair"]), kind)
		"duck":
			_Art.duck(self, cx, base_y)
		"goat":
			_Art.goat(self, cx, base_y)
		"chicken":
			_Art.chicken(self, cx, base_y)


func _draw_girl(cx: float, base_y: float, h: float, dress: Color, hair: Color, who: String) -> void:
	_Art.girl(self, cx, base_y, h, dress, hair, who)
