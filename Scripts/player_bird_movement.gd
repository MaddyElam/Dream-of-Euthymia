extends CharacterBody2D

@export var player_bird_active : bool = false
@export var player_cat_ref : CharacterBody2D

const CONTINUOUS_FLAP_SPEED = -800
const FLAP_SPEED_MAXIMUM = -1200
const SOAR_SPEED = 800
const STARTING_FLAP_SPEED = -600
const movement_y_increased_SPEED_X = 200
const movement_y_increased_SPEED_Y = -900
const WALKING_SPEED = 400
const DRIFT_SPEED = -500
const CAT_POS_OFFSET_X = -300
const CAT_POS_OFFSET_Y = -300
const NEWLY_ACTIVE_FLAP_SPEED = -400
const LOOP_TIME_FRAME = 500.0
const BARREL_TIME_FRAME = 250.0
const LOOP_ROTATION_SPEED = 7
const LOOP_COMBO : Array[String] = ["player_right", "player_up", "player_left"]
const LOOP_COMBO_R : Array[String] = ["player_left", "player_up", "player_right"]
const BARREL_COMBO : Array[String] = ["player_right", "player_up", "player_right"]
const BARREL_COMBO_R : Array[String] = ["player_left", "player_up", "player_left"]
const BARREL_SPEED = 1200
const MAXIMUM_CAT_DISTANCE = Vector2(1500, 1500)
const WALL_KNOCKBACK_FORCE = -800
const SUMMONED_X_FORCE = 2500
const SUMMONED_X_BOOST = 4000
const MAXIMUM_SUMMON_TIME = 2000
const SUMMON_BOOST_TIME = 500
const MAX_RETURN_TIME = 2000
const SUMMON_TARGET_MULTIPLIER = 10
const TOTAL_SUMMON_TIME = 5000

var summon_speed = SUMMONED_X_FORCE

var gravity_multiplier = 1
var gravity_increment = 0.15
var flap_multiplier_min = -15
var flap_multiplier_increment = 15
var flap_multiplier = 1
var drift_multiplier = 0.5

var current_direction_x = 0
var current_direction_y = 0
var current_h_facing = 1
var current_v_facing = 1
var old_h_facing = 1
var old_v_facing = 1

var movement_y = false
var injured = false
var movement_x = false
var movement_y_increased = false
var movement_y_decreased = false
var newly_active = false
var dead = false
var looping = false
var barrelling = false
var forced_barrelling = false
var injured_anim_finished = false
var takeoff_landing = false
var knocked_back = false
var delayed_death = false
var summoned = false
var returning = false

var mnvr_loop : Array[Maneuvers] = [Maneuvers.initialize(500, -250, 0, -45), Maneuvers.initialize(250, -500, 0.2, -90), Maneuvers.initialize(-250, -500, 0.1, -135), Maneuvers.initialize(-500, -250, 0.1, -180), Maneuvers.initialize(-500, 250, 0.1, -225), Maneuvers.initialize(-250, 500, 0.05, -300), Maneuvers.initialize(250, 500, 0.05, -330), Maneuvers.initialize(500, 250, 0.05, -360), Maneuvers.initialize(250, 0, 0.5, -360)]
# 	 									approaching 1 right, up	  					approaching 2 right, up						approaching 3 left, up	  					approaching 4 left, up 						approaching 5 left, down   						approaching 6 left, down	  					approaching 7 right,down				approaching 8 right, down (end)
var mnvr_barrel : Array[Maneuvers] = [Maneuvers.initialize(1500, 0, 0, 0), Maneuvers.initialize(0, 0, 1, 0)]

var mnvr_knockback : Array[Maneuvers] = [Maneuvers.initialize(0, 0, 0, 0), Maneuvers.initialize(0, 0, 0.3, 0)]

var mnvr_queue : Array[Maneuvers]
var mnvr_interval_counter = 0
var mnvr_prev = Vector2(0, 0)
var maneuver_finished = false

var position_by_cat = Vector2(0,0)
var player_input_enabled = false
var stored_velocity_x = 0

var input_queue : Array[InputContainer] = []

signal h_facing_changed(old_direction, new_direction)
signal v_facing_changed(old_direction, new_direction)
signal bird_death()

var colliding_with_wall = false
var idle_motion_speed = movement_y_increased_SPEED_Y
var shader_animator

var target_position
var summoned_time = 0

