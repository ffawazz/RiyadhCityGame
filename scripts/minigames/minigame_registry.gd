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
		"instructions": "Dad is waiting in the car! Cross the forecourt to the shop, grab the snack, and bring it back to the car. The cars are slow - just wait for a gap!\nWASD to move.",
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
		"instructions": "Knock the sand, water, Pepsi and Cola bottles off the shelf! The WIND pushes your shot - watch the flag and aim into it.\nAim with the mouse (or drag your finger), click / tap or press SPACE to shoot, TAB (SWAP button) switches between the bow and the air rifle.",
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
	"farm_lemons": {
		"title": "Lemon Picking",
		"instructions": "Pick the ripe YELLOW lemons from the tree before time runs out! Golden lemons are worth 3. Leave the green ones, they are not ready!\nMove the mouse (or WASD / drag your finger) and click, tap or press SPACE to pick.",
		"script": "res://scripts/minigames/lemon_picking.gd",
	},
	"farm_goatfeed": {
		"title": "Feed the Goats",
		"instructions": "The goats are hungry! Each one shows what it wants. Pick a food with 1 / 2 / 3 (or the arrow keys), aim with the mouse and click or tap a goat to feed it.\nA happy goat gives you points - the wrong food makes it sad.",
		"script": "res://scripts/minigames/feeding_goats.gd",
	},
	"farm_eggs": {
		"title": "Collect the Eggs",
		"instructions": "The hens are laying! Click or tap the eggs to collect them before they hatch into chicks. Golden eggs are worth extra.\nMove the mouse (or WASD / drag your finger) and click, tap or press SPACE.",
		"script": "res://scripts/minigames/egg_picking.gd",
	},
	"farm_sand": {
		"title": "Sand Digging",
		"instructions": "Treasure is buried in the sand! Dig with your shovel - the sand colour tells you how close you are: red = hot, blue = cold. Find 5 treasures, but watch out for pinchy crabs!\nMove the mouse (or WASD / drag your finger) and click, tap or press SPACE to dig.",
		"script": "res://scripts/minigames/sand_dig.gd",
	},
	"farm_trampoline": {
		"title": "Trampoline",
		"instructions": "Press SPACE just as you land to bounce higher. When you are high, hold A or D to do a flip - land upright to score! W tucks in for faster flips.",
		"script": "res://scripts/minigames/trampoline_game.gd",
	},
	"farm_slide": {
		"title": "Slide Down!",
		"instructions": "Whee! Slide down the big slide. A / D change lane, SPACE jumps over the toys. Collect the stars and splash into the pool at the bottom!",
		"script": "res://scripts/minigames/slide_game.gd",
	},
	"park_bbq": {
		"title": "Camping BBQ",
		"instructions": "Dad lit the coals! Click each kebab when it turns golden brown - not too raw and not burnt! Perfect = 2 points.\nMove the mouse (or WASD / drag your finger) and click, tap or press SPACE.",
		"script": "res://scripts/minigames/bbq_grill.gd",
	},
	"park_kite": {
		"title": "Kite Flying",
		"instructions": "The desert wind is perfect for kites! Steer your kite through the golden rings and dodge the birds.\nMove the mouse (or WASD / drag your finger) to steer the kite.",
		"script": "res://scripts/minigames/kite_flying.gd",
	},
	"park_boat": {
		"title": "Boat Ride on Al-Kharrarah Lake",
		"instructions": "The rain made a lake in the desert! Drive the little boat: W / Up = motor, S / Down = slow down, A / D steer. Collect the floating buoys, go around the rocks and say hi to the ducks!",
		"script": "res://scripts/minigames/boat_game.gd",
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
