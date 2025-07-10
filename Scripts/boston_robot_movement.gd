extends CharacterBody2D

const RUN_SPEED = 1000.0
const SPRINT_SPEED = 1200.0
const DRIFT_JUMP_SPEED = 1500.0
const STARTING_RUN_SPEED = 700.0
const CLIMB_SPEED_X = 0.0
const JUMP_SPEED = 700.0
const WALL_JUMP_SPEED = 500.0
const INJURED_SPEED = 615.0
const REDUCED_JUMP_VELOCITY = -600.0
const FALL_VELOCITY = 1000.0

const JUMP_DECREASE = 100.0
const JUMP_VELOCITY = -800.0
const CLIMB_SPEED_Y = -300.0

const WALL_GRAVITY_DAMPENER = 0.8
const WALL_EDGE_BOOST = Vector2(200, -50)

const ATTACK_COMBO_TIME = 400



@export var speed_curve : Curve
@export var jump_curve : Curve

var running_time := 0.0
var jump_time := 0.0

var jump_velocity := -800.0
var jump_decrease := 100
var jump_increase := -10.0
var jump_increment := 0.0
var max_speed := 800.0

var gravity_multiplier = 1
var gravity_increment = 0.15
var jump_multiplier_min = -15
var jump_multiplier_increment = 15
var jump_multiplier = 1

var current_direction_x = 0
var current_direction_y = 0
var current_h_facing = 1
var old_h_facing = 1


var climbing = false
var running = false
var jumping = false
var rolling = false
var attacking = false
var wall_jumping = false
var injured = false
var injured_anim_finished = false
var dead = false
var knocked_back = false
var delayed_death = false
var idle_1 = false
var idle_2 = false
var stretch = false
var hissing = false
var drifting = false
var delayed_drift = false
var wall_dragging = false
var can_jump = false
var touching_floor = false

signal h_facing_changed(old_direction, new_direction)
signal v_facing_changed(old_direction, new_direction)
signal rolling_started()
signal attacking_started(attack_type, drifting)


var slash_trail
var middle_wall_detector
var ground_particle_raycast
var slope_manager

func _ready() -> void:
	pass

# getters, setters, and resetters
func reset_velocity_y():
	velocity.y = 0

func set_jumping(p_jumping : bool):
	jump_time = 0
	jump_increment = 0.0
	jumping = p_jumping

func add_jump_velocity():
	velocity.y = jump_velocity


func set_h_facing(current_direction):
	if current_direction != 0:
		old_h_facing = current_h_facing
		current_h_facing = current_direction
		if old_h_facing != current_h_facing:
			scale.x *= -1
			h_facing_changed.emit(old_h_facing, current_h_facing)

func set_v_facing(_current_direction):
	v_facing_changed.emit(0,0)


func continuous_movement(event):
	# Events that are continuous (running, climbing, etc)
	# Running
	if (event.is_action_pressed("player_left") || event.is_action_pressed("player_right")) && !rolling:
		if event.is_action_pressed("player_left"):
			current_direction_x = -1
		elif event.is_action_pressed("player_right"):
			current_direction_x = 1
		if !climbing:
			set_h_facing(current_direction_x)
		running = true
		running_time = 0
		drifting = false

	# Diving/Drifting
	if abs(velocity.x) >= max_speed && event.is_action_pressed("player_down") && !injured && !climbing:
		if  is_on_floor() && !jumping:
			drifting = true
			running = false
		else:
			delayed_drift = true


func discontinuous_movement(event):
	# Events that are NOT continuous
	# Jumping
	if event.is_action_pressed("player_space") && is_on_floor() && !climbing:
		set_jumping(true)
		add_jump_velocity()


func input_released(event):
	# For releasing
	if event.is_action_released("player_left") || event.is_action_released("player_right"):
		current_direction_x = Input.get_axis("player_left", "player_right")
		running_time *= 0.5
		if !climbing:
			set_h_facing(current_direction_x)
		if current_direction_x == 0:
			running = false
			running_time = 0
	if event.is_action_released("player_up"):
		if climbing:
			current_direction_y = 0
			reset_velocity_y()
	if event.is_action_released("player_space"):
		if wall_jumping:
			wall_jumping = false
		set_jumping(false)
		velocity.y += jump_decrease
	if event.is_action_released("player_ctrl"):
		current_direction_x = Input.get_axis("player_left", "player_right")
		set_h_facing(current_direction_x)
		if current_direction_x == 0:
			running = false
		climbing = false
		current_direction_y = 0


func _input(event: InputEvent) -> void:
	continuous_movement(event)
	discontinuous_movement(event)
	input_released(event)


func set_velocity_x(current_velocity_x, delta):
	if running && !climbing && !rolling && !attacking && !drifting:
		# Jumping speeds
		if (jumping && is_on_floor()) || (!jumping && !is_on_floor()) || (jumping && !is_on_floor() && !wall_jumping):
			return JUMP_SPEED
		elif wall_jumping && !is_on_floor():
			return WALL_JUMP_SPEED
		# Normal running
		else:
			# If we have not reached top speed,
			if abs(current_velocity_x) < SPRINT_SPEED:
				# And we're not at the starting point for our run speed,
				if abs(current_velocity_x) < STARTING_RUN_SPEED:
					return STARTING_RUN_SPEED
				elif abs(current_velocity_x) < RUN_SPEED:
					# If we are at the proper starting velocity, we can begin to accelerate
					return move_toward(abs(current_velocity_x), RUN_SPEED, 300 * delta)
				elif abs(current_velocity_x) < SPRINT_SPEED:
					return move_toward(abs(current_velocity_x), SPRINT_SPEED, WALL_JUMP_SPEED * delta)
			else:
				# And once we have achieved our sprint speed, we stay there
				return SPRINT_SPEED
	if climbing:
		return CLIMB_SPEED_X
	if injured:
		return INJURED_SPEED
	if !running:
		if jumping && drifting:
			return SPRINT_SPEED
		if !is_on_floor() && velocity.y < 0:
			return move_toward(abs(current_velocity_x), 0, RUN_SPEED * delta)
		else:
			return move_toward(abs(current_velocity_x), 0, RUN_SPEED * delta)
			
	return 0

func _physics_process(delta: float) -> void:
	if running || drifting:
		running_time += delta
		if running:
			running_time = clamp(running_time, 0, 2)
		elif drifting:
			running_time = clamp(running_time, 2, 4)
	
	velocity.x = max_speed * current_direction_x * speed_curve.sample(running_time)
	
	# Add the gravity.
	if !is_on_floor() && !climbing:
		#if get_middle_wall_detected() && running:
			#velocity += get_gravity() * delta * WALL_GRAVITY_DAMPENER
			#if velocity.y < REDUCED_JUMP_VELOCITY:
				#velocity.y -= WALL_EDGE_BOOST.y
		#else:
			velocity += get_gravity() * delta * gravity_multiplier
			# If we're jumping, the gravity should be weaker while going up, and stronger after we reach peak altitude.
			if jumping:
				velocity.y -= jump_multiplier
				if velocity.y < 0:
					if jump_multiplier > jump_multiplier_min:
						jump_multiplier -= delta * jump_multiplier_increment
				else:
					gravity_multiplier += gravity_increment/2
			else:
				gravity_multiplier += gravity_increment
		

	
	
	move_and_slide()
