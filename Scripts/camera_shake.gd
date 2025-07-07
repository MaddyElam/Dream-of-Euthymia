extends Camera2D

@export var trauma_decay : float = 0.8
@export var max_offset : Vector2 = Vector2(100, 75)
@export var max_rot : float = 0.1
@export var default_offset : Vector2 = Vector2(0, -100)

var trauma : float = 0.0
var trauma_power : int = 2

func _ready() -> void:
	randomize()

func _process(delta: float) -> void:
	if trauma:
		trauma = max(trauma - trauma_decay * delta, 0)
		shake()

func add_trauma(amount : float):
	trauma = min(trauma + amount, 1.0)

func shake():
	var amount = pow(trauma, trauma_power)
	rotation = max_rot * amount * randf_range(-1, 1)
	offset.x = default_offset.x + (max_offset.x * amount * randf_range(-1, 1))
	offset.y = default_offset.y + (max_offset.y * amount * randf_range(-1, 1))
