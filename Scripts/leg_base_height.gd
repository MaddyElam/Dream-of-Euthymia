extends Node2D

@export var reference_points : Array[Node2D]
@export var default_pos := Vector2(-63.0, -26.0)
@export var highest_pos := Vector2(-40.0, -110)
@export var lowest_pos := Vector2(-80, 15)
var offset_from_ref := Vector2(0, 0)
var avg_ref_points_pos = Vector2(0, 0)


func _ready() -> void:
	avg_ref_points_pos = ref_point_average(reference_points)
	offset_from_ref = position - avg_ref_points_pos

func _process(_delta: float) -> void:
	avg_ref_points_pos = ref_point_average(reference_points)
	self.position.y = clamp(avg_ref_points_pos.y + offset_from_ref.y, highest_pos.y, lowest_pos.y)

func ref_point_average(p_ref_points):
	var avg_pos = Vector2(0, 0)
	for ref in p_ref_points:
		avg_pos += ref.global_position
	avg_pos = avg_pos/reference_points.size()
	return avg_pos
