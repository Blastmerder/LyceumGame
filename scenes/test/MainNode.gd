class_name FloorManager
extends Node2D

signal floor_changed(new_id: int, prev_id: int)
signal ladder_entered(source_floor_id: int)

@export var initial_floor_id: int = 0
@export var tasks_file: String = ""

@onready var floors_node: Node = $floors
@onready var ledder_part: Node2D = $LedderPart

var cur_floor_id: int = 0
var _on_ladder: bool = false

func _ready() -> void:
	cur_floor_id = initial_floor_id
	_connect_staircases()
	_show_floor(cur_floor_id)
	if tasks_file != "":
		var tm := _task_manager()
		if tm:
			tm.load_from_file(tasks_file)

func _connect_staircases() -> void:
	for stair in get_tree().get_nodes_in_group("staircase"):
		if stair is Staircase:
			stair.staircase_entered.connect(_on_staircase_entered)
	for exit in get_tree().get_nodes_in_group("ladder_exit"):
		if exit is Staircase:
			exit.staircase_entered.connect(_on_staircase_entered)

func _on_staircase_entered(target_floor_id: int, source_floor_id: int) -> void:
	if target_floor_id == Staircase.LADDER_FLOOR_ID:
		_enter_ladder(source_floor_id)
	else:
		_goto_floor(target_floor_id)

func _enter_ladder(source_floor_id: int) -> void:
	cur_floor_id = source_floor_id
	_on_ladder = true
	
	ladder_entered.emit(source_floor_id)
	_show_ladder()
	var em := _event_manager()
	if em:
		em.trigger("ladder_entered", {"from_floor": source_floor_id})

func _goto_floor(new_id: int) -> void:
	if not _has_floor(new_id):
		push_warning("FloorManager: no floor with id %d" % new_id)
		return
	var prev := cur_floor_id
	cur_floor_id = new_id
	_on_ladder = false
	
	_show_floor(new_id)
	floor_changed.emit(new_id, prev)
	var em := _event_manager()
	if em:
		em.notify_floor_change(new_id, prev)

func _show_floor(floor_id: int) -> void:
	floors_node.visible = true
	ledder_part.visible = false
	_set_collision(ledder_part, false)
	
	for child in floors_node.get_children():
		var active: bool = int(child.get_meta("floor_id", 0)) == floor_id
		child.visible = active
		_set_collision(child, active)
	
	for col in ledder_part.get_children():
		if col.get_meta("exit", false):
			for child in col.get_children():
				print("HUH??")
				child.disabled = true

func _show_ladder() -> void:
	floors_node.visible = false
	ledder_part.visible = true
	_set_collision(ledder_part, true)
	for child in floors_node.get_children():
		_set_collision(child, false)
	
	for col in ledder_part.get_children():
		if col.get_meta("exit", false):
			for child in col.get_children():
				child.disabled = false
				print(child)

func _has_floor(floor_id: int) -> bool:
	for child in floors_node.get_children():
		if int(child.get_meta("floor_id", 0)) == floor_id:
			return true
	return false

func _set_collision(root: Node, enabled: bool) -> void:
	if root == null:
		return
	if "collision_enabled" in root:
		root.collision_enabled = enabled
		return
	for child in root.get_children():
		if child is TileMapLayer:
			child.collision_enabled = enabled
		else:
			_set_collision(child, enabled)

func _event_manager() -> Node:
	return get_tree().root.get_node_or_null("EventManager")

func _task_manager() -> Node:
	return get_tree().root.get_node_or_null("TaskManager")
