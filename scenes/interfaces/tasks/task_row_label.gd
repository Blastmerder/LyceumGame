class_name TaskRowLabel
extends RichTextLabel

## RichTextLabel with a shrunken custom tooltip. The built-in tooltip
## uses the project's default theme; this override renders the
## description through a hand-made Label with our own font size so
## tooltips don't dwarf the (already tiny) task list font.

@export var tooltip_font_size: int = 6
@export var tooltip_max_width: float = 160.0

func _make_custom_tooltip(for_text: String) -> Object:
	var label := Label.new()
	label.text = for_text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(tooltip_max_width, 0)
	label.add_theme_font_size_override("font_size", tooltip_font_size)
	return label
