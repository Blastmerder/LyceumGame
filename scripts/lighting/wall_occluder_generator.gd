class_name WallOccluderGenerator
extends Node

## Walks the given root, finds every TileMapLayer, and instantiates a
## LightOccluder2D child for each cell whose tile has a collision
## polygon on physics_layer 0. This lets a PointLight2D cast shadows
## from wall tiles without having to pre-author an occlusion layer in
## the TileSet.
##
## The occluder polygon is shrunk inward by `polygon_inset` pixels so
## the lit face of the wall tile remains illuminated by the light.
## Without this, the occluder and the tile cover the exact same area,
## so the tile ends up inside its own shadow and stays dark even when
## the light is right next to it. Ambient CanvasModulate still fills
## the rest.

@export var target: Node
@export var occluder_light_mask: int = 1
@export var polygon_inset: float = 2.5
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
			var shrunk: PackedVector2Array = _inset_polygon(points, polygon_inset)
			if shrunk.size() < 3:
				continue
			var occ := LightOccluder2D.new()
			occ.light_mask = occluder_light_mask
			var polygon := OccluderPolygon2D.new()
			polygon.polygon = shrunk
			polygon.closed = true
			occ.occluder = polygon
			occ.position = layer.map_to_local(cell)
			layer.add_child(occ)

func _inset_polygon(points: PackedVector2Array, inset: float) -> PackedVector2Array:
	if inset <= 0.0:
		return points
	var center := Vector2.ZERO
	for p in points:
		center += p
	center /= float(points.size())
	var out: PackedVector2Array = PackedVector2Array()
	out.resize(points.size())
	for i in points.size():
		var dir: Vector2 = points[i] - center
		var dist: float = dir.length()
		if dist <= inset:
			out[i] = points[i]
		else:
			out[i] = points[i] - dir.normalized() * inset
	return out
