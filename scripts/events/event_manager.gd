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
##
## Also keeps a `active_zones` registry — a tiny `event_name -> zone_id`
## dictionary that survives scene swaps so a TriggerZonesManager
## spawned with a freshly loaded floor can restore the previously
## picked zone instead of rolling a brand new one.

signal event_signal(payload: Dictionary)

var active_zones: Dictionary = {}

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


## Persistent active-zone registry. Lets a TriggerZonesManager on a
## newly loaded scene restore the zone picked before the floor swap.
func set_active_zone(event_name: String, zone_id: String) -> void:
	active_zones[event_name] = zone_id


func get_active_zone(event_name: String) -> String:
	return active_zones.get(event_name, "")


func clear_active_zone(event_name: String) -> void:
	active_zones.erase(event_name)
