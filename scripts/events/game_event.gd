class_name GameEvent
extends Node

signal fired(event: GameEvent)

## Period (seconds) between firings.
@export var period: float = 120.0

## If true, keeps firing every period. If false, fires once.
@export var repeats: bool = true

## Starts the timer automatically in _ready.
@export var autostart: bool = true

## Optional identifier for listeners to dispatch on.
@export var event_name: StringName = &""

var _timer: Timer

func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = max(period, 0.01)
	_timer.one_shot = not repeats
	_timer.autostart = false
	add_child(_timer)
	_timer.timeout.connect(_on_timeout)
	if autostart:
		start()

func start() -> void:
	if _timer:
		_timer.wait_time = max(period, 0.01)
		_timer.one_shot = not repeats
		_timer.start()

func stop() -> void:
	if _timer:
		_timer.stop()

func fire_now() -> void:
	_emit_fired()

func _on_timeout() -> void:
	_emit_fired()
	if repeats:
		_timer.start()

func _emit_fired() -> void:
	fired.emit(self)
