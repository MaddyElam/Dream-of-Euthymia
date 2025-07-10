extends Marker2D

@export var step_target : Marker2D
@export var look_node : Marker2D
@export var max_step_distance : float = 5
@export var adj_target : Node2D
@export var opp_target : Node2D
@export var pre_position : Vector2
@export var max_dist_from_body : float = 0
@export var run_curve : Curve
@export var curve_multiplier : float = 10
@export var origin_node : Node2D

var current_curve
var step_time := 0.0
var step_height := Vector2(20, -20)
var is_stepping := false
var step_dist_limits := Vector2(5, 150)
var can_step := true
var step_reset := false
var step_multiplier := 1.0
var reached_half_point := false
var target_pos_grabbed := false
var target_pos := Vector2(0, 0)
var halfway_point := Vector2(0, 0)

func _ready() -> void:
	current_curve = run_curve


func _process(delta: float) -> void:
	global_position.x = clamp(global_position.x, abs(origin_node.global_position.x) - max_dist_from_body, abs(origin_node.global_position.x) + max_dist_from_body)
	
	if owner.running && can_step && abs(global_position.distance_to(step_target.global_position)) > max_step_distance && !adj_target.is_stepping:
		is_stepping = true
		step(delta)
		if !opp_target.is_stepping:
			opp_target.step(delta)
		step_reset = false
	if can_step && !adj_target.is_stepping && owner.velocity.x == 0:
		reset_step()
		step_reset = true
	
	look_node.global_position = self.global_position + Vector2(10 * owner.current_h_facing, 0)


func step(p_delta):
	if !target_pos_grabbed:
		target_pos = step_target.global_position
		halfway_point = ((global_position + step_target.global_position)/2)
		target_pos_grabbed = true
	
	step_time += p_delta
	step_time = clamp(step_time, 0, 1)
	
	if !reached_half_point:
		if global_position.x != halfway_point.x:
			global_position.x = move_toward(global_position.x, halfway_point.x, p_delta * 1000)
			global_position.y = global_position.y + current_curve.sample(step_time) * curve_multiplier
			print(global_position)
		else:
			print("Halfway point reached")
			reached_half_point = true
	elif global_position != step_target.global_position:
		global_position = global_position.move_toward(step_target.global_position, p_delta * 1000)
	else:
		on_step_finished()


func on_step_finished():
	reached_half_point = false
	is_stepping = false
	can_step = false
	adj_target.can_step = true
	target_pos_grabbed = false

func reset_step():
	var target_pos = step_target.global_position
	var new_tween = get_tree().create_tween()
	new_tween.tween_property(self, "global_position", target_pos, 0.1)
