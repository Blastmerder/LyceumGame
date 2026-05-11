class_name EventsContainer
extends Node

## Owns GameEvent children and routes EventManager's two phase signals
## to them: `event_started` -> child.on_start(), `event_completed` ->
## child.on_complete(). The phases are isolated — neither path knows
## about the other.
##
## Legacy `event_triggered` is treated as a generic "started" alias so
## existing code (e.g. dialogue mutations doing
## `do EventManager.trigger("npc_test")`) keeps working without
## creating a third phase.

signal event_started_dispatched(event: GameEvent, payload: Dictionary)
signal event_completed_dispatched(event: GameEvent, payload: Dictionary)
signal event_fired(event: GameEvent)

var _starts_by_name: Dictionary = {}
var _completes_by_name: Dictionary = {}

func _ready() -> void:
	for child in get_children():
		if child is GameEvent:
			child.fired.connect(_on_event_fired)
			for n in child.get_start_names():
				_starts_by_name[n] = child
			for n in child.get_complete_names():
				_completes_by_name[n] = child
	var em: Node = get_tree().root.get_node_or_null("EventManager")
	if em:
		em.event_started.connect(_on_started_signal)
		em.event_completed.connect(_on_completed_signal)
		em.event_triggered.connect(_on_legacy_triggered)


## Programmatic alias for EventManager.start_event without going via
## the autoload — useful in tests and internal wiring.
func dispatch_start(event_name: StringName, payload: Dictionary = {}) -> void:
	_dispatch_to(_starts_by_name, event_name, payload, true)


func dispatch_complete(event_name: StringName, payload: Dictionary = {}) -> void:
	_dispatch_to(_completes_by_name, event_name, payload, false)


func _on_started_signal(event_name: String, payload: Dictionary) -> void:
	_dispatch_to(_starts_by_name, StringName(event_name), payload, true)


func _on_completed_signal(event_name: String, payload: Dictionary) -> void:
	_dispatch_to(_completes_by_name, StringName(event_name), payload, false)


func _on_legacy_triggered(event_name: String, payload: Dictionary) -> void:
	_dispatch_to(_starts_by_name, StringName(event_name), payload, true)


func _dispatch_to(table: Dictionary, key: StringName, payload: Dictionary, is_start: bool) -> void:
	var ev: GameEvent = table.get(key)
	if ev == null:
		print("[EventsContainer] no %s handler for %s, known=%s" % [
			"start" if is_start else "complete", key, table.keys()
		])
		return
	var enriched := payload.duplicate()
	enriched["event_name"] = String(key)
	print("[EventsContainer] %s %s -> %s" % [
		"start" if is_start else "complete", key, ev.name
	])
	if is_start:
		ev.on_start(enriched)
		event_started_dispatched.emit(ev, enriched)
	else:
		ev.on_complete(enriched)
		event_completed_dispatched.emit(ev, enriched)


func _on_event_fired(event: GameEvent) -> void:
	event_fired.emit(event)
