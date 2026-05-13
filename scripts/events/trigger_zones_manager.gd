class_name TriggerZonesManager
extends Node

## Standalone Node that picks one of its Area2D children to be the
## "live" trigger for a named event. Completely independent of the
## GameEvent that owns the actual logic — both subscribe to
## EventManager.event_signal on their own, so the same payload that
## starts the event also tells this manager to roll a new active
## zone.
##
## The picked zone's id (the child's node name) is also stashed in
## EventManager.active_zones[event_name]. When the manager wakes up
## on a freshly loaded scene it reads that registry — if a child
## matches the saved id it is re-enabled instead of rolling a brand
## new pick. This is what makes the random fire zone "survive"
## switching floors in Main.tscn.
##
## Rules:
##   payload.name != event_name  -> ignored
##   payload.type == "start"     -> disable every child, pick a
##                                  random Area2D (excluding any
##                                  zone the player is currently
##                                  standing on), enable just that
##                                  one, announce via ChatManager
##                                  and write the id to EventManager.
##   payload.type == "trigger_zone" -> disable every child and clear
##                                     the EventManager registry (the
##                                     run is over either way).

@export var event_name: String = ""
## Chat sender for the active-zone announcement.
@export var sender: String = "Менеджер тревоги"
## Goes through `% area.name` — leave the %s in place.
@export var announce_template: String = "Активна зона: %s"
## Toggles visibility together with monitoring. When true (default),
## every zone's CanvasItem.visible follows its active state — so the
## fire / drone / etc. textures attached to a zone disappear while
## the event isn't running and reappear only on the chosen zone.
## CanvasItem visibility cascades to children, so any Sprite2D /
## Label / ColorRect dropped under a zone fades with it.
@export var show_active: bool = true
## How long the visibility transition takes (seconds). 0 = instant
## toggle. Any positive value tweens modulate.a on the zone so
## children fade in / out instead of popping.
@export var fade_duration: float = 0.0
## Pixels: zones closer to the player than this are excluded from the
## random pick so we never spawn the danger right under the feet.
@export var min_player_distance: float = 80.0
## Group used to locate the player on the active scene.
@export var player_group: StringName = &"player"


var _fade_tweens: Dictionary = {}


func _ready() -> void:
	var em: Node = get_tree().root.get_node_or_null("EventManager")
	if em == null:
		push_warning("TriggerZonesManager: EventManager autoload not found")
		return
	em.event_signal.connect(_on_event_signal)
	_disable_all_zones()
	_restore_active_zone()


func _on_event_signal(payload: Dictionary) -> void:
	if String(payload.get("name", "")) != event_name:
		return
	var msg_type: String = String(payload.get("type", ""))
	match msg_type:
		"start":
			_pick_random()
		"trigger_zone":
			_resolve_run()


func _pick_random() -> void:
	_disable_all_zones()
	var pool: Array[Area2D] = _candidate_areas()
	if pool.is_empty():
		print("[TriggerZonesManager] %s: no eligible Area2D children" % event_name)
		return
	var chosen: Area2D = pool[randi() % pool.size()]
	_set_active(chosen)


func _resolve_run() -> void:
	_disable_all_zones()
	var em: Node = get_tree().root.get_node_or_null("EventManager")
	if em and em.has_method("clear_active_zone"):
		em.clear_active_zone(event_name)


## On scene load, re-enable the zone that was picked before this
## scene was instanced — keeps the random pick stable across floor
## swaps in Main.tscn.
func _restore_active_zone() -> void:
	var em: Node = get_tree().root.get_node_or_null("EventManager")
	if em == null or not em.has_method("get_active_zone"):
		return
	var saved_id: String = em.get_active_zone(event_name)
	if saved_id == "":
		return
	for a in _areas():
		if String(a.name) == saved_id:
			_apply_enabled(a, true)
			print("[TriggerZonesManager] %s restored active zone: %s" % [event_name, saved_id])
			return


func _set_active(area: Area2D) -> void:
	_apply_enabled(area, true)
	var em: Node = get_tree().root.get_node_or_null("EventManager")
	if em and em.has_method("set_active_zone"):
		em.set_active_zone(event_name, String(area.name))
	print("[TriggerZonesManager] %s -> active zone: %s" % [event_name, area.name])
	var cm: Node = get_tree().root.get_node_or_null("ChatManager")
	if cm and announce_template != "":
		cm.send(announce_template % area.name, sender)


func _disable_all_zones() -> void:
	for a in _areas():
		_apply_enabled(a, false)


func _apply_enabled(area: Area2D, enabled: bool) -> void:
	area.monitoring = enabled
	if not show_active:
		return
	# Stop any in-flight fade for this zone so toggles don't stack.
	var prev: Tween = _fade_tweens.get(area)
	if prev and prev.is_valid():
		prev.kill()
		_fade_tweens.erase(area)
	if fade_duration <= 0.0:
		area.visible = enabled
		area.modulate.a = 1.0 if enabled else 0.0
		return
	# Tweened transition. visible has to flip on before the fade-in
	# (otherwise the children stay culled); for the fade-out we wait
	# until the tween ends, then hide.
	if enabled:
		area.visible = true
		var tw_in := area.create_tween()
		tw_in.tween_property(area, "modulate:a", 1.0, fade_duration)
		_fade_tweens[area] = tw_in
	else:
		var tw_out := area.create_tween()
		tw_out.tween_property(area, "modulate:a", 0.0, fade_duration)
		tw_out.tween_callback(func(): area.visible = false)
		_fade_tweens[area] = tw_out


func _areas() -> Array[Area2D]:
	var out: Array[Area2D] = []
	for c in get_children():
		if c is Area2D:
			out.append(c)
	return out


## Filter zones too close to the player. If every zone is within the
## threshold (cramped floor, lots of overlap), fall back to the full
## list so the event doesn't silently produce nothing.
func _candidate_areas() -> Array[Area2D]:
	var areas: Array[Area2D] = _areas()
	var player: Node2D = _find_player()
	if player == null or min_player_distance <= 0.0:
		return areas
	var out: Array[Area2D] = []
	for a in areas:
		if a.global_position.distance_to(player.global_position) >= min_player_distance:
			out.append(a)
	if out.is_empty():
		return areas
	return out


func _find_player() -> Node2D:
	for n in get_tree().get_nodes_in_group(player_group):
		if n is Node2D:
			return n
	return null
