extends Node

const LEVEL_PATHS = [
	"res://scenes/builds/rooms/lycium1floor.tscn",
	"res://scenes/builds/rooms/lycium2floor.tscn",
	"res://scenes/builds/rooms/lycium3floor.tscn",
    "res://scenes/builds/rooms/lycium4floor.tscn"
]

var current_index: int = -1

func _ready():
	goto_level(0)

func goto_level(index: int) -> void:
	index = clamp(index, 0, LEVEL_PATHS.size() - 1)
	if index == current_index:
		return
	current_index = index
	get_tree().change_scene_to_file(LEVEL_PATHS[index])

func next_level() -> void:
	goto_level(min(current_index + 1, LEVEL_PATHS.size() - 1))

func prev_level() -> void:
	goto_level(max(current_index - 1, 0))