func _ready() -> void:
	$HealthComponent.injured.connect(on_injured)
	$HealthComponent.vulnerable.connect(on_invincible_timeout)
	$HitboxComponent.damage_knockback.connect(on_knockback_force)
	shader_animator = $ShaderAnimationPlayer
	set_attack_enabled(false)
	set_hitbox_enabled(false)

# Signal Receivers
func on_knockback_force(p_knockback_force):
	if p_knockback_force != 0:
		velocity.x = 0
		knocked_back = true
		player_input_enabled = false
		movement_x = false
		mnvr_knockback.front().force_x = p_knockback_force
		maneuver_initializer(mnvr_knockback, current_h_facing)

func on_injured(health_remaining):
	injured = true
	injured_anim_finished = false
	set_hitbox_enabled(false)
	if health_remaining <= 0:
		knocked_back = true
		on_death()

func on_invincible_timeout():
	injured = false
	set_hitbox_enabled(true)
	current_direction_x = Input.get_axis("player_left", "player_right")
	if current_direction_x == 0:
		movement_x = false
		set_h_facing(current_direction_x)
	
func on_death():
	if !knocked_back:
		dead = true
		player_input_enabled = false
		player_cat_ref.player_cat_active = true
		player_cat_ref.player_camera_2D.reparent(player_cat_ref, false)
		player_cat_ref.player_input_enabled = true
		player_cat_ref.player_bird_ref = null
		bird_death.emit()
		self.queue_free()
	else:
		delayed_death = true
	
func on_wall_collision_entered():
	if forced_barrelling && !dead:
		on_death()

# Setters and Getters
func set_h_facing(current_direction):
	if current_direction != 0:
		old_h_facing = current_h_facing
		current_h_facing = current_direction
		if old_h_facing != current_h_facing:
			h_facing_changed.emit(old_h_facing, current_h_facing)

func set_v_facing(current_direction):
	if current_direction != 0:
		old_v_facing = current_v_facing
		current_v_facing = current_direction
		if old_v_facing != current_v_facing:
			v_facing_changed.emit(old_v_facing, current_v_facing)

func set_attack_enabled(enabled):
	$AttackComponent/CollisionShape2D.set_deferred("disabled", !enabled)

func set_hitbox_enabled(enabled):
	$HitboxComponent/CollisionShape2D.set_deferred("disabled", !enabled)
	
func set_collider_enabled(enabled):
	$CollisionShape2D.set_deferred("disabled", !enabled)

func set_trail_enabled(enabled):
	$Trail_Line2D.set_visible(enabled)

func set_player_bird_active(active):
	player_bird_active = active
	player_input_enabled = true
	reset_velocity_y()
	reset_gravity_multiplier()
	reset_flap_multiplier()
	velocity.y += NEWLY_ACTIVE_FLAP_SPEED
	movement_y = false
	newly_active = true
	current_direction_x = Input.get_axis("player_left", "player_right")
	idle_motion_speed = movement_y_increased_SPEED_Y
	set_hitbox_enabled(true)
	$SlopeManager.enabled = true
	
func reset_gravity_multiplier():
	gravity_multiplier = 1

func reset_flap_multiplier():
	flap_multiplier = 1

func reset_velocity_y():
	velocity.y = 0

func set_velocity_x(current_velocity_x, delta):
	if player_input_enabled:
		if maneuver_finished:
			maneuver_finished = false
			return stored_velocity_x
		else:
			if is_on_floor():
				return WALKING_SPEED
			if forced_barrelling:
				return BARREL_SPEED
			if movement_x && takeoff_landing:
				return movement_y_increased_SPEED_X
			elif movement_x && abs(current_velocity_x) < SOAR_SPEED && !movement_y_increased && !movement_y_decreased:
				return move_toward(abs(current_velocity_x), SOAR_SPEED, BARREL_SPEED * delta)
			if movement_x && !movement_y_increased && !movement_y_decreased:
				return SOAR_SPEED
			if movement_y_increased || movement_y_decreased:
				return movement_y_increased_SPEED_X
	else:
		if abs(current_velocity_x) < 50 && player_bird_active && !looping && !barrelling && !summoned:
			player_input_enabled = true
			current_direction_x = Input.get_axis("player_left", "player_right")
			set_h_facing(current_direction_x)
			movement_x = (Input.is_action_pressed("player_left") || Input.is_action_pressed("player_right"))
		elif summoned:
			return BARREL_SPEED
		else:
			return move_toward(current_velocity_x, 0, SOAR_SPEED * delta)
	return 0


