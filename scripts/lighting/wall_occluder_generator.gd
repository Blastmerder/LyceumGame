class_name WallOccluderGenerator
extends Node

## Walks the given root, finds every TileMapLayer, and instantiates a
## LightOccluder2D child for each cell whose tile has a collision
## polygon on physics_layer 0. This lets a PointLight2D cast shadows
## from wall tiles without having to pre-author an occlusion layer in
## the TileSet. Walls stay visible because the ambient CanvasModulate
## still tints them; only the light does not reach past them.

@export var target: Node
@export var occluder_light_mask: int = 1
@export var generate_on_ready: bool = true

func _ready() -> void:
	if generate_on_ready:
		var root: Node = target if target != null else get_parent()
		generate(root)

func generate(root: Node) -> void:
	if root == null:
		return
	for layer in _collect_layers(root):
		_process_layer(layer)

func _collect_layers(root: Node) -> Array[TileMapLayer]:
	var out: Array[TileMapLayer] = []
	if root is TileMapLayer:
		out.append(root)
	for child in root.get_children():
		out.append_array(_collect_layers(child))
	return out

func _process_layer(layer: TileMapLayer) -> void:
	if layer.tile_set == null or layer.tile_set.get_physics_layers_count() == 0:
		return
	for cell in layer.get_used_cells():
		var td: TileData = layer.get_cell_tile_data(cell)
		if td == null:
			continue
		var polys: int = td.get_collision_polygons_count(0)
		if polys == 0:
			continue
		for i in range(polys):
			var points: PackedVector2Array = td.get_collision_polygon_points(0, i)
			if points.size() < 3:
				continue
			var occ := LightOccluder2D.new()
			occ.light_mask = occluder_light_mask
			var polygon := OccluderPolygon2D.new()
			polygon.polygon = points
			polygon.closed = true
			occ.occluder = polygon
			occ.position = layer.map_to_local(cell)
			layer.add_child(occ)
