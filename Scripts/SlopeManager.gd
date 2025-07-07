extends RayCast2D
class_name SlopeManager

var collision_normal = 0
var slope_modifier = 0
var rotation_reset = false
var rotation_set = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	if self.is_colliding():
		collision_normal = self.get_collision_normal()
		get_parent().rotation_degrees = (collision_normal.x/2) * 100
		slope_modifier = abs(collision_normal.x) * 100
		rotation_reset = false
		
	else:
		if !get_parent().is_on_floor() && !self.is_colliding() && !rotation_reset:
			get_parent().rotation_degrees = 0
			rotation_reset = true
