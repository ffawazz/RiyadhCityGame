class_name LocationZone
extends Area2D
## A glowing circle on the road. When the car is inside, the drive scene
## offers "Press E to enter" and hands the location id to the Router.

signal car_entered(zone: LocationZone)
signal car_exited(zone: LocationZone)

const RADIUS := 120.0

var location_id: String = ""
var title: String = ""
var tint: Color = Color.WHITE
var _t: float = 0.0


func setup(id: String, pos: Vector2) -> void:
	location_id = id
	position = pos
	var data: Dictionary = Game.LOCATIONS[id]
	title = data["title"]
	tint = Color.html(data["color"])


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var shape := CircleShape2D.new()
	shape.radius = RADIUS
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)

	var lbl := Label.new()
	lbl.text = title
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.size = Vector2(500, 30)
	lbl.position = Vector2(-250, -RADIUS - 38)
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 6)
	add_child(lbl)

	body_entered.connect(func(body: Node2D) -> void:
		if body is Car:
			car_entered.emit(self))
	body_exited.connect(func(body: Node2D) -> void:
		if body is Car:
			car_exited.emit(self))


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var pulse := 1.0 + 0.05 * sin(_t * 3.0)
	draw_circle(Vector2.ZERO, RADIUS * pulse, Color(tint, 0.25))
	draw_arc(Vector2.ZERO, RADIUS * pulse, 0.0, TAU, 48, tint, 5.0)
