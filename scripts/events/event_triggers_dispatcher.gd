class_name EventTriggersDispatcher
extends Node

## Subscribes to every EventTrigger child (existing and added later)
## and forwards their `interactable_activated` to
## EventManager.trigger(child.event_name).
##
## The dispatcher is intentionally state-free: it just maps a hitbox
## into a named event. EventsContainer/EventManager handles the rest,
## so adding/removing triggers at runtime works without rewiring code.

func _ready() -> void:
	child_entered_tree.connect(_on_child_entered)
	for child in get_children():
		_register(child)


func _on_child_entered(child: Node) -> void:
	_register(child)


func _register(child: Node) -> void:
	if child is EventTrigger:
		var callable := _on_trigger_activated.bind(child)
		if not child.interactable_activated.is_connected(callable):
			child.interactable_activated.connect(callable)


func _on_trigger_activated(trigger: EventTrigger) -> void:
	if trigger.event_name.is_empty():
		push_warning("EventTrigger %s has empty event_name — ignoring activation" % trigger.name)
		return
	print("[EventTriggersDispatcher] ", trigger.name, " -> ", trigger.event_name)
	EventManager.trigger(trigger.event_name)
