class_name EventManagerClass
extends Node

## Global event bus. `event_started` and `event_completed` are two
## *separate* signals — there is no overloading of one signal for
## both phases. Pick the one that matches the action you want:
##   start_event(name)    -> fires event_started
##   complete_event(name) -> fires event_completed
##
## `event_triggered` stays around for back-compat (dialogue mutations,
## generic "this just happened" pings). It's mapped to event_started
## inside EventsContainer.

signal bell_rang(bell_id: String)
signal notification_shown(title: String, text: String)
signal floor_changed(new_floor_id: int, prev_floor_id: int)

signal event_started(event_name: String, payload: Dictionary)
signal event_completed(event_name: String, payload: Dictionary)

# Legacy: routed to event_started by EventsContainer. Keep so existing
# dialogue mutations and other code can keep using EventManager.trigger.
signal event_triggered(event_name: String, payload: Dictionary)

func start_event(event_name: String, payload: Dictionary = {}) -> void:
	event_started.emit(event_name, payload)

func complete_event(event_name: String, payload: Dictionary = {}) -> void:
	event_completed.emit(event_name, payload)

func ring_bell(bell_id: String = "default") -> void:
	bell_rang.emit(bell_id)
	event_triggered.emit("bell", {"id": bell_id})

func show_notification(title: String, text: String = "") -> void:
	notification_shown.emit(title, text)
	event_triggered.emit("notification", {"title": title, "text": text})

func trigger(event_name: String, payload: Dictionary = {}) -> void:
	event_triggered.emit(event_name, payload)

func notify_floor_change(new_floor_id: int, prev_floor_id: int) -> void:
	floor_changed.emit(new_floor_id, prev_floor_id)
	event_triggered.emit("floor_change", {"from": prev_floor_id, "to": new_floor_id})
