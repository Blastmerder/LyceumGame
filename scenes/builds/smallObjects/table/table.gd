extends StaticBody2D

@onready var interactable_component: InteractableComponent = $InteractableComponent
@onready var interact_showcase: Control = $InteractShowcase


func _ready() -> void:
	interact_showcase.hide()
	interactable_component.interactable_activated.connect(on_activated)
	interactable_component.interactable_deactivated.connect(on_deactivated)
	

func on_activated():
	interact_showcase.show()


func on_deactivated():
	interact_showcase.hide()
