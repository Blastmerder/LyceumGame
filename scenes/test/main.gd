extends Node2D

## Main scene that swaps floor scenes in and out. Holds a mirror of
## EventManager.active_zones (event_name -> picked TriggerZone node
## name) so the picked zones from a running event survive across
## floor changes — when a newly loaded floor's TriggerZonesManager
## wakes up, it pulls the saved id from EventManager.active_zones
## and re-enables the matching child.

@export var tasks_file: String = ""
@export var ID_FLOOR: int = 0
var Global_direction: int = 0
@onready var floor: Node = $floor

@export var FLOORS = [
	preload("res://scenes/builds/rooms/lycium1floor.tscn"),
	preload("res://scenes/builds/rooms/lycium2floor.tscn"),
	preload("res://scenes/builds/rooms/lycium3floor.tscn"),
	preload("res://scenes/builds/rooms/lycium4floor.tscn")
]

@export var ledder_part: Resource

var current_scene: Node = null

## Local mirror of EventManager.active_zones — kept in sync via
## the event signal so the main scene exposes the picked zone id
## as a plain field (handy for debugging / save state / etc.).
var active_zones: Dictionary = {}


func _ready() -> void:
	var em := _event_manager()
	if em:
		em.event_signal.connect(_on_event_signal)
		# Sync any state that already existed (e.g. autoload was set
		# from a different scene before Main loaded).
		active_zones = em.active_zones.duplicate()
	current_scene = FLOORS[ID_FLOOR].instantiate()
	_load_floor()


func _change_floor(direction):
	current_scene.queue_free()

	match Global_direction:
		0:
			Global_direction = direction
			current_scene = ledder_part.instantiate()
		_:
			ID_FLOOR += int((Global_direction + direction) / 2)
			Global_direction = 0
			current_scene = FLOORS[ID_FLOOR].instantiate()
	_load_floor()


func _load_floor():
	add_child(current_scene)
	move_child(current_scene, 0)
	var ladders = current_scene.get_node("ladders")
	for ladder in ladders.get_children():
		ladder.ladder_activated.connect(_change_floor)


## Keep the local mirror in sync with whatever a TriggerZonesManager
## (or any other consumer) writes into the autoload.
func _on_event_signal(payload: Dictionary) -> void:
	var em := _event_manager()
	if em == null:
		return
	# Defer one frame so we read the registry after the manager nodes
	# have had a chance to update it.
	await get_tree().process_frame
	active_zones = em.active_zones.duplicate()


func _event_manager() -> Node:
	return get_tree().root.get_node_or_null("EventManager")
