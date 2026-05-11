class_name TaskTrigger
extends Area2D

## Drop-in Area2D that completes (or notifies progress on) a TaskManager
## task when the player walks into it. Use it for quests like "go to room
## 202": just place the trigger over the door and set the matching id.

signal triggered(trigger_id: String)

@export var task_id: String
@export var trigger_id: String
@export var player_group: StringName = &"player"
## If true the linked task is marked completed directly; otherwise we
## just call notify_exact_trigger so any task wired to `exact_trigger`
## resolves on its own.
@export var complete_directly: bool = false
## Disable monitoring after the first hit so the player can't keep
## re-triggering a one-shot quest.
@export var fire_once: bool = true
@export var auto_accept_task: bool = true

var _fired: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func reset() -> void:
	_fired = false
	monitoring = true


func _on_body_entered(body: Node) -> void:
	if _fired:
		return
	if not body.is_in_group(player_group):
		return
	_fired = true
	var tm: Node = get_tree().root.get_node_or_null("TaskManager")
	if tm:
		if task_id != "":
			if auto_accept_task and tm.get_task(task_id) and not tm.get_task(task_id).accepted:
				tm.accept(task_id)
			if complete_directly and task_id != "":
				tm.complete(task_id)
		var key: String = trigger_id if trigger_id != "" else task_id
		if key != "":
			tm.notify_exact_trigger(key)
	triggered.emit(trigger_id if trigger_id != "" else task_id)
	if fire_once:
		monitoring = false
