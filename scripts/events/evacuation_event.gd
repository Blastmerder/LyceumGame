class_name EvacuationEvent
extends GameEvent

## Drill event driven by the events bus. It listens to TWO names so
## starting and completing the drill are different signals:
##
##   event_name           ("drill_drone")        -> start the drill
##   complete_event_name  ("drill_drone_done")   -> mark it succeeded
##
## EventsContainer registers both names (see get_handled_names()) and
## passes the actually triggered name back via payload["event_name"].
## The drill ignores `complete_event_name` while it isn't active, so a
## player wandering into the hitbox before the sequencer starts does
## nothing. Once active, the first hit completes; later hits chat the
## `already_message`.

signal succeeded(event: EvacuationEvent)

@export_group("Drill")
@export var announcement: String = "Тревога: эвакуация!"
@export var sender: String = "Завуч"
@export var success_message: String = "Эвакуация выполнена."
@export var already_message: String = "Молодец, ты уже на месте."

@export_group("Events")
## Name dispatched by the sequencer to START this drill. Matches the
## base GameEvent.event_name; kept here just for the inspector group.
## The "complete" name below is the one the hitbox dispatcher sends.
@export var complete_event_name: StringName = &""

@export_group("Targeting")
## Path to the InteractableComponent (or any Node2D) used as the goal
## marker. Only consumed for path drawing — the completion signal
## comes through EventManager.
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


func get_handled_names() -> Array[StringName]:
	var out: Array[StringName] = []
	if event_name != &"":
		out.append(event_name)
	if complete_event_name != &"" and complete_event_name != event_name:
		out.append(complete_event_name)
	return out


func trigger(payload: Dictionary = {}) -> void:
	var name: StringName = StringName(payload.get("event_name", String(event_name)))
	if name == event_name:
		if active:
			print("[EvacuationEvent] %s already started, ignoring start signal" % event_name)
			return
		_start_drill()
	elif name == complete_event_name:
		if not active:
			print("[EvacuationEvent] %s completion ignored — drill not active" % complete_event_name)
			return
		if _completed:
			_already_drill()
			return
		_complete_drill()
	else:
		push_warning("EvacuationEvent %s: unknown trigger name '%s'" % [name, name])


func _start_drill() -> void:
	print("[EvacuationEvent] start:", event_name, " target=", _target)
	active = true
	_completed = false
	_player = _find_player()
	_announce(announcement)
	_accept_task()
	_setup_path()
	fire_now()


func _complete_drill() -> void:
	print("[EvacuationEvent] complete:", event_name)
	_completed = true
	if task_id != "":
		var tm: Node = get_tree().root.get_node_or_null("TaskManager")
		if tm:
			tm.complete(task_id)
	_announce(success_message, sender)
	_clear_path()
	fire_now()
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
