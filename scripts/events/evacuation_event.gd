class_name EvacuationEvent
extends GameEvent

## Drill-style event: announces a danger via ChatManager, draws a
## guidance line from the player to a target Area2D, and watches for
## the player entering that area. On entry the linked task is marked
## complete and `succeeded` is emitted; the parent EventsContainer can
## chain into the next drill on this signal.
##
## Plug it in by adding it under an EventsContainer and giving it an
## `event_name`; the manager will call `trigger(payload)` to start it.

signal succeeded(event: EvacuationEvent)
signal failed(event: EvacuationEvent)

@export_group("Drill")
@export var announcement: String = "Тревога: эвакуация!"
@export var sender: String = "Завуч"
@export var time_limit: float = 30.0
@export var success_message: String = "Эвакуация выполнена."
@export var fail_message: String = "Время вышло, тренировка провалена."

@export_group("Targeting")
@export var target_path: NodePath
@export var player_group: StringName = &"player"

@export_group("Tasks")
@export var task_id: String = ""
@export var auto_register_task: bool = true
@export var task_title: String = ""
@export var task_description: String = ""

@export_group("Path display")
@export var path_color: Color = Color(1.0, 0.55, 0.0, 0.9)
@export var path_width: float = 2.0
@export var update_interval: float = 0.1

var active: bool = false

var _target: Area2D
var _player: Node2D
var _line: Line2D
var _deadline_timer: Timer
var _redraw_timer: Timer
var _completed: bool = false

func _ready() -> void:
	super._ready()
	_target = get_node_or_null(target_path) as Area2D
	if _target:
		_target.body_entered.connect(_on_target_entered)
	if auto_register_task and task_id != "":
		var tm: Node = get_tree().root.get_node_or_null("TaskManager")
		if tm:
			var existing: Variant = tm.get_task(task_id)
			if existing == null:
				tm.register_raw(task_id, _resolve_title(), task_description, false, "")


func trigger(_payload: Dictionary = {}) -> void:
	if active:
		return
	active = true
	_completed = false
	_player = _find_player()
	_announce(announcement)
	_arm_task()
	_setup_path()
	_setup_deadline()
	fire_now()


func cancel() -> void:
	if not active:
		return
	_teardown()


func _process(_delta: float) -> void:
	if active and is_instance_valid(_line) and is_instance_valid(_player) and is_instance_valid(_target):
		_redraw()


func _arm_task() -> void:
	if task_id == "":
		return
	var tm: Node = get_tree().root.get_node_or_null("TaskManager")
	if tm == null:
		return
	if tm.get_task(task_id) != null:
		tm.accept(task_id)


func _setup_path() -> void:
	_line = Line2D.new()
	_line.default_color = path_color
	_line.width = path_width
	_line.z_index = 10
	get_tree().current_scene.add_child(_line)
	_redraw()
	if _redraw_timer:
		_redraw_timer.queue_free()
	_redraw_timer = Timer.new()
	_redraw_timer.wait_time = max(update_interval, 0.02)
	_redraw_timer.autostart = true
	add_child(_redraw_timer)
	_redraw_timer.timeout.connect(_redraw)


func _setup_deadline() -> void:
	if time_limit <= 0:
		return
	if _deadline_timer:
		_deadline_timer.queue_free()
	_deadline_timer = Timer.new()
	_deadline_timer.one_shot = true
	_deadline_timer.wait_time = time_limit
	add_child(_deadline_timer)
	_deadline_timer.timeout.connect(_on_deadline)
	_deadline_timer.start()


func _redraw() -> void:
	if not is_instance_valid(_line):
		return
	if not is_instance_valid(_player) or not is_instance_valid(_target):
		_line.points = PackedVector2Array()
		return
	_line.points = PackedVector2Array([_player.global_position, _target.global_position])


func _on_target_entered(body: Node) -> void:
	if not active or _completed:
		return
	if not body.is_in_group(player_group):
		return
	_completed = true
	if task_id != "":
		var tm: Node = get_tree().root.get_node_or_null("TaskManager")
		if tm:
			tm.complete(task_id)
	_announce(success_message, sender)
	succeeded.emit(self)
	_teardown()


func _on_deadline() -> void:
	if not active or _completed:
		return
	_announce(fail_message, sender)
	failed.emit(self)
	_teardown()


func _teardown() -> void:
	active = false
	if is_instance_valid(_line):
		_line.queue_free()
	_line = null
	if _redraw_timer:
		_redraw_timer.queue_free()
		_redraw_timer = null
	if _deadline_timer:
		_deadline_timer.queue_free()
		_deadline_timer = null


func _announce(text: String, who: String = sender) -> void:
	if text == "":
		return
	var cm: Node = get_tree().root.get_node_or_null("ChatManager")
	if cm:
		cm.send(text, who)


func _find_player() -> Node2D:
	for node in get_tree().get_nodes_in_group(player_group):
		if node is Node2D:
			return node
	return null


func _resolve_title() -> String:
	if not task_title.is_empty():
		return task_title
	return announcement
