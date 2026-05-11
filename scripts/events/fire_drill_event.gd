class_name FireDrillEvent
extends EvacuationEvent

## Пожарная тревога. Все тексты этого учения — здесь.

const SENDER := "Завуч"
const START_TEXT := "Пожарная тревога: эвакуируйся."
const COMPLETE_TEXT := "Эвакуация выполнена."

func _on_drill_started() -> void:
	chat(START_TEXT, SENDER)


func _on_drill_completed() -> void:
	chat(COMPLETE_TEXT, SENDER)
