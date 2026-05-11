class_name DialogueNPC
extends Node2D

const BALLOON_SCENE := preload("res://diologue/game_dialogue_balloon.tscn")

enum InteractMode {
	AUTO_ON_TOUCH,
	KEY_PRESS,
}

@export_group("Dialogue")
@export var dialogue_resource: DialogueResource
@export var dialogue_start_title: String = "start"
@export var auto_block_player: bool = true

@export_group("Interaction")
@export var interact_mode: InteractMode = InteractMode.AUTO_ON_TOUCH
@export var interact_action: StringName = &"interact"

@export_group("Appearance")
## Full SpriteFrames if you have one. Wins over idle_texture / spritesheet.
@export var sprite_frames: SpriteFrames
@export var idle_animation: StringName = &"idle"
@export var default_flip_h: bool = false

## Quick path: a plain texture or a full spritesheet. If `spritesheet_hframes`
## or `spritesheet_vframes` are >1 the texture is treated as a grid and
## `spritesheet_frame` picks the cell. Otherwise the whole image is used,
## or, if `idle_region` has a non-zero size, just that region.
@export var idle_texture: Texture2D
@export var idle_region: Rect2 = Rect2()
@export var spritesheet_hframes: int = 1
@export var spritesheet_vframes: int = 1
@export var spritesheet_frame: int = 0

@export_group("Tasks")
@export var offered_task_ids: PackedStringArray = PackedStringArray()
@export var exact_trigger_on_touch: String = ""

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interactable_component: InteractableComponent = $InteractableComponent
@onready var body: StaticBody2D = $StaticBody2D

var _player: Player
var _dialogue_active: bool = false
var _player_in_range: bool = false

func _ready() -> void:
	var frames: SpriteFrames = sprite_frames
	if frames == null and idle_texture != null:
		frames = _build_static_frames()
	if frames:
		animated_sprite.sprite_frames = frames
	animated_sprite.flip_h = default_flip_h
	if frames and frames.has_animation(idle_animation):
		animated_sprite.play(idle_animation)
	interactable_component.interactable_activated.connect(_on_interactable_activated)
	interactable_component.interactable_deactivated.connect(_on_interactable_deactivated)
	interactable_component.area_entered.connect(_on_area_entered)
	interactable_component.area_exited.connect(_on_area_exited)


## Builds a single-frame SpriteFrames from `idle_texture`, optionally
## cropping by spritesheet grid or by `idle_region`. Lets the inspector
## point an NPC at a spritesheet without authoring a SpriteFrames asset.
func _build_static_frames() -> SpriteFrames:
	var tex: Texture2D = idle_texture
	if tex == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = _resolve_region(tex)
	var sf := SpriteFrames.new()
	sf.remove_animation(&"default")
	sf.add_animation(idle_animation)
	sf.set_animation_loop(idle_animation, true)
	sf.add_frame(idle_animation, atlas)
	return sf


func _resolve_region(tex: Texture2D) -> Rect2:
	if idle_region.size.x > 0 and idle_region.size.y > 0:
		return idle_region
	var size: Vector2 = tex.get_size()
	var hf: int = max(spritesheet_hframes, 1)
	var vf: int = max(spritesheet_vframes, 1)
	if hf == 1 and vf == 1:
		return Rect2(Vector2.ZERO, size)
	var cell := Vector2(size.x / float(hf), size.y / float(vf))
	var idx: int = clampi(spritesheet_frame, 0, hf * vf - 1)
	var col: int = idx % hf
	var row: int = idx / hf
	return Rect2(Vector2(col, row) * cell, cell)

func _unhandled_input(event: InputEvent) -> void:
	if interact_mode != InteractMode.KEY_PRESS:
		return
	if not _player_in_range or _dialogue_active:
		return
	if event.is_action_pressed(interact_action):
		get_viewport().set_input_as_handled()
		_start_dialogue()

func _find_player() -> Player:
	if _player:
		return _player
	var nodes := get_tree().get_nodes_in_group("player")
	if nodes.size() > 0 and nodes[0] is Player:
		_player = nodes[0]
	return _player

func _on_interactable_activated() -> void:
	_player_in_range = true
	if exact_trigger_on_touch != "":
		var tm := _task_manager()
		if tm:
			tm.notify_exact_trigger(exact_trigger_on_touch)
	if interact_mode == InteractMode.AUTO_ON_TOUCH:
		_start_dialogue()

func _on_interactable_deactivated() -> void:
	_player_in_range = false

func _on_area_entered(area: Area2D) -> void:
	if area.get_parent() is Player:
		_player_in_range = true

func _on_area_exited(area: Area2D) -> void:
	if area.get_parent() is Player:
		_player_in_range = false

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
