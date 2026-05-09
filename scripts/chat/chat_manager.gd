class_name ChatManagerClass
extends Node

## Receives `send_message` and forwards each message to every UI that
## registered itself via `register_ui`. Other code emits the signal
## (or calls `send`) — the manager doesn't care about the producer.
##
## Designed to be used as an autoload (singleton named "ChatManager"):
##   ChatManager.send_message.emit("Hello", "Alice")
##   ChatManager.send("Hello")  # sender omitted

signal send_message(text: String, sender: String)

const MAX_HISTORY: int = 200

var history: Array[Dictionary] = []
var _uis: Array = []

func _ready() -> void:
	send_message.connect(_on_send_message)


## Emit a message via the public signal. Convenience wrapper.
func send(text: String, sender: String = "") -> void:
	send_message.emit(text, sender)


## A ChatUI calls this in its _ready so messages get routed to it.
## Past history is replayed so late-spawning UIs aren't empty.
func register_ui(ui: Node) -> void:
	if ui == null or _uis.has(ui):
		return
	_uis.append(ui)
	ui.tree_exited.connect(_on_ui_freed.bind(ui))
	if ui.has_method("add_message"):
		for entry in history:
			ui.add_message(entry.text, entry.sender)


func unregister_ui(ui: Node) -> void:
	_uis.erase(ui)


func clear_history() -> void:
	history.clear()
	for ui in _uis:
		if ui.has_method("clear_messages"):
			ui.clear_messages()


func _on_send_message(text: String, sender: String) -> void:
	history.append({"text": text, "sender": sender})
	if history.size() > MAX_HISTORY:
		history.pop_front()
	for ui in _uis:
		if ui.has_method("add_message"):
			ui.add_message(text, sender)


func _on_ui_freed(ui: Node) -> void:
	unregister_ui(ui)
