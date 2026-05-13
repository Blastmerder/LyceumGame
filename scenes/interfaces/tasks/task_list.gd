class_name TaskListUI
extends Control

## Renders a single flat list of accepted tasks (no categories). Each
## row is an HBox containing a click-able icon Button (used as the
## checkbox for fuzzy tasks) and a RichTextLabel for the title. When
## a task completes, the row briefly flashes green; when it fails,
## the icon switches to ✕, the title is wrapped in [s]…[/s] and the
## row flashes red. Either resolution schedules the row to be removed
## after `remove_delay` seconds.
##
## Implements the Player idle protocol: on_idle_enable fades the
## panel out, on_idle_disable fades it back in.

@export var toggle_action: StringName = &"task_list"
@export var start_hidden: bool = true
@export var row_font_size: int = 7
@export var remove_delay: float = 7.0
@export var success_color: Color = Color(0.45, 1.0, 0.55, 1.0)
@export var fail_color: Color = Color(1.0, 0.45, 0.45, 1.0)
@export var flash_duration: float = 0.4
@export var fade_out_duration: float = 0.6
@export var fade_in_duration: float = 0.3

const ICON_PENDING := "☐"
const ICON_DONE := "✔"
const ICON_FAILED := "✕"

@onready var task_list: VBoxContainer = %TaskList
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
	if tm.has_signal("task_failed"):
		tm.task_failed.connect(_on_task_state_changed)
	for task in tm.accepted_tasks():
		_add_row(task)
	_update_empty()


func _unhandled_input(event: InputEvent) -> void:
	if InputMap.has_action(toggle_action) and event.is_action_pressed(toggle_action):
		visible = not visible
		get_viewport().set_input_as_handled()


func on_idle_enable() -> void:
	_fade_panel_to(0.0, fade_out_duration)


func on_idle_disable() -> void:
	_fade_panel_to(1.0, fade_in_duration)


func _fade_panel_to(alpha: float, duration: float) -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", alpha, duration)


func _on_task_accepted(task: TaskResource) -> void:
	# If a row already exists (re-running a drill, for example), drop
	# the resolved leftover immediately so the new run gets a fresh
	# pending row without waiting for the auto-removal timer.
	if _rows.has(task.id):
		_remove_row_now(task.id)
	_add_row(task)
	_update_empty()


func _on_task_state_changed(task: TaskResource) -> void:
	if not _rows.has(task.id):
		return
	_refresh_row(task)
	if task.is_resolved():
		_flash_row(task)
		_schedule_removal(task.id)


func _add_row(task: TaskResource) -> void:
	if _rows.has(task.id):
		return
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var icon := Button.new()
	icon.flat = true
	icon.focus_mode = Control.FOCUS_NONE
	icon.custom_minimum_size = Vector2(14, 0)
	icon.add_theme_font_size_override("font_size", row_font_size)

	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.tooltip_text = task.description
	for k in [&"normal_font_size", &"bold_font_size", &"italics_font_size", &"bold_italics_font_size"]:
		label.add_theme_font_size_override(k, row_font_size)

	row.add_child(icon)
	row.add_child(label)
	task_list.add_child(row)

	if task.is_fuzzy():
		icon.pressed.connect(_on_row_icon_pressed.bind(task.id))
	else:
		icon.disabled = true

	_rows[task.id] = {
		"row": row,
		"icon": icon,
		"label": label,
		"timer": null,
		"flash_tween": null,
	}
	_refresh_row(task)


func _refresh_row(task: TaskResource) -> void:
	var entry: Dictionary = _rows.get(task.id, {})
	if entry.is_empty():
		return
	var icon: Button = entry.icon
	var label: RichTextLabel = entry.label
	if task.failed:
		icon.text = ICON_FAILED
		icon.disabled = true
		label.text = "[s]%s[/s]" % task.title
	elif task.completed:
		icon.text = ICON_DONE
		icon.disabled = true
		label.text = task.title
	else:
		icon.text = ICON_PENDING
		label.text = task.title


func _flash_row(task: TaskResource) -> void:
	var entry: Dictionary = _rows.get(task.id, {})
	if entry.is_empty():
		return
	var row: HBoxContainer = entry.row
	var prev: Tween = entry.flash_tween
	if prev and prev.is_valid():
		prev.kill()
	var target_color: Color = fail_color if task.failed else success_color
	row.modulate = target_color * 1.4
	row.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(row, "modulate", target_color, flash_duration)
	entry.flash_tween = tw
	_rows[task.id] = entry


func _schedule_removal(task_id: String) -> void:
	var entry: Dictionary = _rows.get(task_id, {})
	if entry.is_empty():
		return
	var existing: Timer = entry.timer
	if existing and is_instance_valid(existing):
		return
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = max(remove_delay, 0.1)
	add_child(timer)
	timer.timeout.connect(_remove_row.bind(task_id))
	timer.start()
	entry.timer = timer
	_rows[task_id] = entry


func _remove_row(task_id: String) -> void:
	var entry: Dictionary = _rows.get(task_id, {})
	if entry.is_empty():
		return
	var row: HBoxContainer = entry.row
	if is_instance_valid(row):
		row.queue_free()
	var timer: Timer = entry.timer
	if timer and is_instance_valid(timer):
		timer.queue_free()
	_rows.erase(task_id)
	_update_empty()


## Like _remove_row but frees the row immediately so a new row can
## take its slot in the same frame.
func _remove_row_now(task_id: String) -> void:
	var entry: Dictionary = _rows.get(task_id, {})
	if entry.is_empty():
		return
	var row: HBoxContainer = entry.row
	if is_instance_valid(row):
		row.free()
	var timer: Timer = entry.timer
	if timer and is_instance_valid(timer):
		timer.free()
	_rows.erase(task_id)


func _on_row_icon_pressed(task_id: String) -> void:
	var tm := _task_manager()
	if tm == null:
		return
	var task: TaskResource = tm.get_task(task_id)
	if task == null or task.is_resolved():
		return
	tm.complete(task_id)


func _update_empty() -> void:
	empty_label.visible = task_list.get_child_count() == 0


func _task_manager() -> Node:
	return get_tree().root.get_node_or_null("TaskManager")
