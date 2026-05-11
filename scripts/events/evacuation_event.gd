class_name EvacuationEvent
extends GameEvent

## Drill event split across the two phase entry points of the events
## bus: `on_start` from EventManager.event_started, `on_complete` from
## EventManager.event_completed. No shared "trigger" path.
##
## All chat-facing text lives on this node — change a wording here
## and nowhere else.

signal started(event: EvacuationEvent)
signal succeeded(event: EvacuationEvent)


@export_group("Сообщения")
## Sender shown next to every chat line this event produces.
@export var sender: String = "Кавеев Рам. Н."
## Sent to chat when on_start runs.
@export var start_message: String = "Тревога: эвакуация!"
## Sent when on_complete succeeds the first time.
@export var success_message: String = "Эвакуация выполнена."
## Sent when on_complete fires again after success.
@export var already_message: String = "Молодец, ты уже на месте."
## Sent when on_complete fires while the drill isn't active. Empty by
## default — leave blank to keep the early hit completely silent.
@export var idle_complete_message: String = ""
## Sent when on_start fires while the drill is already active.
@export var already_active_message: String = ""

@export_group("Targeting")
## Path to the InteractableComponent (or any Node2D) used as the goal
## marker for the Line2D path display.
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
		print("[EvacuationEvent] start ignored, %s already active" % event_name)
		_announce(already_active_message)
		return
	print("[EvacuationEvent] start:", event_name, " target=", _target)
	active = true
	_completed = false
	_player = _find_player()
	_announce(start_message)
	_accept_task()
	_setup_path()
	fire_now()
	started.emit(self)


func on_complete(_payload: Dictionary = {}) -> void:
	if not active:
		print("[EvacuationEvent] complete ignored, %s not active" % event_name)
		_announce(idle_complete_message)
		return
	if _completed:
		print("[EvacuationEvent] complete: %s already done" % event_name)
		_announce(already_message)
		return
	print("[EvacuationEvent] complete:", event_name)
	_completed = true
	if task_id != "":
		var tm: Node = get_tree().root.get_node_or_null("TaskManager")
		if tm:
			tm.complete(task_id)
	_announce(success_message)
	_clear_path()
	fire_now()
	succeeded.emit(self)


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


## Every chat line passes through this single helper so wording stays
## inside the node. Empty text is skipped silently.
func _announce(text: String) -> void:
	if text.is_empty():
		return
	var cm: Node = get_tree().root.get_node_or_null("ChatManager")
	if cm:
		cm.send(text, sender)


func _find_player() -> Node2D:
	for node in get_tree().get_nodes_in_group(&"player"):
		if node is Node2D:
			return node
	return null


func _resolve_title() -> String:
	if not task_title.is_empty():
		return task_title
	return start_message
