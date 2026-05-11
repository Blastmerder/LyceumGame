class_name DroneDrillEvent
extends EvacuationEvent

## Воздушная тревога. Все тексты этого учения — здесь.

const SENDER := "Завуч"
const START_TEXT := "Воздушная тревога: дойди до укрытия!"
const COMPLETE_TEXT := "Молодец, ты в укрытии."

func _on_drill_started() -> void:
	chat(START_TEXT, SENDER)


func _on_drill_completed() -> void:
	chat(COMPLETE_TEXT, SENDER)
