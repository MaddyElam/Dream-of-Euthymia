extends CharacterBody2D

@export var player_cat_active: bool = true
@export var player_bird_ref: CharacterBody2D
@export var player_camera_2D : Camera2D

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

var current_direction_x = 0
var current_direction_y = 0
var current_h_facing = 1
var old_h_facing = 1

var gravity_multiplier = 1
var gravity_increment = 0.15
var jump_multiplier_min = -15
var jump_multiplier_increment = 15
var jump_multiplier = 1
var climb_gravity_increment = 5
var climb_gravity_max = 50

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
var wall_dragging = false
var can_jump = false
var touching_floor = false

var can_attack = false
var attack_type = -1
var time_since_last_attack = 0
var flashing = false
var gravity_entered = false

signal h_facing_changed(old_direction, new_direction)
signal v_facing_changed(old_direction, new_direction)
signal rolling_started()
signal attacking_started(attack_type, drifting)

var velocity_y_reset = false
var player_input_enabled = true
var x_movement_reset = true
var respawning = false

var mnvr_rolling : Array[Maneuvers] = [Maneuvers.initialize(1500, 0, 0, 0), Maneuvers.initialize(0, 0, 0.4, 0)]
var mnvr_knockback : Array[Maneuvers] = [Maneuvers.initialize(0, 0, 0, 0), Maneuvers.initialize(0, 0, 0.3, 0)]
var mnvr_attack_fallback : Array[Maneuvers] = [Maneuvers.initialize(-100, 0, 0, 0), Maneuvers.initialize(0, 0, 0.1, 0)]

var mnvr_queue : Array[Maneuvers]
var mnvr_interval_counter = 0
var mnvr_prev = Vector2(0, 0)
var maneuver_finished = true
var stored_velocity_x = 0

var player_bird_node = preload("res://Scenes/Player_Bird.tscn")

var most_recent_spawn = Vector2(0, 0)

var flash_increment = 7
var attack_pause_time = 0.03

var slash_trail
var middle_wall_detector
var ground_particle_raycast
var slope_manager
var paw_ff
var paw_fb
var paw_bf
var paw_bb

var offset_from_paws = 0.0
var avg_paw_pos = Vector2(0, 0)

func _ready() -> void:
	most_recent_spawn = self.global_position
	$Flippables_Container/HealthComponent.injured.connect(on_injured)
	$Flippables_Container/HealthComponent.can_attack.connect(on_can_attack)
	$Flippables_Container/HealthComponent.vulnerable.connect(on_invincible_timeout)
	$Flippables_Container/HealthComponent.health_changed.connect(on_health_changed)
	$Flippables_Container/AttackComponent.can_attack.connect(on_can_attack)
	$Flippables_Container/AttackComponent.cooldown_started.connect(on_attack_cooldown_started)
	$Flippables_Container/HitboxComponent.damage_knockback.connect(on_knockback_force)
	$Flippables_Container/Floor_Detector.floor_collided.connect(on_floor_collided)
	$Flippables_Container/Floor_Detector.floor_departed.connect(on_floor_collided)
	player_bird_ref.bird_death.connect(on_bird_death)
	set_attack_enabled(false)
	can_attack = true
	slash_trail = $Flippables_Container/Slash_Trail
	middle_wall_detector = $Flippables_Container/Middle_Wall_Detector
	ground_particle_raycast = $Flippables_Container/Ground_Particles/RayCast2D
	paw_ff = $"Flippables_Container/BodyContainer/IK Targets/PawFF_Target"
	paw_bb = $"Flippables_Container/BodyContainer/IK Targets/PawBB_Target"
	paw_bf = $"Flippables_Container/BodyContainer/IK Targets/PawBF_Target"
	paw_fb = $"Flippables_Container/BodyContainer/IK Targets/PawFB_Target"


func on_bird_death():
	player_bird_ref = player_bird_node.instantiate()
	self.call_deferred("create_new_bird")
	
	
