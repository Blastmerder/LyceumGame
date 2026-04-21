extends Node2D

const GROUP := "tile_container_collision"
const PHYSICS_GROUP := "physics_layer"

@onready var tile_map_layer: TileMapLayer = $TileMapLayer


@export var collision_enabled: bool = true:
	set (value):
		collision_enabled = value
		if is_node_ready():
			_apply_collision(value)
	get:
		return collision_enabled


func _ready() -> void:
	y_sort_enabled = true
	for child in get_children():
		if child is TileMapLayer:
			child.y_sort_enabled = true
			if _layer_has_physics(child):
				child.add_to_group(PHYSICS_GROUP)
	_apply_collision(collision_enabled)


func _apply_collision(enabled: bool) -> void:
	for child in get_children():
		if child is TileMapLayer:
			child.collision_enabled = enabled


func _layer_has_physics(layer: TileMapLayer) -> bool:
	var ts := layer.tile_set
	if ts == null:
		return false
	return ts.get_physics_layers_count() > 0
