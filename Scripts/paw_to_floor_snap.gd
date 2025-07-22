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
var step_time_limits := Vector2(0.1, 0.2)
var reg_a := -0.000125
var reg_b := 0.2875


func _process(delta: float) -> void:
	if owner.running && can_step && !is_stepping && abs(global_position.distance_to(step_target.global_position)) > max_step_distance && !adj_target.is_stepping:
		var p_global_pos := global_position
		top_level = false
		global_position = p_global_pos
		step()
		if !opp_target.is_stepping:
			opp_target.step()
		is_stepping = true
		step_reset = false
	if can_step && !adj_target.is_stepping && owner.velocity.x == 0:
		reset_step()
		step_reset = true
	
	look_node.global_position = self.global_position + Vector2(10 * owner.current_h_facing, 0)


func step():
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
	adj_target.can_step = true
	top_level = true
	global_position = p_global_pos

func reset_step():
	var target_pos = step_target.global_position
	var new_tween = get_tree().create_tween()
	new_tween.tween_property(self, "global_position", target_pos, 0.1)


func trot_gait():
	return can_step && max_step_distance && !adj_target.is_stepping
