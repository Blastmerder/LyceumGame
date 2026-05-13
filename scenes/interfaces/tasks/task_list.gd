class_name TaskListUI
extends Control

## Lists accepted tasks. Honours the Player idle protocol:
##   on_idle_enable  -> fade out
##   on_idle_disable -> fade in
## …so it can be parked under the same UI container as ChatUI and
## both fade together when the player is AFK.

@export var toggle_action: StringName = &"task_list"
## When true the panel hides itself in _ready and the toggle action
## brings it back. Set to false on test/demo scenes that should always
## show the list.
@export var start_hidden: bool = true
## Font size applied to dynamically created CheckBox rows. Matches the
## downscaled ChatUI font (~2.3x smaller than Godot's default 16).
@export var row_font_size: int = 7
@export var fade_out_duration: float = 0.6
@export var fade_in_duration: float = 0.3

@onready var exact_list: VBoxContainer = %ExactList
@onready var fuzzy_list: VBoxContainer = %FuzzyList
@onready var empty_label: Label = %EmptyLabel

var _rows: Dictionary = {}
var _fade_tween: Tween

func _ready() -> void:
	visible = not start_hidden
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


func on_idle_enable() -> void:
	_fade_to(0.0, fade_out_duration)


func on_idle_disable() -> void:
	_fade_to(1.0, fade_in_duration)


func _fade_to(alpha: float, duration: float) -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", alpha, duration)


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
	cb.add_theme_font_size_override("font_size", row_font_size)
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