func create_new_bird():
	self.add_sibling(player_bird_ref)
	player_bird_ref.player_cat_ref = self
	player_bird_ref.global_position = Vector2(self.global_position.x + (player_bird_ref.CAT_POS_OFFSET_X * self.current_h_facing), self.global_position.y + player_bird_ref.CAT_POS_OFFSET_Y)
	player_bird_ref.bird_death.connect(on_bird_death)

func on_floor_adv():
	return (is_on_floor() || touching_floor)

# signal receivers
func on_floor_collided(_body, y_velocity, collided):
	var fall_threshold_1 = 2000
	var fall_threshold_2 = 4000
	var jump_threshold_1 = -600
	var jump_threshold_2 = -900
	
	if collided:
		if y_velocity >= fall_threshold_1 && y_velocity < fall_threshold_2:
			# Shake the camera just a little and add some dust particles
			player_camera_2D.add_trauma(0.1)
		elif y_velocity >= fall_threshold_2:
			# Shake the camera more and add some dirt particles for more impact
			player_camera_2D.add_trauma(0.2)
			player_camera_2D.position_smoothing_speed = 10
		jumping = false
		wall_jumping = false
		touching_floor = true
	else:
		touching_floor = false
		if y_velocity <= jump_threshold_1 && y_velocity > jump_threshold_2 && jumping:
			# Some dust particles
			pass
		elif y_velocity <= jump_threshold_2 && jumping:
			# Dirt particles for more force
			pass

func on_injured(health_remaining):
	player_camera_2D.add_trauma(0.4)
	injured = true
	injured_anim_finished = false
	can_attack = false
	attacking = false
	climbing = false
	set_attack_enabled(false)
	set_hitbox_enabled(false)
	if health_remaining <= 0:
		knocked_back = true
		on_death()
	else:
		set_injured_blinking(true)
	
	$Flippables_Container/BodyContainer.material.set_shader_parameter("flash_opacity", 1)
	flashing = true

func on_invincible_timeout():
	injured = false
	set_injured_blinking(false)

func on_can_attack():
	can_attack = true

func on_attack_cooldown_started():
	get_tree().paused = true
	await get_tree().create_timer(attack_pause_time).timeout
	get_tree().paused = false
	can_attack = false
	attacking = false
	set_attack_enabled(false)
	maneuver_initializer(mnvr_attack_fallback, current_h_facing)
	
func on_knockback_force(p_knockback_force):
	if p_knockback_force != 0:
		velocity.x = 0
		knocked_back = true
		player_input_enabled = false
		running = false
		can_attack = false
		attacking = false
		x_movement_reset = false
		set_attack_enabled(false)
		mnvr_knockback.front().force_x = p_knockback_force
		maneuver_initializer(mnvr_knockback, current_h_facing)
	
func on_death():
	if !knocked_back:
		dead = true
		player_input_enabled = false
		set_attack_enabled(false)
		set_hitbox_enabled(false)
		velocity.x = 0
		slash_trail.set_points_clearing(true)
	else:
		delayed_death = true

func on_health_changed(p_health):
	$Player_Cat_Health.on_player_health_change(p_health)

func on_idle_anim(anim_type):
	if anim_type == 0:
		idle_1 = true
		idle_2 = false
	elif anim_type == 1:
		idle_1 = false
		idle_2 = true
	else:
		idle_1 = false
		idle_2 = false

func respawn_player():
	self.global_position = most_recent_spawn
	running = false
	jumping = false
	attacking = false
	climbing = false
	rolling = false
	dead = false
	injured = false
	can_attack = true
	delayed_death = false
	player_input_enabled = true
	set_attack_enabled(false)
	set_hitbox_enabled(false)
	$Flippables_Container/HealthComponent.reset_health()
	set_injured_blinking(false)
	current_direction_x = 1
	set_h_facing(current_direction_x)
	respawning = true

# getters, setters, and resetters
func reset_gravity_multiplier():
	gravity_multiplier = 1

