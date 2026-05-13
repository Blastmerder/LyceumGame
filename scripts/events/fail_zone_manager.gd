class_name FailZoneManager
extends Node

## Plain Node that owns several Area2D children (TaskTriggers /
## InteractableComponents). Subscribes to a named event on
## EventManager and, when that event STARTS, picks exactly one child
## to be the "live" fail zone for the run. All other children are
## disabled (monitoring = false) so only the chosen one can fire its
## body_entered / fail signal.
##
## The picked zone is announced in ChatManager every run, so the
## player (and you) can see which one is active without scanning
## the console.

@export var event_name: StringName = &"drill_fire"
@export var sender: String = "Менеджер тревоги"
@export var announce_template: String = "Опасная зона активирована: %s"
## When true the picked child is also visible while others are
## hidden. Leave false to keep the layout opaque.
@export var show_active: bool = false

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
	var label: String = _active.name
	print("[FailZoneManager] %s -> active zone: %s" % [name, label])
	_announce(announce_template % label)


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
	# Reset first — TaskTrigger.reset() flips monitoring back to true,
	# so we set the final value after that.
	if area is TaskTrigger:
		(area as TaskTrigger).reset()
	area.monitoring = enabled
	if show_active:
		area.visible = enabled


func _announce(text: String) -> void:
	if text.is_empty():
		return
	var cm: Node = get_tree().root.get_node_or_null("ChatManager")
	if cm:
		cm.send(text, sender)
