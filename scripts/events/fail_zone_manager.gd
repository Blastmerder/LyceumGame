class_name FailZoneManager
extends Node

## Plain Node that owns several Area2D children (TaskTriggers /
## InteractableComponents — anything with `monitoring`). Subscribes
## to a named event on EventManager and, when that event STARTS,
## picks exactly one child to be the "live" fail zone for the run.
## All other children are disabled (monitoring = false) so only the
## chosen one can fire its body_entered / fail signal.
##
## Designed so that adding more zones is just dropping more Area2Ds
## under the node — no extra wiring.

@export var event_name: StringName = &"drill_fire"
## When true the picked child is also visible while others are
## hidden. Leave false to keep the layout opaque and force the player
## to play it safe.
@export var show_active: bool = false
## Optional chat hint sent when a zone is picked (mostly for debug).
@export var debug_chat: bool = false

var _active: Area2D

func _ready() -> void:
	var em: Node = get_tree().root.get_node_or_null("EventManager")
	if em == null:
		push_warning("FailZoneManager: EventManager autoload not found")
		return
	em.event_started.connect(_on_event_started)
	em.event_completed.connect(_on_event_completed)
	_disable_all()


func _on_event_started(name: String, _payload: Dictionary) -> void:
	if StringName(name) != event_name:
		return
	_disable_all()
	var areas: Array[Area2D] = _areas()
	if areas.is_empty():
		print("[FailZoneManager] %s: no Area2D children" % name)
		return
	_active = areas[randi() % areas.size()]
	_set_enabled(_active, true)
	print("[FailZoneManager] %s -> active zone: %s" % [name, _active.name])
	if debug_chat:
		var cm: Node = get_tree().root.get_node_or_null("ChatManager")
		if cm:
			cm.send("Опасная зона выбрана: %s" % _active.name, "Менеджер")


func _on_event_completed(name: String, _payload: Dictionary) -> void:
	if StringName(name) != event_name:
		return
	_disable_all()


func _areas() -> Array[Area2D]:
	var out: Array[Area2D] = []
	for c in get_children():
		if c is Area2D:
			out.append(c)
	return out


func _disable_all() -> void:
	_active = null
	for a in _areas():
		_set_enabled(a, false)


func _set_enabled(area: Area2D, enabled: bool) -> void:
	area.monitoring = enabled
	if show_active:
		area.visible = enabled
	if area is TaskTrigger:
		(area as TaskTrigger).reset()
