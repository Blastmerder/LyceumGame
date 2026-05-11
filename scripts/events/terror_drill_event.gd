class_name TerrorDrillEvent
extends EvacuationEvent

## Антитеррор. Все тексты этого учения — здесь.

const SENDER := "Завуч"
const START_TEXT := "Антитеррор: укройся в кабинете 202."
const COMPLETE_TEXT := "Кабинет закрыт изнутри. Молодец."

func _on_drill_started() -> void:
	chat(START_TEXT, SENDER)


func _on_drill_completed() -> void:
	chat(COMPLETE_TEXT, SENDER)
