# Riyadh Kids Adventures

Family-friendly Godot 4 game: drive the blue Mazda CX-9 around Riyadh as Daniah, Sarah or Lamia,
visit Tamimi Supermarket, School, Home (3 zones) and take the road trip to the Al-Muzahimiyah farm.

* Design: [docs/GDD.md](docs/GDD.md)
* Engine: Godot 4.3+ (GDScript). Open this folder in Godot (first open imports the project and registers the `class_name` scripts), then press **F5**.
  Headless check: `godot --headless --import`.

**Controls:** W/S gas & brake (hold S to reverse), A/D steer, **SPACE handbrake** (tap it while turning with the gas on for a *Driver*-style slide; the tyres leave skid marks and smoke), **C** camera (chase / far / hood; orbit with right-mouse drag or J/L/I/K, zoom with wheel or U/O, B looks back, V locks), **E** enter a light-beam location (slow down first), Esc back to menu/skip. Gamepad supported.

**Crashes:** hit walls or cars hard and the CX-9 gets damaged for real: dents, a crumpled hood and bumper, broken lights, cracked glass, steam, smoke and finally flames, plus less power and a pull to one side. The HUD shows `Car: %`. Repair it at **Mazda Service** (blue circle on the top-middle avenue) or by going home.

**Soundtrack:** Daniah = American rock, Sarah = Korean pop, Lamia = Arabic (maqam Hijaz). Generated in code. To play **your own song** for a sister: on the character screen press **Choose song...** under her name and pick an mp3/ogg (the choice is remembered), or put `lamia.mp3` etc. in the `music` folder.

**Farm:** pick an animal - **Shatoor the duck**, **Hassan the goat** or the chicken - then walk (WASD, SPACE jump) into the glowing circles to play. E enters.

**Farm games (7 + pool/ping-pong/basketball/cornhole):** the farm now has a **map** (top-right, press **M** for the big map), **families strolling around**, and these games - **Bottle Archery** (bow or air rifle at sand / water / Pepsi / Cola bottles, the wind pushes your shot, TAB switches weapon), **Swing Set** (pump with SPACE, jump with W), **Motorbike Track** (D gas, A brake, W/S tilt in the air), a **Pool** where your sister swims the crawl, **Basketball** where she takes the shots, and a **Cornhole match vs Dad** in perspective.

**Android:** the game has on-screen touch controls (a joystick or steer/GAS/BRAKE/DRIFT buttons, tap-to-click menus, finger-drag to aim and to orbit the camera) that appear automatically on a phone/tablet - and on a PC when you start it with `--touch`. A debug **APK** is built by GitHub on every push: open the repo's **Actions** tab -> latest "Android APK" run -> download `RiyadhKids-android-apk`, copy `RiyadhKids-debug.apk` to the phone and open it (allow "install unknown apps"). To build it yourself: `.\build_android.ps1 -Godot <path to Godot 4.3 exe>` (needs the export templates, Android Studio's SDK and JDK 17). Landscape only; best on a recent phone (arm64).

**More farm fun:** pick **Mishmish the cat** or **Qunfuz the hedgehog** at the gate, alongside Shatoor, Hassan and the chicken. New games: **Lemon Picking** (a grove), **Feed the Goats** (goat pen), **Collect Eggs** (hen house), **Sand Digging** (hot/cold treasure hunt), **Trampoline** (time your bounces, then flip) and **Slide** (next to the swings). Cats dash around, hedgehogs waddle (and curl up when you come close), goats and hens live in their pens.

**Run it the safe way (Windows):** `.\run_game.ps1` imports new scripts first, starts the game and writes any errors to `game.log` - send me that file if something breaks.

**Try it:** Play → pick a sister → drive to the supermarket circle (NW) → press E.

**Tests (Godot 4.3):**
* `godot --headless res://tests/smoke_test.tscn` loads every scene, plays every mini-game and drives the car (headless prints harmless `mesh_get_surface_count` messages from the dummy renderer).
* `godot --headless res://tests/music_test.tscn -- <folder>` renders the three tracks to WAV files.
* `godot --headless res://tests/handling_test.tscn` checks handbrake turns, cornering and crash damage numbers.
* `res://tests/drive_shots.tscn`, `crash_shots.tscn`, `scene_tour.tscn` take screenshots (need a real renderer, e.g. xvfb).

All nineteen mini-games are playable greybox versions. `res://tests/farm_games_test.tscn` checks the new farm games headless.

**Make it yours:** the licence plate digits are `PLATE_NUMBER` / `PLATE_NUMBER_AR` at the top of `scripts/driving/car.gd`; clothes and skin colours of the family are in `_build_interior_and_people()`.
Fonts: `assets/fonts/NotoSansArabic.ttf` (SIL Open Font License, see `OFL-NotoSansArabic.txt`).
