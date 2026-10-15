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
		"title": "Run to Class!",
		"instructions": "The bell is about to ring! Sprint down the hallway, jump over the backpacks and puddles, and grab pencils and books.\nW / Up / Space to jump - tap twice for a double jump.",
		"script": "res://scripts/minigames/school_run.gd",
	},
	"living_room": {
		"title": "Living Room Dash",
		"instructions": "Mama is almost home! Run around, grab the toys and dump them in the toy box. Dodge the robot vacuum and the cheeky cat!\nWASD to run.",
		"script": "res://scripts/minigames/living_room_dash.gd",
	},
	"kitchen": {
		"title": "Kitchen Rush",
		"instructions": "The family is hungry! Grab ingredients, chop the tomato, fry the egg and build the sandwich the order asks for.\nWASD walk, E / Space to use.",
		"script": "res://scripts/minigames/kitchen_rush.gd",
	},
	"backyard": {
		"title": "Backyard Treasure Hunt",
		"instructions": "Find the hidden items around the garden.",
		"script": "res://scripts/minigames/backyard_hunt.gd",
	},
	"baqalah_snacks": {
		"title": "Baqalah Snack Run",
		"instructions": "Dad is waiting in the car! Dash across the busy forecourt to the shop, grab the snack, and run back - without getting hit!\nWASD to move.",
		"script": "res://scripts/minigames/snack_run.gd",
	},
	"farm_swim": {
		"title": "Pool Splash",
		"instructions": "Swim across the farm pool, collecting rings. Shatoor the duck is fastest!",
		"script": "res://scripts/minigames/pool_splash.gd",
	},
	"farm_pingpong": {
		"title": "Farm Ping Pong",
		"instructions": "Keep the rally going with your paddle.",
		"script": "res://scripts/minigames/ping_pong.gd",
	},
	"farm_cornhole": {
		"title": "Cornhole Toss",
		"instructions": "Toss the bean bags into the hole. Hassan the goat throws farthest!",
		"script": "res://scripts/minigames/cornhole_toss.gd",
	},
	"farm_archery": {
		"title": "Bottle Archery",
		"instructions": "Knock the sand, water, Pepsi and Cola bottles off the shelf! The WIND pushes your shot - watch the flag and aim into it.\nMove the mouse to aim, click or SPACE to shoot, TAB switches between the bow and the air rifle.",
		"script": "res://scripts/minigames/archery_range.gd",
	},
	"farm_swing": {
		"title": "Swing High!",
		"instructions": "Pump the swing by pressing SPACE just as it starts to move forward. When you are really high, press UP / W at the top to jump off and fly as far as you can!",
		"script": "res://scripts/minigames/swing_game.gd",
	},
	"farm_moto": {
		"title": "Farm Motorbike",
		"instructions": "Race the dirt track! Hold D / Right for gas, A / Left to brake. In the air tilt with W / S to land on both wheels. Grab the stars and jump the ramps!",
		"script": "res://scripts/minigames/motorbike_game.gd",
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
	if script == null or not script.can_instantiate():
		push_error("Mini-game '%s' failed to load (%s) - using the placeholder instead" % [minigame_id, entry["script"]])
		script = load(PLACEHOLDER)
	var mg: MiniGameBase = script.new()
	mg.info = entry
	return mg
