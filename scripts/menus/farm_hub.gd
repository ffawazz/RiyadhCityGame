extends Control
## Hub inside the farm. Mechanics switch from driving to animal avatars:
## the chosen animal plays Swimming, Ping Pong, Cornhole or Basketball.

const ACTIVITIES := [
	{"id": "farm_swim", "label": "Swimming Pool"},
	{"id": "farm_pingpong", "label": "Ping Pong"},
	{"id": "farm_cornhole", "label": "Cornhole"},
	{"id": "farm_basketball", "label": "Basketball"},
]


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var col := UIKit.centered_column(self, Color.html("90be6d"))
	col.add_child(UIKit.label("Al-Muzahimiyah Farm", 44, Color.html("1b4332")))

	var split := HBoxContainer.new()
	split.alignment = BoxContainer.ALIGNMENT_CENTER
	split.add_theme_constant_override("separation", 50)
	col.add_child(split)

	var left := VBoxContainer.new()
	var portrait := Portrait.new()
	portrait.kind = Game.animal_id
	left.add_child(portrait)
	left.add_child(UIKit.label("%s the %s" % [Game.character()["name"], Game.animal()["name"]], 24))
	split.add_child(left)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	var first_button: Button = null
	for act: Dictionary in ACTIVITIES:
		var id: String = act["id"]
		var cell := VBoxContainer.new()
		var btn := UIKit.button(act["label"], _on_activity.bind(id), Vector2(260, 80))
		cell.add_child(btn)
		cell.add_child(UIKit.label(UIKit.stars_text(id), 18, Color.html("1b4332")))
		grid.add_child(cell)
		if first_button == null:
			first_button = btn
	split.add_child(grid)

	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 20)
	bottom.add_child(UIKit.button("Change animal", func() -> void: Router.go("animal_select"), Vector2(220, 50)))
	bottom.add_child(UIKit.button("Drive home", _on_drive_home, Vector2(220, 50)))
	col.add_child(bottom)
	first_button.grab_focus()


func _on_activity(id: String) -> void:
	Router.start_minigame(id, "farm_hub")


func _on_drive_home() -> void:
	Game.spawn_id = "home"
	Game.save_game()
	Router.go("city")
