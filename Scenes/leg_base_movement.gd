extends Node2D

@export var reference_target_1 : Node2D
@export var reference_target_2 : Node2D
@export var max_ref_target_ys := Vector2(0, 0)

func _process(delta: float) -> void:
	if reference_target_1.global_position.y < max_ref_target_ys.x || reference_target_2.global_position.y < max_ref_target_ys.y:
		global_position.y = min(reference_target_1.global_position.y, reference_target_2.global_position.y)
	elif reference_target_1.global_position.y > max_ref_target_ys.x || reference_target_2.global_position.y > max_ref_target_ys.y:
		global_position.y = max(reference_target_1.global_position.y, reference_target_2.global_position.y)