func reset_jump_multiplier():
	jump_multiplier = 1

func reset_velocity_y():
	velocity.y = 0

func set_jumping(p_jumping : bool):
	jumping = p_jumping

func add_jump_velocity():
	velocity.y = JUMP_VELOCITY

func get_middle_wall_detected():
	return $Flippables_Container/Middle_Wall_Detector.is_colliding()

func get_upper_wall_detected():
	return $Flippables_Container/Upper_Wall_Detector.is_colliding()

func get_trail():
	return slash_trail

func set_h_facing(current_direction):
	if current_direction != 0:
		old_h_facing = current_h_facing
		current_h_facing = current_direction
		if old_h_facing != current_h_facing:
			scale.x *= -1
			h_facing_changed.emit(old_h_facing, current_h_facing)

func set_v_facing(_current_direction):
	v_facing_changed.emit(0,0)

func set_attack_enabled(enabled):
	$Flippables_Container/AttackComponent/CollisionShape2D.set_deferred("disabled", !enabled)
	$Flippables_Container/AttackComponent/CollisionShape2D2.set_deferred("disabled", !enabled)
	$Flippables_Container/AttackComponent/CollisionShape2D3.set_deferred("disabled", !enabled)
	
func set_hitbox_enabled(enabled):
	$Flippables_Container/HitboxComponent/CollisionShape2D.set_deferred("disabled", !enabled)

func set_velocity_x(current_velocity_x, delta):
	if player_input_enabled:
		if running && !climbing && !rolling && !attacking && !drifting:
			# Jumping speeds
			if (jumping && on_floor_adv()) || (!jumping && !on_floor_adv()) || (jumping && !on_floor_adv() && !wall_jumping):
				return JUMP_SPEED
			elif wall_jumping && !on_floor_adv():
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
			if !on_floor_adv() && velocity.y < 0:
				return move_toward(abs(current_velocity_x), 0, RUN_SPEED * delta)
			else:
				return move_toward(abs(current_velocity_x), 0, RUN_SPEED * delta)
			
	return 0

func set_injured_blinking(blinking_status : bool):
	$Flippables_Container/BodyContainer.material.set_shader_parameter("blinking", blinking_status)

func set_attacking(p_attacking : bool):
	attacking = p_attacking

func increment_shader_flash(p_delta):
	var previous_flash_opacity = $Flippables_Container/BodyContainer.material.get_shader_parameter("flash_opacity")
	if previous_flash_opacity > 0.0:
		$Flippables_Container/BodyContainer.material.set_shader_parameter("flash_opacity", previous_flash_opacity - (flash_increment * p_delta))
	elif previous_flash_opacity < 0.0:
		$Flippables_Container/BodyContainer.material.set_shader_parameter("flash_opacity", 0.0)
	else:
		flashing = false

# movement functions
func summon_player_bird(p_bird_target):
	if player_cat_active:
		player_bird_ref.on_bird_summoned(p_bird_target)

func continuous_movement(event):
	# Events that are continuous (running, climbing, etc)
	# Running
	if (event.is_action_pressed("player_left") || event.is_action_pressed("player_right")) && !rolling && player_cat_active:
		if event.is_action_pressed("player_left"):
			current_direction_x = -1
		elif event.is_action_pressed("player_right"):
			current_direction_x = 1
		if !climbing:
			set_h_facing(current_direction_x)
		running = true
		drifting = false
	# Climbing
	if event.is_action_pressed("player_ctrl") && (get_middle_wall_detected() && get_upper_wall_detected())  && player_cat_active:
		climbing = true
		reset_velocity_y()
		reset_gravity_multiplier()
	# Climbing Up Walls	
	if climbing && event.is_action_pressed("player_up") && (get_middle_wall_detected() || get_upper_wall_detected())  && player_cat_active:
		if event.is_action_pressed("player_up") && get_middle_wall_detected():
			current_direction_y = 1
		else:
			current_direction_y = 0
		velocity.y = CLIMB_SPEED_Y * current_direction_y
		velocity_y_reset = false
	# Diving/Drifting
	if abs(velocity.x) >= SPRINT_SPEED && event.is_action_pressed("player_down") && on_floor_adv() && !jumping && !injured && !climbing:
		drifting = true
		running = false


