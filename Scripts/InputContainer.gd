class_name InputContainer extends Object

var input_event
var input_time
var input_direction


static func initialize(p_input, p_msec_ticks, p_current_direction_x):
	var new_input_container = InputContainer.new()
	new_input_container.input_event = p_input
	new_input_container.input_time = p_msec_ticks
	new_input_container.input_direction = p_current_direction_x
	return new_input_container
