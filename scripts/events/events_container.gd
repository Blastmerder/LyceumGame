class_name EventsContainer
extends Node

## Manager node that owns GameEvent children. Acts as a single signal
## hub: external code emits EventManager.event_triggered(name, payload),
## the container looks up the matching GameEvent child by name and
## asks it to perform its action via `trigger(payload)`.
##
## A single GameEvent can answer to several names (see
## GameEvent.get_handled_names()) — for example a drill that has a
## "drill_drone" start and a "drill_drone_done" completion. The
## triggered name is forwarded in payload["event_name"] so the event
## can branch on it.

signal event_dispatched(event: GameEvent, payload: Dictionary)
signal event_fired(event: GameEvent)

var _events_by_name: Dictionary = {}

func _ready() -> void:
	for child in get_children():
		if child is GameEvent:
			child.fired.connect(_on_event_fired)
			for n in child.get_handled_names():
				_events_by_name[n] = child
	var em: Node = get_tree().root.get_node_or_null("EventManager")
	if em:
		em.event_triggered.connect(_on_manager_event)


## Look up a child by any of its handled names. Returns null when
## nothing answers to that name.
func get_event(event_name: StringName) -> GameEvent:
	return _events_by_name.get(event_name)


## Trigger an event by name without going through the EventManager.
func trigger(event_name: StringName, payload: Dictionary = {}) -> void:
	var ev: GameEvent = _events_by_name.get(event_name)
	if ev == null:
		return
	var enriched := payload.duplicate()
	enriched["event_name"] = String(event_name)
	ev.trigger(enriched)
	event_dispatched.emit(ev, enriched)


func _on_manager_event(event_name: String, payload: Dictionary) -> void:
	var sn := StringName(event_name)
	var ev: GameEvent = _events_by_name.get(sn)
	if ev == null:
		print("[EventsContainer] no event for name:", event_name, " known:", _events_by_name.keys())
		return
	print("[EventsContainer] dispatch:", event_name, " -> ", ev.name)
	var enriched := payload.duplicate()
	enriched["event_name"] = event_name
	ev.trigger(enriched)
	event_dispatched.emit(ev, enriched)


func _on_event_fired(event: GameEvent) -> void:
	event_fired.emit(event)
