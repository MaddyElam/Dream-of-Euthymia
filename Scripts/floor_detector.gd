extends Area2D

@export var parent_node : CharacterBody2D

signal floor_collided(collided_body, y_velocity, collided)
signal floor_departed(departed_body, y_velocity, collided)


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Terrain":
		floor_collided.emit(body, parent_node.velocity.y, true)


func _on_body_exited(body: Node2D) -> void:
	if body.name == "Terrain":
		floor_departed.emit(body, parent_node.velocity.y, false)