func discontinuous_movement(event):
	# Events that are NOT continuous
	# Jumping
	if event.is_action_pressed("player_space") && on_floor_adv() && !climbing  && player_cat_active:
		jumping = true
		add_jump_velocity()
		reset_gravity_multiplier()
	# Jumping off Walls
	elif event.is_action_pressed("player_space") && (get_middle_wall_detected() || get_upper_wall_detected()) && climbing && player_cat_active:
		current_direction_x = Input.get_axis("player_left", "player_right")
		if current_direction_x == 0:
			running = false
		add_jump_velocity()
		current_direction_y = 1
		reset_gravity_multiplier()
		jumping = true
		climbing = false
		wall_jumping = true
	# Rolling
	if event.is_action_pressed("player_shift")  && player_cat_active && running:
		rolling = true
		maneuver_initializer(mnvr_rolling, current_h_facing)
		x_movement_reset = false
		rolling_started.emit()
		
	# Attacking
	if event.is_action_pressed("player_lmb") && can_attack && player_cat_active && !climbing:
		attacking = true
		set_attack_enabled(true)
		can_attack = false 
		
		if !drifting:
			if Time.get_ticks_msec() - time_since_last_attack < ATTACK_COMBO_TIME && time_since_last_attack != 0:
				attack_type += 1
			else:
				attack_type == -1
			
			if attack_type > 1:
				attack_type = -1
		else:
			attack_type = -1
		
		time_since_last_attack = Time.get_ticks_msec()
		x_movement_reset = false
		attacking_started.emit(attack_type, drifting)


func input_released(event):
	# For releasing
	if event.is_action_released("player_left") || event.is_action_released("player_right")  && player_cat_active:
		current_direction_x = Input.get_axis("player_left", "player_right")
		if !climbing:
			set_h_facing(current_direction_x)
		if current_direction_x == 0:
			running = false
	if event.is_action_released("player_up")  && player_cat_active:
		if climbing:
			current_direction_y = 0
			reset_velocity_y()
	if event.is_action_released("player_space")  && player_cat_active:
		if wall_jumping:
			wall_jumping = false
		jumping = false
		velocity.y += JUMP_DECREASE
		reset_jump_multiplier()
	if event.is_action_released("player_ctrl")  && player_cat_active:
		current_direction_x = Input.get_axis("player_left", "player_right")
		set_h_facing(current_direction_x)
		if current_direction_x == 0:
			running = false
		climbing = false
		current_direction_y = 0
		reset_gravity_multiplier()
	if event.is_action_released("player_lmb") && player_cat_active:
		set_attack_enabled(false)


func _input(event: InputEvent) -> void:
	# Summoning bird
	if event.is_action_pressed("activate_bird") && player_bird_ref && player_bird_ref != null && !dead: 
		pass
	
	if event.is_action_released("activate_bird") && player_bird_ref && player_bird_ref != null && !dead:
		var bird_pointer = (get_viewport().get_screen_transform() * get_viewport().get_canvas_transform()).affine_inverse() * get_viewport().get_mouse_position()
		if player_bird_ref.mnvr_queue.size() <= 0:
			summon_player_bird(bird_pointer)
	
	if mnvr_queue.size() > 0 || attacking || rolling || knocked_back || dead: return
	if !dead && player_input_enabled:
		continuous_movement(event)
		discontinuous_movement(event)
		input_released(event)
	


