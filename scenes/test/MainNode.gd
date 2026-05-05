class_name FloorManager
extends Node2D

@export var initial_floor_id: int = 0
@export var tasks_file: String = ""

@onready var floors_node: Node = $floors
@onready var player: Player = $Player

@onready var go_down: InteractableComponent = $GoDown
@onready var go_up: InteractableComponent = $GoUp

var cur_floor_id: int = 0

var _on_ladder: bool = false
var _ladder_armed: bool = false

func _ready() -> void:
	cur_floor_id = initial_floor_id
	if tasks_file != "":
		var tm := _task_manager()
		if tm:
			tm.load_from_file(tasks_file)


func _event_manager() -> Node:
	return get_tree().root.get_node_or_null("EventManager")


func _task_manager() -> Node:
	return get_tree().root.get_node_or_null("TaskManager")
