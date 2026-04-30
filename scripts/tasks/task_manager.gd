class_name TaskManagerClass
extends Node

signal task_registered(task: TaskResource)
signal task_accepted(task: TaskResource)
signal task_completed(task: TaskResource)
signal task_state_changed(task: TaskResource)

var tasks: Dictionary = {}

func register(task: TaskResource) -> void:
	if task == null or task.id.is_empty():
		return
	tasks[task.id] = task
	task_registered.emit(task)

func register_raw(id: String, title: String, description: String, fuzzy: bool, exact_trigger: String = "") -> TaskResource:
	var t := TaskResource.new()
	t.id = id
	t.title = title
	t.description = description
	t.kind = TaskResource.Kind.FUZZY if fuzzy else TaskResource.Kind.EXACT
	t.exact_trigger = exact_trigger
	register(t)
	return t

func load_from_file(path: String) -> Array[TaskResource]:
	var result: Array[TaskResource] = []
	if not FileAccess.file_exists(path):
		push_warning("TaskManager: file not found: %s" % path)
		return result
	var content := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(content)
	if typeof(parsed) != TYPE_ARRAY:
		push_warning("TaskManager: expected array in %s" % path)
		return result
	for entry in parsed:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var fuzzy: bool = bool(entry.get("fuzzy", true))
		var task := register_raw(
			String(entry.get("id", "")),
			String(entry.get("title", "")),
			String(entry.get("description", "")),
			fuzzy,
			String(entry.get("exact_trigger", ""))
		)
		if task != null:
			result.append(task)
	return result

func get_task(id: String) -> TaskResource:
	return tasks.get(id)

func accept(id: String) -> void:
	var task: TaskResource = get_task(id)
	if task == null or task.accepted:
		return
	task.accepted = true
	task_accepted.emit(task)
	task_state_changed.emit(task)

func complete(id: String) -> void:
	var task: TaskResource = get_task(id)
	if task == null or task.completed:
		return
	task.completed = true
	task_completed.emit(task)
	task_state_changed.emit(task)

func set_completed(id: String, value: bool) -> void:
	var task: TaskResource = get_task(id)
	if task == null:
		return
	if task.completed == value:
		return
	task.completed = value
	if value:
		task_completed.emit(task)
	task_state_changed.emit(task)

func notify_exact_trigger(trigger_id: String) -> void:
	for task in tasks.values():
		if task.is_exact() and task.accepted and not task.completed and task.exact_trigger == trigger_id:
			complete(task.id)

func accepted_tasks() -> Array:
	var out: Array = []
	for task in tasks.values():
		if task.accepted:
			out.append(task)
	return out
