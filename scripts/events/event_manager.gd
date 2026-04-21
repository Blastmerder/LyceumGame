class_name EventManagerClass
extends Node

signal bell_rang(bell_id: String)
signal notification_shown(title: String, text: String)
signal event_triggered(event_name: String, payload: Dictionary)
signal floor_changed(new_floor_id: int, prev_floor_id: int)

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
