extends Node

## Demo for task failure: loads two tasks, auto-accepts them, and lets
## the player walk into either a "good" or a "bad" door. The bad door
## is a TaskTrigger with outcome = FAIL, so entering it marks the
## delivery task as failed (cross icon, strikethrough text, red flash,
## auto-remove after `remove_delay`). The good door completes it.

@export var tasks_file: String = "res://diologue/conversations/task_fail_tasks.json"
@export var auto_accept_ids: PackedStringArray = PackedStringArray([
	"deliver_paper",
	"stay_in_class",
])

func _ready() -> void:
	TaskManager.load_from_file(tasks_file)
	for id in auto_accept_ids:
		TaskManager.accept(id)
	TaskManager.task_completed.connect(_on_completed)
	TaskManager.task_failed.connect(_on_failed)


func _on_completed(task: TaskResource) -> void:
	ChatManager.send("Задача выполнена: %s" % task.title, "Система")


func _on_failed(task: TaskResource) -> void:
	ChatManager.send("Провалена: %s" % task.title, "Система")
