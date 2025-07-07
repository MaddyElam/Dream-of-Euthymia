class_name TrailingMovement extends Line2D

# Trailing Movement logic
@export var root_body : Node2D
@export var flip_body : Node2D
@export var connects_from_line : Line2D
@export var connects_from_point : int
@export var connects_from_object : Node2D
@export var connects_to_line : Line2D
@export var connects_to_point : int
@export var max_length : int = 1
@export var default_pos_max_speed : float = 500
@export var default_pos_min_speed : float = 100
var default_point_positions : Array[Vector2] = []
var offset_from_origin
var current_direction_x = 1
var prior_velocity = Vector2(0, 0)


func _ready() -> void:
	if root_body && root_body != null:
		root_body.h_facing_changed.connect(on_flip_x)
	offset_from_origin = self.get_point_position(0) * current_direction_x
	for point in self.get_point_count():
		default_point_positions.push_back(self.get_point_position(point))
	clear_points()


func on_flip_x(_p_old_direction, p_new_direction):
	current_direction_x = p_new_direction
	offset_from_origin.x *= -1
	clear_points()


func trail_behind():
	if connects_from_line && connects_from_line != null:
		add_point((connects_from_line.get_point_position(connects_from_point) + offset_from_origin + connects_from_line.global_position - connects_from_line.get_point_position(connects_from_point)), 0)
	elif connects_from_object && connects_from_object != null:
		add_point(connects_from_object.global_position + offset_from_origin, 0)
	
	if self.get_point_count() > max_length:
		self.remove_point(self.get_point_count()-1)


func _physics_process(delta: float) -> void:
	if root_body && root_body != null:
		if !root_body.velocity.is_zero_approx():
			trail_behind()
			prior_velocity = root_body.velocity
		else:
			# If we have more points than we're supposed to:
			if self.get_point_count() > max_length:
				self.remove_point(self.get_point_count()-1)
			# If we have fewer points than we're supposed to:
			elif self.get_point_count() < default_point_positions.size():
				if connects_from_line && connects_from_line != null:
					self.add_point((default_point_positions[0] * Vector2(current_direction_x, 1)) + connects_from_line.global_position, 0)
				elif connects_from_object && connects_from_object != null:
					self.add_point((default_point_positions[0] * Vector2(current_direction_x, 1)) + connects_from_object.global_position, 0)
			# Otherwise:
			else:
				for point in self.get_point_count():
					if point < default_point_positions.size():
						if connects_from_line && connects_from_line != null:
							self.set_point_position(point, self.get_point_position(point).move_toward((default_point_positions[point] * Vector2(current_direction_x, 1)) + connects_from_line.global_position, clamp(max(abs(prior_velocity.x), abs(prior_velocity.y)), default_pos_min_speed, default_pos_max_speed) * delta))
						elif connects_from_object && connects_from_object != null:
							self.set_point_position(point, self.get_point_position(point).move_toward((default_point_positions[point] * Vector2(current_direction_x, 1)) + connects_from_object.global_position, clamp(max(abs(prior_velocity.x), abs(prior_velocity.y)), default_pos_min_speed, default_pos_max_speed) * delta))
