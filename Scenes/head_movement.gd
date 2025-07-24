extends Marker2D

var init_pos = Vector2(12, -44)
var head_x_limits = Vector2(-30, 65)
var head_y_limits = Vector2(-72, 20)
var head_pos_divider = 25
var head_running_y = -25
var reset_pos := false

func _process(delta: float) -> void:
	if owner.running:
		reset_pos = false
		position.x = move_toward(position.x, abs(owner.velocity.x)/head_pos_divider, delta * 10)
		position.y = move_toward(position.y, head_running_y, delta * 10)
	elif !reset_pos:
		reset_pos = true
		var head_tween = get_tree().create_tween()
		head_tween.tween_property(self, "position", init_pos, 0.1)
