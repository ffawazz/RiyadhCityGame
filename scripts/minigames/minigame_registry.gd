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
		"script": "res://scripts/minigames/school_sort.gd",
	},
	"living_room": {
		"title": "Living Room Tidy-Up",
		"instructions": "Put the cushions and toys back where they belong.",
		"script": "res://scripts/minigames/tidy_living_room.gd",
	},
	"kitchen": {
		"title": "Kitchen Helpers",
		"instructions": "Help cook: add the ingredients in the right order.",
		"script": "res://scripts/minigames/kitchen_helpers.gd",
	},
	"backyard": {
		"title": "Backyard Treasure Hunt",
		"instructions": "Find the hidden items around the garden.",
		"script": "res://scripts/minigames/backyard_hunt.gd",
	},
	"baqalah_snacks": {
		"title": "Baqalah Snack Pack",
		"instructions": "Quick! Grab the snacks on the list and pack the car for the road trip.",
		"script": "res://scripts/minigames/snack_pack.gd",
	},
	"farm_swim": {
		"title": "Pool Splash",
		"instructions": "Swim across the farm pool, collecting rings. Ducks are fastest!",
		"script": "res://scripts/minigames/pool_splash.gd",
	},
	"farm_pingpong": {
		"title": "Farm Ping Pong",
		"instructions": "Keep the rally going with your paddle.",
		"script": "res://scripts/minigames/ping_pong.gd",
	},
	"farm_cornhole": {
		"title": "Cornhole Toss",
		"instructions": "Toss the bean bags into the hole. Goats throw farthest!",
		"script": "res://scripts/minigames/cornhole_toss.gd",
	},
	"farm_basketball": {
		"title": "Farm Basketball",
		"instructions": "Time your jump and shoot hoops.",
		"script": "res://scripts/minigames/basketball_shot.gd",
	},
}


static func create(minigame_id: String) -> MiniGameBase:
	var entry: Dictionary = ENTRIES.get(minigame_id,
			{"title": minigame_id, "instructions": "", "script": PLACEHOLDER})
	var script: GDScript = load(entry["script"])
	var mg: MiniGameBase = script.new()
	mg.info = entry
	return mg
