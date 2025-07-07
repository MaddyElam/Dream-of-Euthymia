extends Node2D

@export var flippables : Array[Node2D]

func _ready() -> void:
	get_parent().h_facing_changed.connect(on_h_facing_changed)
	get_parent().v_facing_changed.connect(on_v_facing_changed)

func on_h_facing_changed(old_direction, new_direction):
	if old_direction != new_direction:
		for item in flippables:
			if item == null:
				flippables.erase(item)
			else:
				horizontal_flip(item)
				rotation_flip(item)

func on_v_facing_changed(old_direction, new_direction):
	if old_direction != new_direction:
		for item in flippables:
			vertical_flip(item)
			rotation_flip(item)

func horizontal_flip(item):
	if item.position.x != 0:
		item.position.x *= -1
	if item.get_class() == "RayCast2D":
		item.target_position.x *= -1
	if item.get_class() == "Sprite2D":
		item.flip_h = !item.flip_h
	if item.get_class() == "Line2D" && item.get_script() != TrailLogic && item.get_script() != TrailingMovement:
		for point in item.get_point_count():
			item.set_point_position(point, Vector2(item.get_point_position(point).x * -1, item.get_point_position(point).y))
	if item.get_class() == "Polygon2D":
		item.scale.x *= -1

func vertical_flip(item):
	if item.position.y != 0:
		item.position.y *= -1
	if item.get_class() == "RayCast2D":
		item.target_position.y *= -1
	if item.get_class() == "Sprite2D":
		item.flip_v = !item.flip_v

func rotation_flip(item):
	if item.rotation_degrees != 0:
		item.rotation_degrees *= -1
