extends RayCast2D

@export var step_target : Marker2D

func _physics_process(_delta: float) -> void:
	var hit_pos = get_collision_point()
	if hit_pos && !owner.jumping:
		step_target.global_position.y = hit_pos.y
