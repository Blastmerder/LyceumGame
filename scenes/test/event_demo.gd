extends Node

## Demo for the new events pipeline. The Start button publishes a
## "start" payload through EventManager; the EventsContainer routes
## it to the DemoEvent child whose event_name matches. After that,
## walking into the COMPLETE / FAILED TriggerZones resolves the same
## event via the trigger_zone payload.

@onready var start_button: Button = %StartButton

func _ready() -> void:
	start_button.pressed.connect(_on_start)


func _on_start() -> void:
	EventManager.trigger("demo_event")
