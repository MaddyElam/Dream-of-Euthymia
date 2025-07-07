extends Marker2D

@export var ref_points : Array[Node2D]
@export var y_pos_limits : Vector2
var avg_pos := Vector2(0, 0)

func _ready() -> void:
	avg_pos = ref_point_average(ref_points)

func _process(delta: float) -> void:
	avg_pos = ref_point_average(ref_points)
	global_position.y = clamp(avg_pos.y, y_pos_limits.x, y_pos_limits.y)

func ref_point_average(p_ref_points):
	var avg_pos = Vector2(0, 0)
	for ref in p_ref_points:
		avg_pos += ref.position
	avg_pos = avg_pos/p_ref_points.size()
	return avg_pos
