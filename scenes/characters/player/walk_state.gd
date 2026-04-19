extends NodeState

@export var player: Player
@export var animatedSprite2d: AnimatedSprite2D 
@export var speed: int = 99999999
@onready var area_2d: Area2D = $"../../Area2D"

func _on_process(_delta : float) -> void:
	pass 

func _on_physics_process(_delta : float) -> void:
	var direction: Vector2 = GameInputEvents.movement_input()
	
	if Input.is_action_pressed("walk_left"):
		area_2d.position = Vector2(0,0)
		animatedSprite2d.play("walk_left")
	elif Input.is_action_pressed("walk_right"):
		area_2d.position = Vector2(14,0)
		animatedSprite2d.play("walk_right")
	elif Input.is_action_pressed("walk_up"):
		area_2d.position = Vector2(7,-14)
		animatedSprite2d.play("walk_up")
	elif Input.is_action_pressed("walk_down"):
		area_2d.position = Vector2(7,7)
		animatedSprite2d.play("walk_down")
	
	if direction != Vector2.ZERO:
		player.player_direction = direction
	
	player.velocity = direction * speed * _delta
	player.move_and_slide()


func _on_next_transitions() -> void:
	GameInputEvents.movement_input()
	
	if !GameInputEvents.is_movement_input() or player.player_in_dialogue:
		transition.emit("Idle")


func _on_enter() -> void:
	pass


func _on_exit() -> void:
	animatedSprite2d.stop()
