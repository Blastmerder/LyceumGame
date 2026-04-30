extends Node2D

const GROUP := "tile_container_collision"

@onready var tile_map_layer: TileMapLayer = $TileMapLayer


@export var collision_enabled: bool = true:
	set (value):
		collision_enabled = value
		if is_node_ready():
			_apply_collision(value)
	get:
		return collision_enabled


func _ready() -> void:
	_apply_collision(collision_enabled)


func _apply_collision(enabled: bool) -> void:
	for child in get_children():
		if child is TileMapLayer:
			child.collision_enabled = enabled
