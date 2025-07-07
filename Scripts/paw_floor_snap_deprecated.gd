extends Node2D

@export var root_body : CharacterBody2D
@export var floor_raycast : RayCast2D
@export var animation_player_node : AnimationPlayer
@export var substr_cutoff : int = 0
@export var look_node : Node2D
@export var connected_bone : Node2D
@export var connected_offset : Vector2 = Vector2(0, 0)
@export var connected_secondary : Node2D
@export var secondary_offset : Vector2 = Vector2(0, 0)
@export var ground_detector_raycast : RayCast2D
@export var front_paws : bool = false
@export var reference_bone : Node2D
var default_look_offset : Vector2
var default_connective_bone_offset : Vector2

var flat_normal = Vector2(0.0, -1.0)

func _ready() -> void:
	default_look_offset = look_node.position
	default_connective_bone_offset = connected_bone.global_position

func set_snapper_active(p_active):
	set_physics_process(p_active)

func _physics_process(delta: float) -> void:
	if ground_detector_raycast.is_colliding() && ground_detector_raycast.get_collision_normal() != flat_normal && !floor_raycast.is_colliding():
		# Downward slope
		if (ground_detector_raycast.get_collision_normal().x > 0 && root_body.current_h_facing == 1) || (ground_detector_raycast.get_collision_normal().x < 0 && root_body.current_h_facing == -1):
			if front_paws:
				animation_player_node.shift_bone_pos(connected_bone, null, Vector2(0, ground_detector_raycast.get_collision_point().y - connected_offset.y/2), null, substr_cutoff, delta/2)
				animation_player_node.shift_bone_pos(connected_secondary, null, Vector2(secondary_offset.x, connected_bone.global_position.y + secondary_offset.y), null, substr_cutoff, delta/2)
			else:
				animation_player_node.shift_bone_pos(connected_bone, null, Vector2(0, default_connective_bone_offset.y + ground_detector_raycast.get_collision_point().y/20), null, substr_cutoff, delta/2)
		# Upward slope
		elif (ground_detector_raycast.get_collision_normal().x > 0 && root_body.current_h_facing == -1) || (ground_detector_raycast.get_collision_normal().x < 0 && root_body.current_h_facing == 1):
			if !front_paws:
				animation_player_node.shift_bone_pos(connected_bone, null, Vector2(0, connected_offset.y + ground_detector_raycast.get_collision_point().y), null, substr_cutoff, delta/2)
			else:
				animation_player_node.shift_bone_pos(connected_bone, null, Vector2(connected_offset.x, connected_bone.to_local(self.global_position).y + connected_offset.y), null, substr_cutoff, delta/2)
				animation_player_node.shift_bone_pos(connected_secondary, null, Vector2(secondary_offset.x, connected_bone.global_position.y + secondary_offset.y), null, substr_cutoff, delta/2)
		animation_player_node.shift_bone_pos(self, look_node, Vector2(0, ground_detector_raycast.get_collision_point().y), default_look_offset + ground_detector_raycast.get_collision_normal(), substr_cutoff, delta)
		animation_player_node.set_anims_reset(false)
