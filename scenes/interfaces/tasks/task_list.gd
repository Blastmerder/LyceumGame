class_name TaskListUI
extends Control

@export var toggle_action: StringName = &"task_list"

@onready var exact_list: VBoxContainer = %ExactList
@onready var fuzzy_list: VBoxContainer = %FuzzyList
@onready var empty_label: Label = %EmptyLabel

var _rows: Dictionary = {}

func _ready() -> void:
	visible = false
	var tm := _task_manager()
	if tm == null:
		return
	tm.task_accepted.connect(_on_task_accepted)
	tm.task_state_changed.connect(_on_task_state_changed)
	for task in tm.accepted_tasks():
		_add_row(task)
	_update_empty()

func _unhandled_input(event: InputEvent) -> void:
	if InputMap.has_action(toggle_action) and event.is_action_pressed(toggle_action):
		visible = not visible
		get_viewport().set_input_as_handled()

func _on_task_accepted(task: TaskResource) -> void:
	_add_row(task)
	_update_empty()

func _on_task_state_changed(task: TaskResource) -> void:
	if not _rows.has(task.id):
		return
	var row: Dictionary = _rows[task.id]
	var cb: CheckBox = row["checkbox"]
	if cb.button_pressed != task.completed:
		cb.set_pressed_no_signal(task.completed)

func _add_row(task: TaskResource) -> void:
	if _rows.has(task.id):
		return
	var list: VBoxContainer = fuzzy_list if task.is_fuzzy() else exact_list
	var cb := CheckBox.new()
	cb.text = task.title
	cb.tooltip_text = task.description
	cb.button_pressed = task.completed
	if task.is_exact():
		cb.disabled = true
	cb.toggled.connect(_on_row_toggled.bind(task.id))
	list.add_child(cb)
	_rows[task.id] = {"checkbox": cb}

func _on_row_toggled(pressed: bool, task_id: String) -> void:
	var tm := _task_manager()
	if tm == null:
		return
	tm.set_completed(task_id, pressed)

func _update_empty() -> void:
	empty_label.visible = exact_list.get_child_count() == 0 and fuzzy_list.get_child_count() == 0

func _task_manager() -> Node:
	return get_tree().root.get_node_or_null("TaskManager")
