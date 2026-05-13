class_name ChatUI
extends Control

## Renders a scrollable list of chat lines populated by ChatManager.
## Registers itself with the ChatManager autoload in _ready and is
## removed automatically when freed.
##
## Implements the idle protocol used by Player.idle_target_path:
##   on_idle_enable  -> fade out
##   on_idle_disable -> fade in

@export var max_lines: int = 100
@export var auto_scroll: bool = true
@export var message_font_size: int = 7
@export var fade_out_duration: float = 0.6
@export var fade_in_duration: float = 0.3

@onready var _list: VBoxContainer = %MessageList
@onready var _scroll: ScrollContainer = %Scroll

var _fade_tween: Tween

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
	label.add_theme_font_size_override("normal_font_size", message_font_size)
	label.add_theme_font_size_override("bold_font_size", message_font_size)
	label.add_theme_font_size_override("italics_font_size", message_font_size)
	label.add_theme_font_size_override("bold_italics_font_size", message_font_size)
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


func on_idle_enable() -> void:
	_fade_to(0.0, fade_out_duration)


func on_idle_disable() -> void:
	_fade_to(1.0, fade_in_duration)


func _fade_to(alpha: float, duration: float) -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", alpha, duration)


func _format(text: String, sender: String) -> String:
	if sender.is_empty():
		return text
	return "[b]%s:[/b] %s" % [sender, text]
