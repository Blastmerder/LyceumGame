class_name Staircase
extends InteractableComponent

const LADDER_FLOOR_ID: int = -9999

signal staircase_entered(target_floor_id: int, source_floor_id: int)

## Target floor to switch to. Use Staircase.LADDER_FLOOR_ID (-9999)
## for stairs that lead into the shared between-floors ladder tilemap.
@export var target_floor_id: int = LADDER_FLOOR_ID

## Floor id the staircase belongs to. Only meaningful for stairs that
## sit on a normal floor (ladder exits can leave it at 0).
@export var source_floor_id: int = 0

func _ready() -> void:
	interactable_activated.connect(_on_activated)

func _on_activated() -> void:
	staircase_entered.emit(target_floor_id, source_floor_id)
