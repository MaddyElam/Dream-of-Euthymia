extends ParallaxLayer

@export var cloud_speed : float = -10

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	self.motion_offset.x += cloud_speed * delta
