extends Node

## Sequenced evacuation-drill demo. The EventsContainer ("Events")
## holds three EvacuationEvent children (drone, fire, terrorist). The
## script triggers them in order via EventManager — exactly what
## external code would do — and chains them by listening to each
## event's `succeeded` signal.

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
	ChatManager.send("Учения эвакуации начинаются.", "Завуч")
	_run_current()


func _run_current() -> void:
	if _index >= _sequence.size():
		ChatManager.send("Все учения завершены.", "Завуч")
		return
	var drill_name := StringName(_sequence[_index])
	print("[EventsTest] dispatch:", drill_name)
	EventManager.trigger(drill_name)


func _on_drill_finished(_event: EvacuationEvent) -> void:
	_index += 1
	await get_tree().create_timer(2.0).timeout
	_run_current()
