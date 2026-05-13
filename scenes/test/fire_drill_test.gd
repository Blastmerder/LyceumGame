extends Node

## End-to-end demo of the `drill_fire` event built on the new
## components only:
##   - one GameEvent under EventsContainer (its node name IS
##     "drill_fire" — that's the event identity now);
##   - TriggerZones with trigger_type = COMPLETE for the fire exit;
##   - TriggerZones with trigger_type = FAILED for the fire patches;
##   - Start button publishes the "start" payload through EventManager.

@onready var start_button: Button = %StartButton

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)


func _on_start_pressed() -> void:
	EventManager.trigger("drill_fire")
