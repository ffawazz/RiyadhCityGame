class_name DriveScene
extends Node2D
## Base class for every scene where the player drives the car.
## Subclasses only describe the map in _configure(); this class builds the
## collision, zones, camera, HUD and the "press E to enter" logic.

var world_rect: Rect2 = Rect2(0, 0, 2400, 1600)
var ground_color: Color = Color.html("d8c496")
var road_color: Color = Color.html("3a3f47")
var roads: Array = []          # Rect2 - drawn only, drivable
var blocks: Array = []         # Rect2 - drawn AND solid (buildings)
var zones: Array = []          # {"id": String, "pos": Vector2}
var spawns: Dictionary = {}    # spawn id -> Vector2
var default_spawn: Vector2 = Vector2.ZERO

var car: Car
var _active_zone: LocationZone
var _info_label: Label
var _goals_label: Label
var _prompt_label: Label


## Override: fill world_rect, roads, blocks, then call add_zone().
func _configure() -> void:
	pass


## Override: extra background art (trees, signs...), drawn above roads.
func _draw_extra() -> void:
	pass


## Override: extra HUD text appended to the speed readout.
func _extra_info() -> String:
	return ""


func add_zone(id: String, pos: Vector2, spawn_offset: Vector2 = Vector2(180, 0)) -> void:
	zones.append({"id": id, "pos": pos})
	spawns[id] = pos + spawn_offset


func _ready() -> void:
	_configure()
	_build_collision()
	_spawn_zones()
	_spawn_car()
	_build_hud()
	queue_redraw()


func _process(_delta: float) -> void:
	_info_label.text = "%s   |   %d km/h%s" % [
		Game.character()["name"], int(absf(car.speed) * 0.25), _extra_info()]
	_prompt_label.text = ("Press E to enter: %s" % _active_zone.title) if _active_zone else ""
	if _active_zone and Input.is_action_just_pressed("interact"):
		Router.enter_location(_active_zone.location_id)
	if Input.is_action_just_pressed("ui_cancel"):
		Game.save_game()
		Router.go("main_menu")


# --- building the scene -------------------------------------------------

func _build_collision() -> void:
	var t := 200.0 # outer walls sit just outside the world
	var r := world_rect
	_add_solid(Rect2(r.position.x - t, r.position.y - t, r.size.x + 2 * t, t))
	_add_solid(Rect2(r.position.x - t, r.end.y, r.size.x + 2 * t, t))
	_add_solid(Rect2(r.position.x - t, r.position.y, t, r.size.y))
	_add_solid(Rect2(r.end.x, r.position.y, t, r.size.y))
	for b: Rect2 in blocks:
		_add_solid(b)


func _add_solid(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var cs := CollisionShape2D.new()
	cs.shape = shape
	body.add_child(cs)
	add_child(body)


func _spawn_zones() -> void:
	for z: Dictionary in zones:
		var zone := LocationZone.new()
		zone.setup(z["id"], z["pos"])
		zone.car_entered.connect(func(zn: LocationZone) -> void: _active_zone = zn)
		zone.car_exited.connect(func(zn: LocationZone) -> void:
			if _active_zone == zn:
				_active_zone = null)
		add_child(zone)


func _spawn_car() -> void:
	car = Car.new()
	car.position = spawns.get(Game.spawn_id, default_spawn)
	add_child(car)
	var cam := Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.limit_left = int(world_rect.position.x)
	cam.limit_top = int(world_rect.position.y)
	cam.limit_right = int(world_rect.end.x)
	cam.limit_bottom = int(world_rect.end.y)
	car.add_child(cam) # Camera2D ignores parent rotation by default


func _build_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)
	_info_label = _hud_label(hud, 22)
	_info_label.position = Vector2(16, 12)

	_goals_label = _hud_label(hud, 20)
	_goals_label.text = "Today:\n" + "\n".join(Game.daily_lines())
	_goals_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	_goals_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN

	_prompt_label = _hud_label(hud, 30)
	_prompt_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 40)
	_prompt_label.grow_horizontal = Control.GROW_DIRECTION_BOTH


func _hud_label(parent: Node, font_size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	parent.add_child(l)
	return l


# --- drawing --------------------------------------------------------------

func _draw() -> void:
	draw_rect(world_rect.grow(200.0), ground_color)
	for r: Rect2 in roads:
		draw_rect(r, road_color)
		# dashed centre line along the long axis
		if r.size.x >= r.size.y:
			var y := r.get_center().y
			for x in range(int(r.position.x), int(r.end.x), 90):
				draw_line(Vector2(x, y), Vector2(x + 45, y), Color.html("f4f1de"), 4.0)
		else:
			var x := r.get_center().x
			for y in range(int(r.position.y), int(r.end.y), 90):
				draw_line(Vector2(x, y), Vector2(x, y + 45), Color.html("f4f1de"), 4.0)
	for i in blocks.size():
		var b: Rect2 = blocks[i]
		draw_rect(b, Color.html("b8a07a") if i % 2 == 0 else Color.html("c9b58a"))
		draw_rect(b.grow(-14.0), Color.html("e9dcc0"))
	_draw_extra()
