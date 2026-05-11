class_name LogEvent
extends GameEvent

## Trivial GameEvent that prints to the console and pushes a line to
## ChatManager when it fires. Useful as a placeholder/demo event or as
## the "TestEvent" that proves the timer + dispatcher pipeline works.

@export var message: String = "Event happened!"
@export var sender: String = "Система"
@export var also_print: bool = true
@export var also_chat: bool = false

func _ready() -> void:
	super._ready()
	fired.connect(_on_self_fired)


func _on_self_fired(_event: GameEvent) -> void:
	if also_print:
		print(message)
	if also_chat:
		var cm: Node = get_tree().root.get_node_or_null("ChatManager")
		if cm:
			cm.send(message, sender)
