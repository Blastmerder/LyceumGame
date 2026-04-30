class_name Staircase
extends InteractableComponent

const LADDER_FLOOR_ID: int = -9999

signal staircase_activated(staircase: Staircase)

## Destination floor. Use Staircase.LADDER_FLOOR_ID for stairs that
## lead into the shared between-floors ladder tilemap. Ignored when
## relative_direction != 0 (ladder exit uses relative movement).
@export var target_floor_id: int = LADDER_FLOOR_ID

## Floor id the staircase sits on (for stairs that lead into the ladder).
@export var source_floor_id: int = 0

## For ladder exits: relative floor shift from the ladder's source floor
## (+1 for the upper exit, 0 to return to where we came from, -1 for the
## lower exit). When non-zero, overrides target_floor_id.
@export_range(-3, 3) var relative_direction: int = 0

func _ready() -> void:
	interactable_activated.connect(_on_activated)

func _on_activated() -> void:
	staircase_activated.emit(self)

func leads_to_ladder() -> bool:
	return target_floor_id == LADDER_FLOOR_ID and relative_direction == 0
