extends Node

## Demo of ChatManager / ChatUI: typing into the LineEdit and pressing
## Send (or Enter) emits ChatManager.send_message; the ChatUI registered
## in the scene receives the message via the autoload. A timer also
## drops a system message every few seconds so the autoscroll/history
## behaviour is visible without input.

@onready var input: LineEdit = %Input
@onready var send_button: Button = %SendButton
@onready var sender_field: LineEdit = %Sender
@onready var auto_timer: Timer = %AutoTimer

var _auto_count: int = 0

func _ready() -> void:
	send_button.pressed.connect(_on_send_pressed)
	input.text_submitted.connect(_on_input_submitted)
	auto_timer.timeout.connect(_on_auto_tick)
	ChatManager.send("Чат-демо запущено. Жми Enter, чтобы отправить.", "Система")


func _on_send_pressed() -> void:
	_send_current()


func _on_input_submitted(_text: String) -> void:
	_send_current()


func _send_current() -> void:
	var text: String = input.text.strip_edges()
	if text.is_empty():
		return
	ChatManager.send_message.emit(text, sender_field.text.strip_edges())
	input.clear()


func _on_auto_tick() -> void:
	_auto_count += 1
	ChatManager.send("Автосообщение #%d" % _auto_count, "Бот")
