extends GPUParticles2D

var mouse_size_offset = Vector2(16, 16)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	if global_position != mouse_size_offset + get_viewport().get_mouse_position():
		global_position = mouse_size_offset + get_viewport().get_mouse_position()
	
	if emitting && Input.get_last_mouse_velocity() == Vector2(0, 0):
		emitting = false
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		emitting = true
	else:
		emitting = false
