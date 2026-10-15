# Riyadh Kids Adventures

Family-friendly Godot 4 game: drive the blue Mazda CX-9 around Riyadh as Daniah, Sarah or Lamia,
visit Tamimi Supermarket, School, Home (3 zones) and take the road trip to the Al-Muzahimiyah farm.

* Design: [docs/GDD.md](docs/GDD.md)
* Engine: Godot 4.3+ (GDScript). Open this folder in Godot (first open imports the project and registers the `class_name` scripts), then press **F5**.
  Headless check: `godot --headless --import`.

**Controls:** W/S throttle & brake, A/D steer, **E** enter a glowing location, Esc back to menu/skip.

**Try it:** Play → pick a sister → drive to the supermarket circle (NW) → press E.

**Test:** `godot --headless res://tests/smoke_test.tscn` loads every scene and plays every mini-game with simulated input (verified on Godot 4.3).

All ten mini-games are playable greybox versions; art and audio are the next step.
