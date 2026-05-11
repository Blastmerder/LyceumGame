extends Node

## Sequenced evacuation-drill demo. The Start button kicks off the
## first drill via EventManager.start_event; each EvacuationEvent
## emits `succeeded` when its hitbox is touched, which advances the
## sequence. The sequencer holds NO event-facing text — every chat
## line is configured on the EvacuationEvent itself.

@onready var events: EventsContainer = %Events
@onready var start_button: Button = %StartButton

var _sequence: PackedStringArray = PackedStringArray([
	"drill_drone",
	"drill_fire",
	"drill_terror",
])
var _index: int = 0

func _ready() -> void:
	for child in events.get_children():
		if child is EvacuationEvent:
			child.succeeded.connect(_on_drill_finished)
	start_button.pressed.connect(_start_sequence)


func _start_sequence() -> void:
	_index = 0
	_run_current()


func _run_current() -> void:
	if _index >= _sequence.size():
		return
	var drill_name := _sequence[_index]
	print("[EventsTest] start_event:", drill_name)
	EventManager.start_event(drill_name)


func _on_drill_finished(_event: EvacuationEvent) -> void:
	_index += 1
	await get_tree().create_timer(2.0).timeout
	_run_current()
