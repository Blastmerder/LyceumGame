class_name EventsContainer
extends Node

## Routing-only node. Owns GameEvent children and forwards every
## EventManager.event_signal payload to the child whose `event_name`
## equals payload["name"]. The events themselves decide what to do
## with the message (start vs. trigger_zone-resolution).

var _by_name: Dictionary = {}

func _ready() -> void:
	for child in get_children():
		if child is GameEvent and child.event_name != &"":
			_by_name[child.event_name] = child
	var em: Node = get_tree().root.get_node_or_null("EventManager")
	if em == null:
		push_warning("EventsContainer: EventManager autoload not found")
		return
	em.event_signal.connect(_on_event_signal)


func _on_event_signal(payload: Dictionary) -> void:
	var key: StringName = StringName(String(payload.get("name", "")))
	if key == &"":
		return
	var ev: GameEvent = _by_name.get(key)
	if ev == null:
		print("[EventsContainer] no event for name: %s, known=%s" % [key, _by_name.keys()])
		return
	ev.receive(payload)
