extends Node2D
class_name VFX_Node

@export var continuous_vfx : bool = false

# Insert all spritesheets for misc vfx that aren't exclusive to a specific character 
# (intended for non_continuous vfx used by multiple entities)

var sprite
var animator

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sprite = $Sprite2D
	animator = $AnimationPlayer
	
func initialize(p_scale, p_h_frames, p_v_frames, p_texture, p_library, p_current_animation, p_pos, p_rot) -> void:
	scale = p_scale
	sprite.hframes = p_h_frames
	sprite.vframes = p_v_frames
	sprite.texture = p_texture
	position = p_pos
	rotation_degrees = p_rot
	animator.current_animation = p_library + p_current_animation

func play_animation(p_anim_name):
	animator.current_animation = p_anim_name
	
func modify_vfx_scale(p_scale_x, p_scale_y):
	sprite.scale = Vector2(p_scale_x, p_scale_y)
	
func modify_vfx_pos(p_pos_x, p_pos_y, p_facing):
	sprite.position = Vector2(p_pos_x * p_facing, p_pos_y)
	
func modify_vfx_rot(p_rot, p_facing):
	sprite.rotation_degrees = p_rot * p_facing

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	if !continuous_vfx:
		self.queue_free()
