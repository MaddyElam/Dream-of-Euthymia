extends Line2D

@export var trail_vanish_time : float = 0.0025
var points_clearing = false
var trail_delta = 0.0
var current_direction_x = 1
var current_direction_y = 1

func _ready() -> void:
	clear_points()

func _physics_process(delta: float) -> void:
	if points_clearing:
		trail_delta += delta
		if get_point_count() > 0:
			if trail_delta > trail_vanish_time:
				remove_point(0)
				trail_delta = 0.0
		elif get_point_count() <= 0:
			points_clearing = false

func flip_trail_x(direction_x):
	if direction_x != current_direction_x:
		position.x *= -1
		current_direction_x = direction_x

func flip_trail_y(direction_y):
	if direction_y != current_direction_y:
		position.y *= -1
		current_direction_y = direction_y

func add_new_point(point_pos : Vector2):
	add_point(Vector2(point_pos.x * get_parent().current_h_facing, point_pos.y))

func set_points_clearing(p_clearing : bool):
	points_clearing = p_clearing
