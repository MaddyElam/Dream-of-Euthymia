extends Node2D

@export var offset : float = 5.0
@export var root_body : Node2D
var previous_position := Vector2(0, 0)

func _ready() -> void:
	previous_position = root_body.global_position

func _process(_delta: float) -> void:
	var velocity = root_body.global_position.x - previous_position.x
	global_position.x = root_body.global_position.x + velocity * offset
	previous_position.x = root_body.global_position.x
