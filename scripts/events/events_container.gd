class_name EventsContainer
extends Node

## Container for GameEvent children. Connects to each child's fired
## signal and dispatches to the overridable handler. Also listens to
## the EventManager autoload so dialogues / other code can ask for
## specific named events to fire.

@export_node_path("AudioStreamPlayer") var audio_player_path: NodePath
@export_node_path("GameEvent") var test_event_path: NodePath

var _audio_player: AudioStreamPlayer
var _events_by_name: Dictionary = {}

func _ready() -> void:
	_audio_player = get_node_or_null(audio_player_path)
	for child in get_children():
		if child is GameEvent:
			child.fired.connect(_handle_event)
			if child.event_name != &"":
				_events_by_name[child.event_name] = child
	var em: Node = get_tree().root.get_node_or_null("EventManager")
	if em:
		em.event_triggered.connect(_on_manager_event)


func _handle_event(event: GameEvent) -> void:
	match event.event_name:
		&"test_event":
			print("Event happened!")
		_:
			pass


func _on_manager_event(event_name: String, _payload: Dictionary) -> void:
	if event_name == "npc_test":
		_trigger_npc_test()


func _trigger_npc_test() -> void:
	if _audio_player and _audio_player.stream:
		_audio_player.play()
	var target: Node = get_node_or_null(test_event_path)
	if target is GameEvent:
		target.start()
