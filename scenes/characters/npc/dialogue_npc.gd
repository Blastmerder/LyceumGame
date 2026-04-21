class_name DialogueNPC
extends Node2D

const BALLOON_SCENE := preload("res://diologue/game_dialogue_balloon.tscn")

@export_group("Dialogue")
@export var dialogue_resource: DialogueResource
@export var dialogue_start_title: String = "start"
@export var auto_block_player: bool = true

@export_group("Appearance")
@export var sprite_frames: SpriteFrames
@export var idle_animation: StringName = &"idle"
@export var default_flip_h: bool = false

@export_group("Tasks")
@export var offered_task_ids: PackedStringArray = PackedStringArray()
@export var exact_trigger_on_touch: String = ""

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interactable_component: InteractableComponent = $InteractableComponent
@onready var body: StaticBody2D = $StaticBody2D

var _player: Player
var _dialogue_active: bool = false

func _ready() -> void:
	if sprite_frames:
		animated_sprite.sprite_frames = sprite_frames
	animated_sprite.flip_h = default_flip_h
	if sprite_frames and sprite_frames.has_animation(idle_animation):
		animated_sprite.play(idle_animation)
	interactable_component.interactable_activated.connect(_on_interactable_activated)
	interactable_component.interactable_deactivated.connect(_on_interactable_deactivated)

func _find_player() -> Player:
	if _player:
		return _player
	var nodes := get_tree().get_nodes_in_group("player")
	if nodes.size() > 0 and nodes[0] is Player:
		_player = nodes[0]
	return _player

func _on_interactable_activated() -> void:
	if exact_trigger_on_touch != "":
		var tm := _task_manager()
		if tm:
			tm.notify_exact_trigger(exact_trigger_on_touch)
	_start_dialogue()

func _on_interactable_deactivated() -> void:
	pass

func _start_dialogue() -> void:
	if _dialogue_active or dialogue_resource == null:
		return
	var player := _find_player()
	if auto_block_player and player:
		player.player_in_dialogue = true
	_dialogue_active = true
	var balloon: BaseGameDialogueBalloon = BALLOON_SCENE.instantiate()
	get_tree().current_scene.add_child(balloon)
	var extra: Array = [self, {"player": player, "npc": self}]
	balloon.tree_exited.connect(_on_dialogue_closed)
	balloon.start(dialogue_resource, dialogue_start_title, extra)

func _on_dialogue_closed() -> void:
	_dialogue_active = false
	var player := _find_player()
	if auto_block_player and player:
		player.player_in_dialogue = false

func accept_offered_task(task_id: String) -> void:
	if not offered_task_ids.has(task_id):
		push_warning("NPC %s does not offer task %s" % [name, task_id])
		return
	var tm := _task_manager()
	if tm:
		tm.accept(task_id)

func _task_manager() -> Node:
	var root := get_tree().root
	return root.get_node_or_null("TaskManager")
