extends Node3D
## Minimal starter scene — replace with your game.
## Kept simple so it parses cleanly in CI (godot --check-only).

@onready var label: Label = $UI/Label

func _ready() -> void:
	label.text = "Godot Free Game Studio — ready."

func _process(delta: float) -> void:
	# gentle rotation so it is obviously alive
	$World.rotate_y(delta * 0.4)
