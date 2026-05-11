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
	fired.emit(self)

func _on_timeout() -> void:
	fired.emit(self)
	if repeats:
		_timer.start()


## Called by EventsContainer when an event is dispatched by name.
## Override in subclasses to perform the actual side-effects.
## Default behaviour: fire immediately so anyone wired to `fired`
## still hears about it.
func trigger(_payload: Dictionary = {}) -> void:
	fire_now()


## Names this GameEvent answers to when EventManager.event_triggered
## fires. EventsContainer registers each returned StringName in its
## dispatch table. Subclasses can return several names if they want
## separate "start" / "complete" / etc. signals to land on the same
## node (the actual name that was triggered is forwarded back via
## payload["event_name"]).
func get_handled_names() -> Array[StringName]:
	var out: Array[StringName] = []
	if event_name != &"":
		out.append(event_name)
	return out
