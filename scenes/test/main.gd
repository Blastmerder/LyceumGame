extends Node2D

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

func _ready() -> void:
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
	

func _event_manager() -> Node:
	return get_tree().root.get_node_or_null("EventManager")
