class_name TaskTrigger
extends Area2D

## Drop-in Area2D that resolves a TaskManager task when the player
## walks into it. Three outcomes are supported:
##   COMPLETE — mark the linked task completed (and call
##              notify_exact_trigger for any task wired to trigger_id)
##   FAIL     — mark the linked task failed
##   NOTIFY   — only fire notify_exact_trigger; the task itself isn't
##              directly resolved (used when several triggers can
##              advance the same task)

signal triggered(trigger_id: String)

enum Outcome {
	COMPLETE,
	FAIL,
	NOTIFY,
}

@export var task_id: String
@export var trigger_id: String
@export var player_group: StringName = &"player"
@export var outcome: Outcome = Outcome.COMPLETE
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
		if task_id != "" and auto_accept_task and tm.get_task(task_id) and not tm.get_task(task_id).accepted:
			tm.accept(task_id)
		match outcome:
			Outcome.COMPLETE:
				if task_id != "":
					tm.complete(task_id)
				var key: String = trigger_id if trigger_id != "" else task_id
				if key != "":
					tm.notify_exact_trigger(key)
			Outcome.FAIL:
				if task_id != "":
					tm.fail(task_id)
			Outcome.NOTIFY:
				var notify_key: String = trigger_id if trigger_id != "" else task_id
				if notify_key != "":
					tm.notify_exact_trigger(notify_key)
	triggered.emit(trigger_id if trigger_id != "" else task_id)
	if fire_once:
		monitoring = false
