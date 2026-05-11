class_name EvacuationEvent
extends GameEvent

## Minimal "touch-to-win" drill. When triggered by the EventsContainer
## (via EventManager.trigger(event_name)) it announces itself in chat,
## marks the linked task as accepted, and waits for the linked
## InteractableComponent's `interactable_activated` signal. The first
## touch completes the task and emits `succeeded`. Any subsequent
## touch only nudges the player with `already_message` — the drill
## itself stays in the "done" state until the next trigger() call.

signal succeeded(event: EvacuationEvent)

@export_group("Drill")
@export var announcement: String = "Тревога: эвакуация!"
@export var sender: String = "Завуч"
@export var success_message: String = "Эвакуация выполнена."
@export var already_message: String = "Молодец, ты уже на месте."

@export_group("Targeting")
## Path to an InteractableComponent that emits `interactable_activated`
## when the player enters it.
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

var active: bool = false

var _target: InteractableComponent
var _player: Node2D
var _line: Line2D
var _completed: bool = false

func _ready() -> void:
	super._ready()
	_target = get_node_or_null(target_path) as InteractableComponent
	if _target:
		_target.interactable_activated.connect(_on_target_activated)
	else:
		push_warning("EvacuationEvent %s: target_path '%s' is not an InteractableComponent" % [name, target_path])
	if auto_register_task and task_id != "":
		var tm: Node = get_tree().root.get_node_or_null("TaskManager")
		if tm and tm.get_task(task_id) == null:
			tm.register_raw(task_id, _resolve_title(), task_description, false, "")


func trigger(_payload: Dictionary = {}) -> void:
	if active:
		return
	print("[EvacuationEvent] trigger:", event_name, " target=", _target)
	active = true
	_completed = false
	_player = _find_player()
	_announce(announcement)
	_accept_task()
	_setup_path()
	fire_now()
	# Catch the corner case where the player is already standing in the
	# zone when the drill starts — `interactable_activated` only fires
	# on the body_entered transition, so we re-check via overlap.
	call_deferred("_check_already_inside")


func _process(_delta: float) -> void:
	if active and is_instance_valid(_line) and is_instance_valid(_player) and is_instance_valid(_target):
		_line.points = PackedVector2Array([_player.global_position, _target.global_position])


func _on_target_activated() -> void:
	print("[EvacuationEvent] interactable_activated:", event_name, " active=", active, " completed=", _completed)
	if not active:
		return
	if _completed:
		_announce(already_message, sender)
		return
	_completed = true
	if task_id != "":
		var tm: Node = get_tree().root.get_node_or_null("TaskManager")
		if tm:
			tm.complete(task_id)
	_announce(success_message, sender)
	succeeded.emit(self)
	_clear_path()


func _check_already_inside() -> void:
	if _target == null or _completed or not active:
		return
	for body in _target.get_overlapping_bodies():
		if body.is_in_group(&"player"):
			_on_target_activated()
			return


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
	_line = Line2D.new()
	_line.default_color = path_color
	_line.width = path_width
	_line.z_index = 10
	get_tree().current_scene.add_child(_line)


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
