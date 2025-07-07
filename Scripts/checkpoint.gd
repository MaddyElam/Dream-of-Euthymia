extends Node2D

var animator
@export var save_animation_name : String = ""

func _ready() -> void:
	animator = $AnimationPlayer

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.get_parent().name == "Player_Cat":
		if area.get_parent().most_recent_spawn != global_position || area.get_parent().respawning:
			run_checkpoint_anim()
			area.get_parent().respawning = false

func run_checkpoint_anim():
	animator.play(save_animation_name)
