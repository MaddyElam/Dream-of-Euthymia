extends Marker2D

@export var step_target : Marker2D
@export var look_node : Marker2D
@export var max_step_distance : float = 5
@export var adj_target : Node2D
@export var opp_target : Node2D
@export var pre_position : Vector2
@export var step_dist_increment : float = 5
@export var step_height_increment : float = 2.5
@export var max_dist_from_parent : float

var step_height := Vector2(20, -100)
var is_stepping := false
var step_dist_limits := Vector2(5, 150)
var can_step := true
var step_reset := false
var step_multiplier := 1.0


func _process(delta: float) -> void:
	if owner.running && can_step && !is_stepping && abs(global_position.distance_to(step_target.global_position)) > max_step_distance && !adj_target.is_stepping:
		top_level = false
		step()
		if !opp_target.is_stepping:
			opp_target.step()
		is_stepping = true
		step_reset = false
	if can_step && !adj_target.is_stepping && owner.velocity.x == 0:
		reset_step()
		step_reset = true
	
	look_node.global_position = self.global_position + Vector2(10 * owner.current_h_facing, 0)
	#global_position.x = clamp(global_position.x, owner.global_position.x - max_dist_from_parent, owner.global_position.x + max_dist_from_parent)


func step():
	step_height.x = (abs(owner.velocity.x)/step_height_increment)
	var target_pos = step_target.global_position
	var half_point = (global_position + step_target.global_position)/2
	
	var new_tween = get_tree().create_tween()
	new_tween.tween_property(self, "global_position", Vector2(half_point.x + (step_height.x * owner.current_h_facing)/3, half_point.y + step_height.y), 0.1)
	new_tween.tween_property(self, "global_position", Vector2(target_pos.x + (step_height.x * owner.current_h_facing)/2, target_pos.y), 0.2)
	new_tween.connect("finished", on_step_finished)

func on_step_finished():
	var p_global_pos = global_position
	top_level = true
	is_stepping = false
	can_step = false
	adj_target.can_step = true
	global_position = p_global_pos

func reset_step():
	var target_pos = step_target.global_position
	var new_tween = get_tree().create_tween()
	new_tween.tween_property(self, "global_position", target_pos, 0.1)
