extends CharacterBody2D
class_name Player

var player_direction: Vector2
var player_in_dialogue: bool = false

func _ready() -> void:
	add_to_group("player")
