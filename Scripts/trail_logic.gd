class_name TrailLogic extends Line2D

@export var trail_length : int = 20
@export var trail_vanish_time : float = 0.0025
var trail_extending = true
var trail_delta = 0.0
var current_direction_x = 1
var current_direction_y = 1

func _ready() -> void:
	clear_points()
	
func _physics_process(delta: float) -> void:
	if get_parent() && get_parent() != null:
		if trail_extending:
			add_point(get_parent().global_position)
			if get_point_count() > trail_length:
				remove_point(0)
		else:
			trail_delta += delta
			if get_point_count() > 0:
				if trail_delta > trail_vanish_time:
					remove_point(0)
					trail_delta = 0.0

func set_trail_extending(p_extending):
	trail_extending = p_extending

func flip_trail_x(direction_x):
	if direction_x != current_direction_x:
		position.x *= -1
		current_direction_x = direction_x
	
func flip_trail_y(direction_y):
	if direction_y != current_direction_y:
		position.y *= -1
		current_direction_y = direction_y
