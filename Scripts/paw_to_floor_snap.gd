extends Marker2D

@export var step_target : Marker2D
@export var look_node : Marker2D
@export var max_step_distance : float = 5
@export var adj_target : Node2D
@export var opp_target : Node2D
@export var step_dist_increment : float = 5
@export var step_height_increment : float = 2.5
@export var step_x_multiplier : float = 1
@export var step_y_multiplier : float = 1

var step_height := Vector2(20, -10)
var is_stepping := false
var can_step := true
var step_reset := false
var step_reached := false
var step_time_limits := Vector2(0.1, 0.2)
var reg_a := -0.000125
var reg_b := 0.2875
var starting_run_v := 700.0
var avg_run_v := 1000.0
var sprint_v := 1200.0


func _process(delta: float) -> void:
	if owner.running && can_step && !is_stepping && abs(global_position.distance_to(step_target.global_position)) > max_step_distance && !adj_target.is_stepping:
		# For all gaits
		step()
		if abs(owner.velocity.x) < sprint_v:
			if !opp_target.is_stepping:
				opp_target.step()
		else:
			if !adj_target.is_stepping:
				adj_target.step()
		# For all gaits
		is_stepping = true
		step_reset = false
	if owner.velocity.x == 0 && abs(global_position.distance_to(step_target.global_position)) > max_step_distance:
		reset_step()
		step_reset = true
	
	look_node.global_position = self.global_position + Vector2(10 * owner.current_h_facing, 0)


func step():
	var p_global_pos := global_position
	top_level = false
	global_position = p_global_pos
	step_reached = false
	
	step_height.x = (abs(owner.velocity.x)/step_height_increment)
	var target_pos = step_target.global_position
	var half_point = (global_position + step_target.global_position)/2
	var step_time = clamp(reg_a * abs(owner.velocity.x) + reg_b, step_time_limits.x, step_time_limits.y)
	
	var new_tween = get_tree().create_tween()
	new_tween.tween_property(self, "global_position", Vector2(half_point.x + (step_height.x * owner.current_h_facing) * step_x_multiplier, half_point.y * step_y_multiplier), 0.1)
	new_tween.tween_property(self, "global_position", Vector2(target_pos.x + (step_height.x * owner.current_h_facing), target_pos.y), step_time)
	new_tween.connect("finished", on_step_finished)

func on_step_finished():
	var p_global_pos := global_position
	is_stepping = false
	can_step = false
	step_reached = true
	if abs(owner.velocity.x) >= sprint_v:
		opp_target.can_step = true
	else:
		adj_target.can_step = true
	top_level = true
	global_position = p_global_pos

func reset_step():
	var target_pos = step_target.global_position
	var new_tween = get_tree().create_tween()
	new_tween.tween_property(self, "global_position", target_pos, 0.1)
	new_tween.connect("finished", on_step_reset)

func on_step_reset():
	var p_global_pos := global_position
	is_stepping = false
	can_step = true
	top_level = true
	global_position = p_global_pos