# Movement
func continuous_movement(event):
	if event.is_action_pressed("player_space") && player_bird_active:
		input_queue_handler("player_space")
		movement_y = true
		reset_gravity_multiplier()
		reset_flap_multiplier()
		if is_on_floor():
			velocity.y = STARTING_FLAP_SPEED
		else:
			velocity.y = CONTINUOUS_FLAP_SPEED
		if newly_active:
			newly_active = false
	if (event.is_action_pressed("player_left") || event.is_action_pressed("player_right")) && player_bird_active:
		if event.is_action_pressed("player_left"):
			current_direction_x = -1
			input_queue_handler("player_left")
		elif event.is_action_pressed("player_right"):
			current_direction_x = 1
			input_queue_handler("player_right")
		set_h_facing(current_direction_x)
		movement_x = true
		if newly_active:
			newly_active = false
	if(event.is_action_pressed("player_up") && !is_on_floor()):
		input_queue_handler("player_up")
		if movement_y  && velocity.y < 0:
			velocity.y = movement_y_increased_SPEED_Y
			movement_y_increased = true
			if newly_active:
				newly_active = false
		else:
			velocity.y = DRIFT_SPEED
			movement_y_decreased = true
			reset_gravity_multiplier()
			reset_flap_multiplier()
			reset_velocity_y()
			if newly_active:
				newly_active = false

func discontinuous_movement(event):
	if event.is_action_pressed("player_shift"):
		forced_barrelling = true
		current_direction_x = 0
		current_direction_y = 0

func limited_movement(event):
	if (event.is_action_pressed("player_left") || event.is_action_pressed("player_right")) && player_bird_active:
		if event.is_action_pressed("player_left") && current_direction_x == 0:
			current_direction_x = -1
		elif event.is_action_pressed("player_right") && current_direction_x == 0:
			current_direction_x = 1
		current_direction_y = 0
		reset_velocity_y()
		self.rotation_degrees = 0
		set_h_facing(current_direction_x)
		movement_x = true
	if(event.is_action_pressed("player_up") || event.is_action_pressed("player_down")) && player_bird_active:
		if event.is_action_pressed("player_up") && current_direction_y == 0:
			current_direction_y = -1
			self.rotation_degrees = -90 * current_direction_x
		elif event.is_action_pressed("player_down") && current_direction_y == 0:
			current_direction_y = 1
			self.rotation_degrees = 90 * current_direction_x
		current_direction_x = 0
		velocity.y = BARREL_SPEED * current_direction_y
			

func input_released(event):
	if event.is_action_released("player_space") && player_bird_active:
		movement_y = false
		reset_gravity_multiplier()
		reset_flap_multiplier()
		if Input.is_action_pressed("player_up"):
			current_direction_x = Input.get_axis("player_left", "player_right")
			movement_y_decreased = true
	if event.is_action_released("player_left") || event.is_action_released("player_right")  && player_bird_active:
		current_direction_x = Input.get_axis("player_left", "player_right")
		set_h_facing(current_direction_x)
		if current_direction_x == 0:
			movement_x = false
	if event.is_action_released("player_up"):
		movement_y_increased = false
		movement_y_decreased = false

func _input(event: InputEvent) -> void:
	if mnvr_queue.size() > 0 || looping || barrelling: return
	if player_input_enabled && !dead && !forced_barrelling:
		continuous_movement(event)
		discontinuous_movement(event)
		input_released(event)
	elif forced_barrelling:
		limited_movement(event)

func input_queue_handler(event):
	input_queue.append(InputContainer.initialize(event, Time.get_ticks_msec(), current_direction_x))
	if input_queue.size() > 3:
		input_queue.pop_front()
	
	# Loop combo checker
	if event == LOOP_COMBO.back():
		if combo_checker(LOOP_COMBO, LOOP_TIME_FRAME): 
			looping = true
			maneuver_initializer(mnvr_loop, current_h_facing)
	elif event == LOOP_COMBO_R.back():
		if combo_checker(LOOP_COMBO_R, LOOP_TIME_FRAME): 
			looping = true
			maneuver_initializer(mnvr_loop, current_h_facing)
		
	if event == BARREL_COMBO.back():
		if combo_checker(BARREL_COMBO, BARREL_TIME_FRAME): 
			barrelling = true
			maneuver_initializer(mnvr_barrel, current_h_facing)
	elif event == BARREL_COMBO_R.back():
		if combo_checker(BARREL_COMBO_R, BARREL_TIME_FRAME): 
			barrelling = true
			maneuver_initializer(mnvr_barrel, current_h_facing)

