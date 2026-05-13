extends CharacterBody2D
class_name Player

## Signals fired by the state machine: `idle_enable` after the
## IdleTimer expires (player hasn't moved for its wait_time), and
## `idle_disable` whenever movement resumes. They are routed in _ready
## to every *child* of the node pointed to by `idle_target_path` —
## typically a CanvasLayer / UI container — so every Control under it
## that implements `on_idle_enable` / `on_idle_disable` fades together.

signal idle_enable
signal idle_disable

## NodePath chosen in the inspector when the player is dropped into a
## scene. The TARGETED node's direct children receive the signals;
## the targeted node itself is not subscribed.
@export var idle_target_path: NodePath

var player_direction: Vector2
var player_in_dialogue: bool = false

@onready var idle_timer: Timer = $IdleTimer


func _ready() -> void:
	add_to_group("player")
	if idle_timer and not idle_timer.timeout.is_connected(_on_idle_timeout):
		idle_timer.timeout.connect(_on_idle_timeout)
	var root: Node = get_node_or_null(idle_target_path)
	if root == null:
		return
	for child in root.get_children():
		_connect_child(child)
	# Pick up UI nodes that arrive later (instanced at runtime, etc.)
	root.child_entered_tree.connect(_connect_child)


func _connect_child(child: Node) -> void:
	if child.has_method("on_idle_enable"):
		var enable_callable := Callable(child, "on_idle_enable")
		if not idle_enable.is_connected(enable_callable):
			idle_enable.connect(enable_callable)
	if child.has_method("on_idle_disable"):
		var disable_callable := Callable(child, "on_idle_disable")
		if not idle_disable.is_connected(disable_callable):
			idle_disable.connect(disable_callable)


func _on_idle_timeout() -> void:
	idle_enable.emit()
