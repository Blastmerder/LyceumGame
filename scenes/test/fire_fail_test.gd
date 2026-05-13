extends Node

## Demo for FailZoneManager + drill_fire. The Start button kicks off
## the fire drill via EventManager.start_event. The FailZoneManager
## under FailZones picks one of its TaskTrigger children to be the
## live "danger" zone — only entering THAT one fails the task. The
## CompleteZone is a normal TaskTrigger that completes the drill.

@onready var start_button: Button = %StartButton

func _ready() -> void:
	start_button.pressed.connect(_on_start)
	TaskManager.task_failed.connect(_on_failed)
	TaskManager.task_completed.connect(_on_completed)


func _on_start() -> void:
	print("[FireFailTest] start_event: drill_fire")
	EventManager.start_event("drill_fire")


func _on_failed(task: TaskResource) -> void:
	ChatManager.send("Провалена: %s" % task.title, "Система")


func _on_completed(task: TaskResource) -> void:
	ChatManager.send("Выполнена: %s" % task.title, "Система")