func maneuver_initializer(p_mnvr, current_dir_x):
	mnvr_queue.append_array(p_mnvr)
	stored_velocity_x = velocity.x
	reset_gravity_multiplier()
	maneuver_finished = false
	player_input_enabled = false
	climbing = false
	jumping = false
	wall_jumping = false
	if attacking:
		rolling = false
	elif rolling:
		attacking = false
		$Flippables_Container/Middle_Wall_Detector.enabled = false
		$Flippables_Container/Upper_Wall_Detector.enabled = false
	if knocked_back:
		current_direction_x = 1
	else:
		current_direction_x = current_dir_x

func _physics_process(delta: float) -> void:
	avg_paw_pos = (paw_bb.global_position + paw_bf.global_position + paw_fb.global_position + paw_ff.global_position)/4
	
	if !attacking && !rolling && !knocked_back:
		if player_input_enabled:
			velocity.x = abs(set_velocity_x(velocity.x, delta)) * current_direction_x
		else:
			velocity.x = set_velocity_x(velocity.x, delta)
	
	# Add the gravity.
	if !is_on_floor() && !climbing && abs(global_position.y - avg_paw_pos.y) > offset_from_paws:
		if get_middle_wall_detected() && running:
			velocity += get_gravity() * delta * WALL_GRAVITY_DAMPENER
			if velocity.y < REDUCED_JUMP_VELOCITY:
				velocity.y -= WALL_EDGE_BOOST.y
		else:
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
		if !get_upper_wall_detected() && get_middle_wall_detected():
			velocity += Vector2(WALL_EDGE_BOOST.x * current_direction_x, WALL_EDGE_BOOST.y)
	elif climbing:
		if !get_upper_wall_detected() || !get_middle_wall_detected():
			current_direction_y = 0
			reset_gravity_multiplier()
			if !velocity_y_reset:
				reset_velocity_y()
				velocity_y_reset = true
		if !get_upper_wall_detected() && !get_middle_wall_detected():
			if !on_floor_adv():
				current_direction_y = 0
				climbing = false
			reset_gravity_multiplier()
			reset_velocity_y()
		velocity.y += delta * gravity_multiplier
		if gravity_multiplier < climb_gravity_max:
			gravity_multiplier += climb_gravity_increment
	else:
		if ground_particle_raycast.get_collision_normal() && !jumping:
			if (ground_particle_raycast.get_collision_normal().x > 0 && current_direction_x == 1) || (ground_particle_raycast.get_collision_normal().x < 0 && current_direction_x == -1):
				velocity.y += get_gravity().y * delta * abs(ground_particle_raycast.get_collision_normal().x) * 100
			
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
	else:
		if mnvr_interval_counter != 0.0:
			mnvr_interval_counter = 0.0
		if !maneuver_finished:
			set_attack_enabled(false)
			set_hitbox_enabled(true)
			attacking = false
			rolling = false
			$Flippables_Container/Middle_Wall_Detector.enabled = true
			$Flippables_Container/Upper_Wall_Detector.enabled = true
			player_input_enabled = true
			reset_gravity_multiplier()
			if Input.is_action_pressed("player_ctrl") && get_middle_wall_detected() && get_upper_wall_detected() && !on_floor_adv() && !wall_jumping:
				climbing = true
				reset_velocity_y()
				reset_gravity_multiplier()
			if knocked_back:
				can_attack = true
				knocked_back = false
			if on_floor_adv():
				current_direction_x = Input.get_axis("player_left", "player_right")
				if current_direction_x == 0:
					running = false
				if !climbing:
					set_h_facing(current_direction_x)
			maneuver_finished = true
		if !x_movement_reset:
			if !(Input.is_action_pressed("player_left") || Input.is_action_pressed("player_right")):
				current_direction_x = 0
				running = false
			else:
				running = true
				drifting = false
			x_movement_reset = true
		if delayed_death:
			on_death()
	
	if flashing:
		increment_shader_flash(delta)
	
	move_and_slide()


func _on_hitbox_component_area_entered(area: Area2D) -> void:
	if area.get_parent() && area.get_parent() != null:
		if area.get_parent().name == "Checkpoint":
			most_recent_spawn = area.global_position
