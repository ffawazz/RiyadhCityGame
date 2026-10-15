extends Control
## Arriving home unlocks three zones, each launching its own mini-game.

const ZONES := [
	{"id": "living_room", "label": "Living Room"},
	{"id": "kitchen", "label": "Kitchen"},
	{"id": "backyard", "label": "Backyard"},
]


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var col := UIKit.centered_column(self, Color.html("f2cc8f"))
	var title := UIKit.label("Home Sweet Home  -  %s" % Game.character()["name"], 44, Color.html("3d405b"))
	title.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
	col.add_child(title)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 30)
	col.add_child(row)

	var first_button: Button = null
	for zone: Dictionary in ZONES:
		var id: String = zone["id"]
		var card := VBoxContainer.new()
		card.add_theme_constant_override("separation", 6)
		var btn := UIKit.button(zone["label"], _on_zone.bind(id), Vector2(280, 120))
		card.add_child(btn)
		card.add_child(UIKit.label(UIKit.stars_text(id), 20, Color.html("3d405b")))
		row.add_child(card)
		if first_button == null:
			first_button = btn

	col.add_child(UIKit.button("Drive out", func() -> void: Router.go("city"), Vector2(200, 50)))
	first_button.grab_focus()


func _on_zone(id: String) -> void:
	Router.start_minigame(id, "home_hub")
