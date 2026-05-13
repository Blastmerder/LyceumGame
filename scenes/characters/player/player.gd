extends CharacterBody2D
class_name Player

## Signals fired by the state machine: `idle_enable` after the
## IdleTimer expires (player hasn't moved for its wait_time), and
## `idle_disable` whenever movement resumes. They're connected in
## _ready to `on_idle_enable` / `on_idle_disable` on the node pointed
## to by `idle_target_path` if the target exposes those methods.

signal idle_enable
signal idle_disable

## NodePath chosen in the inspector when the player is dropped into a
## scene — typically the UI that should fade out while AFK.
@export var idle_target_path: NodePath

var player_direction: Vector2
var player_in_dialogue: bool = false

@onready var idle_timer: Timer = $IdleTimer


func _ready() -> void:
	add_to_group("player")
	if idle_timer and not idle_timer.timeout.is_connected(_on_idle_timeout):
		idle_timer.timeout.connect(_on_idle_timeout)
	var target: Node = get_node_or_null(idle_target_path)
	if target == null:
		return
	if target.has_method("on_idle_enable"):
		idle_enable.connect(Callable(target, "on_idle_enable"))
	if target.has_method("on_idle_disable"):
		idle_disable.connect(Callable(target, "on_idle_disable"))


func _on_idle_timeout() -> void:
	idle_enable.emit()
