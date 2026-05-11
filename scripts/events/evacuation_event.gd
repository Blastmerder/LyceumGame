class_name EvacuationEvent
extends GameEvent

## Drill event driven by the events bus. `trigger()` is a tiny state
## machine:
##   - first call  -> start (announce, accept task, draw path)
##   - second call -> success (complete task, emit `succeeded`)
##   - subsequent  -> just chat-nudge with `already_message`
## The same name covers both phases, so the dispatcher routing an
## InteractableComponent activation to EventManager.trigger(event_name)
## naturally lands on the right phase.

signal succeeded(event: EvacuationEvent)

@export_group("Drill")
@export var announcement: String = "Тревога: эвакуация!"
@export var sender: String = "Кавеев Рам. Н."
@export var success_message: String = "Эвакуация выполнена."
@export var already_message: String = "Молодец, ты уже на месте."

@export_group("Targeting")
## Path to the InteractableComponent (or any Node2D) used as the goal
## marker. Only consumed for path drawing — the actual completion
## signal comes through EventManager.
@export var target_path: NodePath

@export_group("Tasks")
@export var task_id: String = ""
@export var auto_register_task: bool = true
@export var task_title: String = ""
@export var task_description: String = ""

@export_group("Path display")
@export var draw_path: bool = true
@export var path_color: Color = Color(1.0, 0.55, 0.0, 0.9)
@export var path_width: float = 2.0
## Drawn on a high z_index so it can't be covered by floors/walls.
@export var path_z_index: int = 100

var active: bool = false

var _target: Node2D
var _player: Node2D
var _line: Line2D
var _completed: bool = false

func _ready() -> void:
	super._ready()
	_target = get_node_or_null(target_path) as Node2D
	if _target == null:
		push_warning("EvacuationEvent %s: target_path '%s' didn't resolve to a Node2D" % [name, target_path])
	if auto_register_task and task_id != "":
		var tm: Node = get_tree().root.get_node_or_null("TaskManager")
		if tm and tm.get_task(task_id) == null:
			tm.register_raw(task_id, _resolve_title(), task_description, false, "")


func trigger(_payload: Dictionary = {}) -> void:
	if not active:
		_start_drill()
	elif not _completed:
		_complete_drill()
	else:
		_already_drill()
	fire_now()


func _start_drill() -> void:
	print("[EvacuationEvent] start:", event_name, " target=", _target)
	active = true
	_completed = false
	_player = _find_player()
	_announce(announcement)
	_accept_task()
	_setup_path()


func _complete_drill() -> void:
	print("[EvacuationEvent] complete:", event_name)
	_completed = true
	if task_id != "":
		var tm: Node = get_tree().root.get_node_or_null("TaskManager")
		if tm:
			tm.complete(task_id)
	_announce(success_message, sender)
	_clear_path()
	succeeded.emit(self)


func _already_drill() -> void:
	_announce(already_message, sender)


func _process(_delta: float) -> void:
	if not active or _completed:
		return
	if not is_instance_valid(_line):
		return
	if not is_instance_valid(_player) or not is_instance_valid(_target):
		return
	_line.points = PackedVector2Array([_player.global_position, _target.global_position])


func _accept_task() -> void:
	if task_id == "":
		return
	var tm: Node = get_tree().root.get_node_or_null("TaskManager")
	if tm and tm.get_task(task_id) != null:
		tm.accept(task_id)


func _setup_path() -> void:
	_clear_path()
	if not draw_path or _target == null:
		return
	var host: Node = get_tree().current_scene
	if host == null:
		host = get_tree().root
	_line = Line2D.new()
	_line.default_color = path_color
	_line.width = path_width
	_line.z_index = path_z_index
	_line.z_as_relative = false
	_line.top_level = true
	if _player and _target:
		_line.points = PackedVector2Array([_player.global_position, _target.global_position])
	host.add_child(_line)
	print("[EvacuationEvent] line drawn, parent=", host.name, " points=", _line.points)


func _clear_path() -> void:
	if is_instance_valid(_line):
		_line.queue_free()
	_line = null


func _announce(text: String, who: String = sender) -> void:
	if text.is_empty():
		return
	var cm: Node = get_tree().root.get_node_or_null("ChatManager")
	if cm:
		cm.send(text, who)


func _find_player() -> Node2D:
	for node in get_tree().get_nodes_in_group(&"player"):
		if node is Node2D:
			return node
	return null


func _resolve_title() -> String:
	if not task_title.is_empty():
		return task_title
	return announcement
