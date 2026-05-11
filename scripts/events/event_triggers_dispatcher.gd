class_name EventTriggersDispatcher
extends Node

## Subscribes to every EventTrigger child (existing and added later)
## and forwards their `interactable_activated` to
## EventManager.complete_event(child.event_name).
##
## Hitboxes are always treated as "completion" signals — they nudge
## an already-running event and never start one. To launch an event,
## call EventManager.start_event() from your own code (sequencer,
## input handler, etc).

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
	print("[EventTriggersDispatcher] complete <- ", trigger.name, " name=", trigger.event_name)
	EventManager.complete_event(trigger.event_name)
