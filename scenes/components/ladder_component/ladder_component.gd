class_name LadderComponent
extends Area2D

signal ladder_activated

@export var direction: int

func _on_body_entered(_body: Node2D) -> void:
	ladder_activated.emit(direction)
