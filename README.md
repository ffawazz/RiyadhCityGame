# Riyadh Kids Adventures

Family-friendly Godot 4 game: drive the blue Mazda CX-9 around Riyadh as Daniah, Sarah or Lamia,
visit Tamimi Supermarket, School, Home (3 zones) and take the road trip to the Al-Muzahimiyah farm.

* Design: [docs/GDD.md](docs/GDD.md)
* Engine: Godot 4.3+ (GDScript). Open this folder in Godot (first open imports the project and registers the `class_name` scripts), then press **F5**.
  Headless check: `godot --headless --import`.

**Controls:** W/S gas & brake (hold S to reverse), A/D steer, **SPACE handbrake** (tap it while turning with the gas on for a *Driver*-style slide; the tyres leave skid marks and smoke), **C** camera (chase / far / hood), **E** enter a light-beam location (slow down first), Esc back to menu/skip. Gamepad supported.

**Crashes:** hit walls or cars hard and the CX-9 gets damaged for real: dents, a crumpled hood and bumper, broken lights, cracked glass, steam, smoke and finally flames, plus less power and a pull to one side. The HUD shows `Car: %`. Repair it at **Mazda Service** (blue circle on the top-middle avenue) or by going home.

**Soundtrack:** Daniah = American rock, Sarah = Korean pop, Lamia = Arabic (maqam Hijaz). Generated in code. To play **your own song** for a sister: on the character screen press **Choose song...** under her name and pick an mp3/ogg (the choice is remembered), or put `lamia.mp3` etc. in the `music` folder.

**Farm:** pick an animal - **Shatoor the duck**, **Hassan the goat** or the chicken - then walk (WASD, SPACE jump) into the glowing circles to play. E enters.

**Run it the safe way (Windows):** `.\run_game.ps1` imports new scripts first, starts the game and writes any errors to `game.log` - send me that file if something breaks.

**Try it:** Play → pick a sister → drive to the supermarket circle (NW) → press E.

**Tests (Godot 4.3):**
* `godot --headless res://tests/smoke_test.tscn` loads every scene, plays every mini-game and drives the car (headless prints harmless `mesh_get_surface_count` messages from the dummy renderer).
* `godot --headless res://tests/music_test.tscn -- <folder>` renders the three tracks to WAV files.
* `godot --headless res://tests/handling_test.tscn` checks handbrake turns, cornering and crash damage numbers.
* `res://tests/drive_shots.tscn`, `crash_shots.tscn`, `scene_tour.tscn` take screenshots (need a real renderer, e.g. xvfb).

All ten mini-games are playable greybox versions.

**Make it yours:** the licence plate digits are `PLATE_NUMBER` / `PLATE_NUMBER_AR` at the top of `scripts/driving/car.gd`; clothes and skin colours of the family are in `_build_interior_and_people()`.
Fonts: `assets/fonts/NotoSansArabic.ttf` (SIL Open Font License, see `OFL-NotoSansArabic.txt`).
