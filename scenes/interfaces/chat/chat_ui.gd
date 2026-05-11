class_name ChatUI
extends Control

## Renders a scrollable list of chat lines populated by ChatManager.
## Registers itself with the ChatManager autoload in _ready and is
## removed automatically when freed.

@export var max_lines: int = 100
@export var auto_scroll: bool = true

@onready var _list: VBoxContainer = %MessageList
@onready var _scroll: ScrollContainer = %Scroll

func _ready() -> void:
	var cm: Node = get_tree().root.get_node_or_null("ChatManager")
	if cm and cm.has_method("register_ui"):
		cm.register_ui(self)


func add_message(text: String, sender: String = "") -> void:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = _format(text, sender)
	_list.add_child(label)
	while _list.get_child_count() > max_lines:
		var first := _list.get_child(0)
		_list.remove_child(first)
		first.queue_free()
	if auto_scroll:
		await get_tree().process_frame
		_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)


func clear_messages() -> void:
	for child in _list.get_children():
		child.queue_free()


func _format(text: String, sender: String) -> String:
	if sender.is_empty():
		return text
	return "[b]%s:[/b] %s" % [sender, text]
