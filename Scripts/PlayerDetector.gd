extends Area2D
class_name PlayerDetector

signal player_detected(player_target)
signal player_lost()

var player_target


func _on_detection_range_body_entered(body: Node2D) -> void:
	if player_target && player_target != null:
		if body.name == player_target.name:
			player_detected.emit(body)

func _on_detection_range_body_exited(body: Node2D) -> void:
	if player_target && player_target != null:
		if body.name == player_target.name:
			player_lost.emit()
