class_name EvacuationEvent
extends GameEvent

## Base for "go-to-zone" drills. Holds only mechanics: state flag,
## task wiring, Line2D path, hooks. Each concrete drill is its own
## script that overrides `_on_drill_started` and `_on_drill_completed`
## to send chat lines. No text is configured on this base class.

signal started(event: EvacuationEvent)
signal succeeded(event: EvacuationEvent)

@export_group("Targeting")
## Path to the InteractableComponent (or any Node2D) used as the goal
## marker for path drawing.
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


func on_start(_payload: Dictionary = {}) -> void:
	if active:
		print("[EvacuationEvent] %s already active — start ignored" % event_name)
		return
	print("[EvacuationEvent] start:", event_name)
	active = true
	_completed = false
	_player = _find_player()
	_accept_task()
	_setup_path()
	_on_drill_started()
	fire_now()
	started.emit(self)


func on_complete(_payload: Dictionary = {}) -> void:
	if not active:
		print("[EvacuationEvent] %s not active — complete ignored" % event_name)
		return
	if _completed:
		print("[EvacuationEvent] %s already completed — ignored" % event_name)
		return
	print("[EvacuationEvent] complete:", event_name)
	_completed = true
	if task_id != "":
		var tm: Node = get_tree().root.get_node_or_null("TaskManager")
		if tm:
			tm.complete(task_id)
	_clear_path()
	_on_drill_completed()
	fire_now()
	succeeded.emit(self)


## Override in a subclass to push the drill's start text to chat.
## Called once per successful on_start; not called on repeated starts.
func _on_drill_started() -> void:
	pass


## Override in a subclass to push the drill's completion text to chat.
## Called once per successful on_complete; not called on repeats.
func _on_drill_completed() -> void:
	pass


## Helper for subclasses to drop a line into ChatManager.
func chat(text: String, sender: String) -> void:
	if text.is_empty():
		return
	var cm: Node = get_tree().root.get_node_or_null("ChatManager")
	if cm:
		cm.send(text, sender)


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


func _clear_path() -> void:
	if is_instance_valid(_line):
		_line.queue_free()
	_line = null


func _find_player() -> Node2D:
	for node in get_tree().get_nodes_in_group(&"player"):
		if node is Node2D:
			return node
	return null


func _resolve_title() -> String:
	if not task_title.is_empty():
		return task_title
	return String(event_name)
