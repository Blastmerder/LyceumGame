extends Node2D

@onready var stairs_1_up: InteractableComponent = $"stairs1-up"

@onready var floor1: Node2D = $Lycium1Floor
@onready var floor2: Node2D
@onready var floor3: Node2D
@onready var floor4: Node2D
@onready var floors_node: Node = $floors
@onready var ledder_part: Node2D = $LedderPart

@onready var player: Player = $Player

var floors = [floor1, floor2, floor3, floor4]
var cur_floorID = 0

func _ready() -> void:
	stairs_1_up.interactable_activated.connect(go_to_ladder)
	

func go_to_ladder():
	floors_node.visible = false
	ledder_part.visible = true


	
