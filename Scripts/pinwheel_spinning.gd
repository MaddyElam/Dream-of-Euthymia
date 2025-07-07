extends Node2D

const default_speed = 1
var spinning = false

func set_spinning(p_spinning : bool = false):
	spinning = p_spinning

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.get_parent().name == "Player_Cat" && !spinning:
		set_spinning(true)
		if area.get_parent().velocity.x >= 0:
			$AnimationPlayer.play("Spin")
		else:
			$AnimationPlayer.play_backwards("Spin")
		$AnimationPlayer.queue("RESET")
		
