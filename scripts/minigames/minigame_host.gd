extends Control
## The single scene Router loads for every mini-game. It builds the requested
## game from the registry and reports the result back to the Router.


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var mg := MiniGameRegistry.create(Game.pending_minigame)
	add_child(mg)
	mg.finished.connect(func(stars: int) -> void: Router.finish_minigame(stars))