func combo_checker(combo : Array, combo_time : float):
	var combo_num = 0
	for input_num in input_queue.size():
		if input_queue[input_num].input_event == combo[input_num]:
			combo_num += 1
	if combo_num == 3:
		if input_queue[2].input_time - input_queue[0].input_time < combo_time:
			return true

func maneuver_initializer(p_mnvr, _current_dir_x):
	mnvr_queue.append_array(p_mnvr)
	stored_velocity_x = velocity.x
	reset_gravity_multiplier()
	maneuver_finished = false
	player_input_enabled = false
	movement_y_increased = false 
	movement_y_decreased = false
	newly_active = false
	movement_y = false
	if looping || barrelling:
		current_direction_x = input_queue.front().input_direction
		set_h_facing(current_direction_x)
		injured = false
		reset_velocity_y()
	elif knocked_back:
		current_direction_x = 1


func inactive_movement(delta):
	movement_y = true
	if player_cat_ref && player_cat_ref != null:
		position_by_cat = Vector2(player_cat_ref.global_position.x + (CAT_POS_OFFSET_X * player_cat_ref.current_h_facing), player_cat_ref.global_position.y + CAT_POS_OFFSET_Y)
	else: 
		position_by_cat = self.global_position
	
	if (self.global_position - position_by_cat).normalized().x < 0:
		current_direction_x = 1
		if summoned:
			if rotation_degrees <= -90 || rotation_degrees >= 90:
				set_h_facing(-1)
			else:
				set_h_facing(1)
		else:
			set_h_facing(current_direction_x)
	elif (self.global_position - position_by_cat).normalized().x > 0:
		current_direction_x = -1
		if summoned:
			if rotation_degrees <= -90 || rotation_degrees >= 90:
				set_h_facing(1)
			else:
				set_h_facing(-1)
		else:
			set_h_facing(current_direction_x)
	else:
		if player_cat_ref && player_cat_ref != null:
			current_direction_x = player_cat_ref.current_h_facing
		set_h_facing(current_direction_x)
		
	if self.global_position != position_by_cat:
		self.global_position = global_position.move_toward(position_by_cat, abs(idle_motion_speed) * delta)
		
	if (abs(self.global_position.x - position_by_cat.x) > 1000 || abs(self.global_position.y - position_by_cat.y) > 1000):
		if colliding_with_wall:
			self.global_position = position_by_cat
			colliding_with_wall = false
			idle_motion_speed = movement_y_increased_SPEED_Y
		elif !summoned:
			idle_motion_speed += 50


