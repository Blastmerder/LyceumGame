class_name TriggerZone
extends InteractableComponent

## Extended InteractableComponent that, when a body activates it,
## emits a single dictionary payload through EventManager:
##     {
##         "name": <event_name>,        # event this zone resolves
##         "type": "trigger_zone",      # message type, fixed
##         "data": [<trigger_type>],    # ["complete"], ["failed"], …
##     }
##
## Add a new trigger kind by extending the TriggerType enum — the
## name() helper turns it into the lowercase string that goes into
## `data` automatically.

enum TriggerType {
	COMPLETE,
	FAILED,
}

const MESSAGE_TYPE := "trigger_zone"

@export var event_name: String = ""
@export var trigger_type: TriggerType = TriggerType.COMPLETE

func _ready() -> void:
	interactable_activated.connect(_on_zone_entered)


func _on_zone_entered() -> void:
	if event_name.is_empty():
		push_warning("TriggerZone %s has empty event_name" % name)
		return
	var em: Node = get_tree().root.get_node_or_null("EventManager")
	if em == null:
		return
	em.dispatch({
		"name": event_name,
		"type": MESSAGE_TYPE,
		"data": [_trigger_type_name()],
	})


func _trigger_type_name() -> String:
	# Use the enum key name and lowercase it so adding a new entry
	# (e.g. SECONDARY -> "secondary") needs no extra wiring here.
	return String(TriggerType.find_key(trigger_type)).to_lower()
