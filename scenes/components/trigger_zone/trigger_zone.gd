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
## Seconds to swallow body_entered after the zone is armed by the
## manager (or anyone calling `arm()`). Godot fires body_entered for
## bodies that are *already* inside an Area2D the moment monitoring
## flips to true — without this grace window the player would fail
## a drill just because the picked zone happened to overlap them.
@export var arm_delay: float = 0.15

var _arm_until_msec: int = -1


func _ready() -> void:
	interactable_activated.connect(_on_zone_entered)


## Begin the grace window. While it's open, the next body_entered is
## ignored so a pre-existing overlap doesn't instantly fire the zone.
func arm() -> void:
	if arm_delay > 0.0:
		_arm_until_msec = Time.get_ticks_msec() + int(arm_delay * 1000.0)
	else:
		_arm_until_msec = -1


## Cancel the grace window (used when the manager turns the zone off
## for the next run).
func disarm() -> void:
	_arm_until_msec = -1


func _on_zone_entered() -> void:
	if _arm_until_msec > 0 and Time.get_ticks_msec() < _arm_until_msec:
		# Still in the post-activation grace window — this body_entered
		# is the spurious one from a body that was already overlapping.
		return
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
