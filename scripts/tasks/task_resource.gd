class_name TaskResource
extends Resource

enum Kind {
	FUZZY,
	EXACT,
}

@export var id: String
@export var title: String
@export var description: String
@export var kind: Kind = Kind.FUZZY
@export var exact_trigger: String = ""

var accepted: bool = false
var completed: bool = false

func is_fuzzy() -> bool:
	return kind == Kind.FUZZY

func is_exact() -> bool:
	return kind == Kind.EXACT
