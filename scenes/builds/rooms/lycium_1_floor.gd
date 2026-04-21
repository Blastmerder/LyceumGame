extends Node2D

const GROUP := "tile_container_collision"
@onready var tile_map_layer: TileMapLayer = $TileMapLayer


@export var collision_enabled: bool = true:
	set (value):
		collision_enabled = value
		tile_map_layer.collision_enabled = collision_enabled
	get:
		return collision_enabled
