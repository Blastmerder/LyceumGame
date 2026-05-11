extends Node

## Stand-alone quest demo. Loads task definitions from a JSON, drops a
## player + two TaskTrigger doors, and accepts the tasks at start so
## walking into the matching trigger completes them. The TaskListUI in
## the corner reflects every state change automatically.

@export var tasks_file: String = "res://diologue/conversations/quest_test_tasks.json"
@export var auto_accept_ids: PackedStringArray = PackedStringArray([
	"go_to_202",
	"go_to_lab",
	"stop_by_locker",
])

func _ready() -> void:
	TaskManager.load_from_file(tasks_file)
	for id in auto_accept_ids:
		TaskManager.accept(id)
	TaskManager.task_completed.connect(_on_task_completed)


func _on_task_completed(task: TaskResource) -> void:
	ChatManager.send("Задача выполнена: %s" % task.title, "Система")
