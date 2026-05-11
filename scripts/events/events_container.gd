class_name EventsContainer
extends Node

## Manager node that owns GameEvent children. Acts as a single signal
## hub: external code emits EventManager.event_triggered(name, payload),
## the container looks up the matching GameEvent child by event_name
## and asks it to perform its action via `trigger(payload)`.
##
## Each GameEvent child is responsible for the actual side-effects
## (showing a path, playing audio, completing a task, etc). The
## container keeps no event-specific logic itself.

signal event_dispatched(event: GameEvent, payload: Dictionary)
signal event_fired(event: GameEvent)

var _events_by_name: Dictionary = {}

func _ready() -> void:
	for child in get_children():
		if child is GameEvent:
			child.fired.connect(_on_event_fired)
			if child.event_name != &"":
				_events_by_name[child.event_name] = child
	var em: Node = get_tree().root.get_node_or_null("EventManager")
	if em:
		em.event_triggered.connect(_on_manager_event)


## Look up a child by its event_name. Returns null when not found.
func get_event(event_name: StringName) -> GameEvent:
	return _events_by_name.get(event_name)


## Trigger an event by name without going through the EventManager.
func trigger(event_name: StringName, payload: Dictionary = {}) -> void:
	var ev: GameEvent = _events_by_name.get(event_name)
	if ev != null:
		ev.trigger(payload)
		event_dispatched.emit(ev, payload)


func _on_manager_event(event_name: String, payload: Dictionary) -> void:
	var ev: GameEvent = _events_by_name.get(StringName(event_name))
	if ev == null:
		print("[EventsContainer] no event for name:", event_name, " known:", _events_by_name.keys())
		return
	print("[EventsContainer] dispatch:", event_name, " -> ", ev.name)
	ev.trigger(payload)
	event_dispatched.emit(ev, payload)


func _on_event_fired(event: GameEvent) -> void:
	event_fired.emit(event)
