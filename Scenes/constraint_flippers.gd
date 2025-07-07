extends Skeleton2D

@export var root_body : Node2D
@export var affected_bones : Array[Node2D]
var degree_offset = -90
var child_degree_offset = 180
var grandchild_degree_offset = -270

func _ready() -> void:
	root_body.connect("h_facing_changed", flip_constraints)
	pass

func flip_constraints(_p_old_dir, _p_new_dir):
	for bone in affected_bones:
		if bone.limit_rotation:
			var prev_dir_deg = bone.constraint_data.rotation_direction_degrees
			bone.constraint_data.rotation_direction_degrees = wrap(prev_dir_deg * -1, -180, 180)
