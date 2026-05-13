class_name TriggerZonesManager
extends Node

## Standalone Node that picks one of its Area2D children to be the
## "live" trigger for a named event. Completely independent of the
## GameEvent that owns the actual logic — both subscribe to
## EventManager.event_signal on their own, so the same payload that
## starts the event also tells this manager to roll a new active
## zone.
##
## Rules:
##   payload.name != event_name  -> ignored
##   payload.type == "start"     -> disable every child, pick a
##                                  random Area2D, enable just that
##                                  one, announce via ChatManager
##   payload.type == "trigger_zone" -> disable every child (the run
##                                     is over either way)
##
## Drop more Area2Ds under the manager to expand the pool; no extra
## wiring needed. Works with TriggerZone or any other Area2D.

@export var event_name: String = ""
## Chat sender for the active-zone announcement.
@export var sender: String = "Менеджер тревоги"
## Goes through `% area.name` — leave the %s in place.
@export var announce_template: String = "Активна зона: %s"
## When true the picked child becomes visible while the others stay
## hidden. Off by default so the player can't see which zone is live
## until they walk into it (or read the chat hint).
@export var show_active: bool = false

var _active: Area2D


func _ready() -> void:
	var em: Node = get_tree().root.get_node_or_null("EventManager")
	if em == null:
		push_warning("TriggerZonesManager: EventManager autoload not found")
		return
	em.event_signal.connect(_on_event_signal)
	_disable_all()


func _on_event_signal(payload: Dictionary) -> void:
	if String(payload.get("name", "")) != event_name:
		return
	var msg_type: String = String(payload.get("type", ""))
	match msg_type:
		"start":
			_pick_random()
		"trigger_zone":
			_disable_all()


func _pick_random() -> void:
	_disable_all()
	var areas: Array[Area2D] = _areas()
	if areas.is_empty():
		print("[TriggerZonesManager] %s: no Area2D children" % event_name)
		return
	_active = areas[randi() % areas.size()]
	_set_enabled(_active, true)
	print("[TriggerZonesManager] %s -> active zone: %s" % [event_name, _active.name])
	var cm: Node = get_tree().root.get_node_or_null("ChatManager")
	if cm and announce_template != "":
		cm.send(announce_template % _active.name, sender)


func _disable_all() -> void:
	_active = null
	for a in _areas():
		_set_enabled(a, false)


func _areas() -> Array[Area2D]:
	var out: Array[Area2D] = []
	for c in get_children():
		if c is Area2D:
			out.append(c)
	return out


func _set_enabled(area: Area2D, enabled: bool) -> void:
	area.monitoring = enabled
	if show_active:
		area.visible = enabled
