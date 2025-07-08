extends Node2D

@export var targets : Array[Node2D]
@export var root_body : Node2D

func _ready() -> void:
	root_body.connect("h_facing_changed", flip_targets)

func flip_targets(_p_old_dir, _p_new_dir):
	for target in targets:
		target.position.x *= -1
