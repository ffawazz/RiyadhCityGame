extends Control
## Shown at the farm gate: pick Duck, Goat or Chicken. The choice carries
## into every farm mini-game via Game.mod().


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var col := UIKit.centered_column(self, Color.html("6a994e"))
	col.add_child(UIKit.label("Welcome to the farm, %s!" % Game.character()["name"], 40))
	col.add_child(UIKit.label("Pick your animal", 26, Color.html("fff3b0")))

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 40)
	col.add_child(row)

	var first_button: Button = null
	for id: String in Game.ANIMALS:
		var data: Dictionary = Game.ANIMALS[id]
		var card := VBoxContainer.new()
		card.add_theme_constant_override("separation", 8)
		var portrait := Portrait.new()
		portrait.kind = id
		card.add_child(portrait)
		card.add_child(UIKit.label("%s  %s" % [data["name"], data["name_ar"]], 30))
		card.add_child(UIKit.label(data["blurb"], 18, Color.html("f1f1f1"), 260.0))
		var pick := UIKit.button("Be the %s" % data["name"], _on_pick.bind(id), Vector2(260, 54))
		card.add_child(pick)
		row.add_child(card)
		if first_button == null:
			first_button = pick
	first_button.grab_focus()


func _on_pick(id: String) -> void:
	Game.select_animal(id)
	Router.go("farm_hub")