func _process(delta: float) -> void:
	if player_bird_active && !summoned:
		if !looping && !barrelling && !knocked_back:
			if player_input_enabled:
				velocity.x = set_velocity_x(velocity.x, delta) * current_direction_x
			else:
				velocity.x = set_velocity_x(velocity.x, delta)
	
		if not is_on_floor() && !forced_barrelling:
			if movement_y_decreased || newly_active:
				velocity += get_gravity() * delta * gravity_multiplier * drift_multiplier
			elif !looping && !barrelling:
				velocity += get_gravity() * delta * gravity_multiplier
				if movement_y && velocity.y > FLAP_SPEED_MAXIMUM:
					velocity.y -= flap_multiplier
					if velocity.y < 0:
						if flap_multiplier > flap_multiplier_min:
							flap_multiplier += delta * flap_multiplier_increment
				else:
					gravity_multiplier += gravity_increment
		elif newly_active:
			newly_active = false
		else:
			if $SlopeManager.collision_normal:
				if ($SlopeManager.collision_normal.x > 0 && current_direction_x == 1) || ($SlopeManager.collision_normal.x < 0 && current_direction_x == -1):
					velocity.y += get_gravity().y * delta * $SlopeManager.slope_modifier
		
		if mnvr_queue.size() > 0:
			mnvr_interval_counter += delta
			if mnvr_queue.front().time_between <  mnvr_interval_counter:
				mnvr_interval_counter = 0.0
				var mnvr = mnvr_queue.pop_front()
				# If the previous command had you going left while the current one is pointing right:
				if mnvr_prev.x < 0 && mnvr.force_x > 0:
					velocity.x += (mnvr.force_x + abs(velocity.x)) * current_direction_x
				# Otherwise, if previously you were going right while the new one is pointed left:
				elif mnvr_prev.x > 0 && mnvr.force_x < 0:
					velocity.x += (mnvr.force_x + (abs(velocity.x) * -1)) * current_direction_x
				else:
					velocity.x += mnvr.force_x * current_direction_x
				# If prev had you going up and now you're going down:
				if mnvr_prev.y < 0 && mnvr.force_y > 0:
					velocity.y += mnvr.force_y + abs(velocity.y)
				# Otherwise, if you were going down and now are going up:
				elif mnvr_prev.y > 0 && mnvr.force_y < 0:
					velocity.y += mnvr.force_y + (abs(velocity.y) * -1)
				else:
					velocity.y += mnvr.force_y
				mnvr_prev = Vector3(mnvr.force_x, mnvr.force_y, mnvr.rotation_degrees)
			if self.rotation != deg_to_rad(mnvr_prev.z) * current_direction_x:
				self.rotation = rotate_toward(deg_to_rad(self.rotation_degrees), deg_to_rad(mnvr_prev.z) * current_direction_x, LOOP_ROTATION_SPEED * delta)
		else:
			if mnvr_interval_counter != 0.0:
				mnvr_interval_counter = 0.0
			if (looping || barrelling || knocked_back):
				looping = false
				barrelling = false
				knocked_back = false
				maneuver_finished = true
				player_input_enabled = true
				current_direction_x = Input.get_axis("player_left", "player_right")
				if current_direction_x == 0:
					movement_x = false
				self.rotation_degrees = 0
				set_h_facing(current_direction_x)
				reset_gravity_multiplier()
			if delayed_death:
				on_death()
	
	elif !player_bird_active && !summoned:
		inactive_movement(delta)
	
	elif summoned:
		#We move toward our desired location.
		if target_position && target_position != null:
			if !(global_position.x == target_position.x && global_position.y == target_position.y) && !returning:
				global_position = global_position.move_toward(target_position, summon_speed * delta)
			
			#After the initial boost, we continue to increase the speed.
			if(Time.get_ticks_msec() - summoned_time >= SUMMON_BOOST_TIME) && summon_speed != SUMMONED_X_FORCE:
				summon_speed = move_toward(summon_speed, SUMMONED_X_FORCE, SUMMONED_X_BOOST * delta)
			
			#Upon either reaching the desired location or running out of time, the raven stops spinning and returns.
			if !returning && (Time.get_ticks_msec() - summoned_time >= MAXIMUM_SUMMON_TIME) || (global_position.x == target_position.x && global_position.y == target_position.y):
				returning = true
				idle_motion_speed = summon_speed/2
				set_attack_enabled(false)
				$Trail_Line2D.set_trail_extending(false)
				$Sparks_GPUParticles2D.emitting = false
				$Trail_Head.visible = false
			
			#We have to maintain a consistent rotation during this return trip
			if returning:
				rotation_degrees = rad_to_deg(global_position.angle_to_point(target_position))
				inactive_movement(delta)
			
			#Once we finish returning, we end the summoning code block and reset the speed.
			if global_position == position_by_cat || Time.get_ticks_msec() - summoned_time >= TOTAL_SUMMON_TIME:
				barrelling = false
				global_position = position_by_cat
				set_v_facing(1)
				rotation_degrees = 0
				summoned = false
				returning = false
				idle_motion_speed = movement_y_increased_SPEED_Y
				set_trail_enabled(false)
				
	move_and_slide()


func _on_wall_floor_detector_body_entered(_body: Node2D) -> void:
	colliding_with_wall = true 
	if forced_barrelling && !dead:
		forced_barrelling = false
		velocity.x = 0 
		on_knockback_force(WALL_KNOCKBACK_FORCE)
		on_injured(0)

func on_bird_summoned(p_target_pos):
	if !summoned:
		$Trail_Line2D.set_trail_extending(true)
		set_trail_enabled(true)
		$Sparks_GPUParticles2D.emitting = true
		$Trail_Head.visible = true
		summoned = true
		barrelling = true
		returning = false
		target_position = p_target_pos
		summoned_time = Time.get_ticks_msec()
		summon_speed = SUMMONED_X_BOOST
		var target_angle = rad_to_deg(global_position.angle_to_point(target_position))
		rotation_degrees = target_angle
		
		if target_angle <= -90 || target_angle >= 90:
			set_v_facing(-1)
			$Trail_Line2D.flip_trail_x(-1)
			$Trail_Line2D.flip_trail_y(-1)
		else:
			set_v_facing(1)
			$Trail_Line2D.flip_trail_x(1)
			$Trail_Line2D.flip_trail_y(1)
		
		set_h_facing(1)
		set_attack_enabled(true)
