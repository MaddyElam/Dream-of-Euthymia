class_name Maneuvers extends Object

var force_x : float
var force_y : float
var time_between : float
var rotation_degrees : float

static func initialize(p_force_x, p_force_y, p_time_between, p_rotation_degrees):
	var new_maneuver = Maneuvers.new()
	new_maneuver.force_x = p_force_x
	new_maneuver.force_y = p_force_y
	new_maneuver.time_between = p_time_between
	new_maneuver.rotation_degrees = p_rotation_degrees
	return new_maneuver
