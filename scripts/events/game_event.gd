class_name GameEvent
extends Node

## Base class for an event handled by EventsContainer. Two kinds of
## message are recognised:
##   "start"        -> sets `fired` and registers/accepts the linked
##                     task in TaskManager, sends start_chat. If
##                     `single_fire` is true and the event has already
##                     fired once (single_fired), the message is
##                     ignored.
##   "trigger_zone" -> only accepted while `fired`. Reads
##                     payload["data"][0] (the zone type, e.g.
##                     "complete" / "failed") and resolves the task
##                     and chat accordingly, then clears `fired`.
##
## Subclasses override `_on_started`, `_on_completed`, `_on_failed`
## for any extra side effects. The wording and task metadata stay on
## this node via @export so everything for one event lives in one
## inspector.

@export_group("Identity")
@export var event_name: StringName = &""
@export var single_fire: bool = false

@export_group("Task")
@export var task_id: String = ""
@export var task_title: String = ""
@export var task_description: String = ""

@export_group("Chat")
@export var chat_sender: String = "Система"
@export var start_chat: String = ""
@export var complete_chat: String = ""
@export var failed_chat: String = ""

var fired: bool = false
var single_fired: bool = false


## Called by EventsContainer with a routed payload. The default
## implementation handles the two known message types; subclasses
## that need richer behaviour usually only override the `_on_*`
## hooks below.
func receive(payload: Dictionary) -> void:
	var msg_type: String = String(payload.get("type", ""))
	match msg_type:
		"start":
			_handle_start(payload)
		"trigger_zone":
			_handle_trigger_zone(payload)
		_:
			pass


func _handle_start(payload: Dictionary) -> void:
	if fired:
		print("[GameEvent] %s already fired — start ignored" % event_name)
		return
	if single_fire and single_fired:
		print("[GameEvent] %s single_fire used up" % event_name)
		return
	fired = true
	single_fired = true
	_register_task()
	_send_chat(start_chat)
	_on_started(payload)


func _handle_trigger_zone(payload: Dictionary) -> void:
	if not fired:
		# Event isn't running, ignore stray zone hits.
		return
	var data: Array = payload.get("data", [])
	if data.is_empty():
		return
	var zone_type: String = String(data[0]).to_lower()
	match zone_type:
		"complete":
			_resolve_complete(payload)
		"failed":
			_resolve_failed(payload)
		_:
			pass


func _resolve_complete(payload: Dictionary) -> void:
	if task_id != "":
		var tm: Node = _task_manager()
		if tm:
			tm.complete(task_id)
	_send_chat(complete_chat)
	fired = false
	_on_completed(payload)


func _resolve_failed(payload: Dictionary) -> void:
	if task_id != "":
		var tm: Node = _task_manager()
		if tm:
			tm.fail(task_id)
	_send_chat(failed_chat)
	fired = false
	_on_failed(payload)


## Adds (or re-accepts) the linked task in TaskManager so the UI
## shows a fresh row even on repeated runs.
func _register_task() -> void:
	if task_id == "":
		return
	var tm: Node = _task_manager()
	if tm == null:
		return
	if tm.get_task(task_id) == null:
		tm.register_raw(task_id, _resolve_title(), task_description, false, "")
	if tm.has_method("reset"):
		tm.reset(task_id)
	tm.accept(task_id)


func _send_chat(text: String) -> void:
	if text.is_empty():
		return
	var cm: Node = get_tree().root.get_node_or_null("ChatManager")
	if cm:
		cm.send(text, chat_sender)


func _resolve_title() -> String:
	if not task_title.is_empty():
		return task_title
	return String(event_name)


func _task_manager() -> Node:
	return get_tree().root.get_node_or_null("TaskManager")


# Override points for subclasses.
func _on_started(_payload: Dictionary) -> void:
	pass


func _on_completed(_payload: Dictionary) -> void:
	pass


func _on_failed(_payload: Dictionary) -> void:
	pass
