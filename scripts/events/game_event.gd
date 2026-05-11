class_name GameEvent
extends Node

## Base class for nodes the EventsContainer dispatches to.
##
## Two phase-specific entry points, NOT a single trigger():
##   on_start(payload)    — invoked when EventManager.event_started is
##                          received for one of `get_start_names()`.
##   on_complete(payload) — invoked when EventManager.event_completed
##                          is received for one of `get_complete_names()`.
##
## Subclasses override either or both. Default `on_start` calls
## `fire_now()` so legacy timer-driven events keep working.

signal fired(event: GameEvent)

## Period (seconds) between firings on the optional internal timer.
@export var period: float = 120.0

## If true, the internal timer keeps firing every period.
@export var repeats: bool = true

## Starts the internal timer automatically in _ready.
@export var autostart: bool = true

## Primary name for this event. Used as both the start name and (when
## `complete_event_name` is empty) the complete name. EventsContainer
## routes EventManager.start_event(event_name) here.
@export var event_name: StringName = &""

## Optional separate name for the completion phase. If left empty the
## complete phase reuses `event_name`. Set this when the start and
## the completion deserve different names on the wire.
@export var complete_event_name: StringName = &""

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
	fired.emit(self)


func _on_timeout() -> void:
	fired.emit(self)
	if repeats:
		_timer.start()


## Names dispatched via EventManager.event_started.
func get_start_names() -> Array[StringName]:
	var out: Array[StringName] = []
	if event_name != &"":
		out.append(event_name)
	return out


## Names dispatched via EventManager.event_completed.
func get_complete_names() -> Array[StringName]:
	var out: Array[StringName] = []
	var name: StringName = complete_event_name if complete_event_name != &"" else event_name
	if name != &"":
		out.append(name)
	return out


## Override for the "start / open / launch" phase.
func on_start(_payload: Dictionary = {}) -> void:
	fire_now()


## Override for the "finish / close / succeed" phase.
func on_complete(_payload: Dictionary = {}) -> void:
	pass
