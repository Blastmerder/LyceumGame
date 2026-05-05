class_name Listener
extends Node

var in_room: bool = false
signal UP(obj)
signal DOWN(obj)

func _ready() -> void:
	var cur: Node = get_parent()
	while cur:
		if cur is Area2D:
			var zone: Area2D = cur
			for child in get_children():
				if not child:
					continue
				var d: int = 0
				if "diraction" in child:
					d = int(child.get("diraction"))
				elif child.has_meta("diraction"):
					d = int(child.get_meta("diraction"))
				match d:
					1:
						zone.connect("interactable_activated", Callable(self, "_up").bind(child))
					-1:
						zone.connect("interactable_activated", Callable(self, "_down").bind(child))
					0:
						zone.connect("interactable_activated", Callable(self, "_toggle").bind(child, true))
						zone.connect("interactable_deactivated", Callable(self, "_toggle").bind(child, false))
			break
		cur = cur.get_parent()

func _up(obj: Node) -> void:
	if in_room:
		UP.emit(obj)

func _down(obj: Node) -> void:
	if in_room:
		DOWN.emit(obj)

func _toggle(obj: Node, state: bool) -> void:
	in_room = state
