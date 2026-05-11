class_name EventTrigger
extends InteractableComponent

## InteractableComponent that carries the name of the event it stands
## for. Drop it under an EventTriggersDispatcher and the dispatcher
## will route its `interactable_activated` to
## EventManager.trigger(event_name). The developer is responsible for
## making `event_name` match a GameEvent in the EventsContainer.

@export var event_name: String = ""
