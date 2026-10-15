extends Control
## Pick Daniah, Sarah or Lamia, then start the day in the city.


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var col := UIKit.centered_column(self, Color.html("264653"))
	col.add_child(UIKit.label("Who's driving today?", 44))

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 40)
	col.add_child(row)

	var first_button: Button = null
	for id: String in Game.CHARACTERS:
		var data: Dictionary = Game.CHARACTERS[id]
		var card := VBoxContainer.new()
		card.add_theme_constant_override("separation", 8)
		var portrait := Portrait.new()
		portrait.kind = id
		card.add_child(portrait)
		card.add_child(UIKit.label("%s  %s" % [data["name"], data["name_ar"]], 30))
		card.add_child(UIKit.label(data["title"], 20, Color.html("ffd479")))
		card.add_child(UIKit.label(data["blurb"], 16, Color.html("dddddd"), 260.0))
		var pick := UIKit.button("Choose %s" % data["name"], _on_pick.bind(id), Vector2(260, 54))
		card.add_child(pick)
		row.add_child(card)
		if first_button == null:
			first_button = pick

	col.add_child(UIKit.button("Back", func() -> void: Router.go("main_menu"), Vector2(160, 44)))
	first_button.grab_focus()


func _on_pick(id: String) -> void:
	Game.select_character(id)
	Music.play_for(id)
	Game.spawn_id = "home"
	Router.go("city")
