class_name MiniGameRegistry
extends RefCounted
## Maps a mini-game id to its script + display text.
## To add a real game: write a script extending MiniGameBase and change the
## "script" entry (replacing PLACEHOLDER). Nothing else in the project changes.

const PLACEHOLDER := "res://scripts/minigames/placeholder_minigame.gd"

const ENTRIES := {
	"supermarket_catch": {
		"title": "Tamimi Grocery Catch",
		"instructions": "Groceries are falling off the shelves! Catch dates, milk, bread and apples in your basket. Dodge the soap bars!\nMove with A / D or the arrow keys.",
		"script": "res://scripts/minigames/catch_groceries.gd",
	},
	"school_puzzle": {
		"title": "School Supplies Sort",
		"instructions": "Sort pencils, books and notebooks into the right bags before the bell rings.",
		"script": PLACEHOLDER,
	},
	"living_room": {
		"title": "Living Room Tidy-Up",
		"instructions": "Put the cushions and toys back where they belong.",
		"script": PLACEHOLDER,
	},
	"kitchen": {
		"title": "Kitchen Helpers",
		"instructions": "Help cook: add the ingredients in the right order.",
		"script": PLACEHOLDER,
	},
	"backyard": {
		"title": "Backyard Treasure Hunt",
		"instructions": "Find the hidden items around the garden.",
		"script": PLACEHOLDER,
	},
	"baqalah_snacks": {
		"title": "Baqalah Snack Pack",
		"instructions": "Quick! Grab the snacks on the list and pack the car for the road trip.",
		"script": PLACEHOLDER,
	},
	"farm_swim": {
		"title": "Pool Splash",
		"instructions": "Swim across the farm pool, collecting rings. Ducks are fastest!",
		"script": PLACEHOLDER,
	},
	"farm_pingpong": {
		"title": "Farm Ping Pong",
		"instructions": "Keep the rally going with your paddle.",
		"script": PLACEHOLDER,
	},
	"farm_cornhole": {
		"title": "Cornhole Toss",
		"instructions": "Toss the bean bags into the hole. Goats throw farthest!",
		"script": PLACEHOLDER,
	},
	"farm_basketball": {
		"title": "Farm Basketball",
		"instructions": "Time your jump and shoot hoops.",
		"script": PLACEHOLDER,
	},
}


static func create(minigame_id: String) -> MiniGameBase:
	var entry: Dictionary = ENTRIES.get(minigame_id,
			{"title": minigame_id, "instructions": "", "script": PLACEHOLDER})
	var script: GDScript = load(entry["script"])
	var mg: MiniGameBase = script.new()
	mg.info = entry
	return mg
