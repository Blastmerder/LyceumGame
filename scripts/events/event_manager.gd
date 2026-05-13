class_name EventManagerClass
extends Node

## Global bus for the trigger-zone / events pipeline.
##
## A single signal carries every payload:
##     { name: <event_name>, type: <message_type>, data: <extras_list> }
## EventsContainer listens to it and forwards each payload to the
## GameEvent child whose event_name matches `name`. Anyone can drop a
## payload here via `dispatch()` (or the `trigger()` helper for the
## common "start" case used in dialogues / buttons).

signal event_signal(payload: Dictionary)

func dispatch(payload: Dictionary) -> void:
	event_signal.emit(payload)

## Start an event by name. Convenience for dialogue mutations and
## buttons: `do EventManager.trigger("drill_fire")`.
func trigger(event_name: String, data: Array = []) -> void:
	dispatch({
		"name": event_name,
		"type": "start",
		"data": data,
	})
