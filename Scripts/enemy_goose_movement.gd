extends EnemyBaseMovement

# The stats go in the order: x-pos, y-pos, rotation-degrees
const default_collider_1_stats = Vector3(27, 0, 72)
const rearing_collider_1_stats = Vector3(-92, 28, 0)
const default_collider_2_stats = Vector3(-94, 17, 90)
const rearing_collider_2_stats = Vector3(-75, -56, 0)
const attack_collider_stats = Vector3(0, 0, 90)
const attack_rearing_collider_stats = Vector3(-78, 9, 0)

var player_within_attack_range = false

var initial_sky_position
var goal_sky_position

var swoop_cooldown = 2
var can_swoop = true
var swoop_timer 
var timer_begin = false
var swoop_force_multiplier_x = 1
var swoop_force_multiplier_y = 1

var target_last_location

var wall_detector_l
var wall_detector_r

var mnvr_swoop : Array[Maneuvers] = [Maneuvers.initialize(1, 1, 0, 45), Maneuvers.initialize(1, 1, 0.2, 22.5), Maneuvers.initialize(1, 0, 0.1, 0), Maneuvers.initialize(1, 0, 0.1, -22.5), Maneuvers.initialize(1, 0, 0.1, -45), Maneuvers.initialize(0, 0, 0.2, 0)]
									#steep down, forward					#shallow down, further forward			#midpoint, forward					#no up, further forward						#no up, forward (end)


func _ready() -> void:
	super()
	initial_sky_position = global_position.y
	goal_sky_position = initial_sky_position
	swoop_timer = $Swoop_Cooldown_Timer
	aerial_enemy = true
	wall_detector_l = $Wall_Detector_L
	wall_detector_r = $Wall_Detector_R
	can_attack = true

func on_invincible_timeout():
	super()
	can_attack = true
	set_attack_enabled(true)
	if player_target && player_target != null:
		target_last_location = player_target.global_position

func on_attack_cooldown_started():
	super()
	swoop_timer.wait_time = swoop_cooldown
	swoop_timer.start()
	timer_begin = true

func on_can_attack():
	super()
	if player_target && player_target != null:
		target_last_location = player_target.global_position


func move_collider(p_collider : int, new_stats : Vector3):
	#Normal colliders
	if p_collider == 0:
		$CollisionShape2D.position = Vector2(new_stats.x * -current_h_facing, new_stats.y)
		$CollisionShape2D.rotation_degrees = new_stats.z * -current_h_facing
	if p_collider == 1:
		$CollisionShape2D2.position = Vector2(new_stats.x * -current_h_facing, new_stats.y)
		$CollisionShape2D2.rotation_degrees = new_stats.z * -current_h_facing
	#Attack collider
	if p_collider == 2:
		$AttackComponent/CollisionShape2D.position = Vector2(new_stats.x * -current_h_facing, new_stats.y)
		$AttackComponent/CollisionShape2D.rotation_degrees = new_stats.z * -current_h_facing
	#Hitbox colliders
	if p_collider == 3:
		$HitboxComponent/CollisionShape2D.position = Vector2(new_stats.x * -current_h_facing, new_stats.y)
		$HitboxComponent/CollisionShape2D.rotation_degrees = new_stats.z * -current_h_facing
	if p_collider == 4:
		$HitboxComponent/CollisionShape2D2.position = Vector2(new_stats.x * -current_h_facing, new_stats.y)
		$HitboxComponent/CollisionShape2D2.rotation_degrees = new_stats.z * -current_h_facing

func idle_movement(p_delta):
	velocity.x = move_toward(velocity.x, current_speed_x * current_direction_x, SPEED_COOLDOWN * p_delta)
	if wall_detector_l.is_colliding() || wall_detector_r.is_colliding():
		current_direction_x *= -1
		set_h_facing(current_direction_x)


func _physics_process(delta: float) -> void:
	super(delta)
	
	if mnvr_queue.size() <= 0 && !knocked_back && (global_position.y != initial_sky_position):
		if wall_detector_l.is_colliding() || wall_detector_r.is_colliding():
			goal_sky_position -= 1
		else:
			goal_sky_position = initial_sky_position
		
		global_position.y = move_toward(global_position.y, goal_sky_position, SPEED * delta)
	
	if can_attack && maneuver_finished && player_within_attack_range && can_swoop && mnvr_queue.size() <= 0:
		target_last_location = player_target.global_position
		distance_from_player(mnvr_swoop)
		can_swoop = false
		attacking = true
		maneuver_initializer(mnvr_swoop, current_direction_x)
		
	if !timer_begin && maneuver_finished && mnvr_queue.size() <= 0 && !can_swoop:
		swoop_timer.wait_time = swoop_cooldown
		swoop_timer.start()
		timer_begin = true
		
	if mnvr_queue.size() <= 0:
		move_toward_player_x(player_target, delta)


func _on_attack_range_body_entered(body: Node2D) -> void:
	if player_target && player_target != null:
		if body.name == player_target.name:
			player_within_attack_range = true
			if !attacking && can_swoop && can_attack:
				target_last_location = body.global_position
				distance_from_player(mnvr_swoop)
				attacking = true
				can_swoop = false
				maneuver_initializer(mnvr_swoop, current_direction_x)
				timer_begin = false

func _on_attack_range_body_exited(body: Node2D) -> void:
	if player_target && player_target != null:
		if body.name == player_target.name:
			player_within_attack_range = false
			if mnvr_queue.size() <= 0:
				rotation_degrees = 0

func _on_swoop_cooldown_timer_timeout() -> void:
	can_swoop = true
	timer_begin = false


func distance_from_player(p_mnvr):
	swoop_force_multiplier_x = abs((global_position - target_last_location).normalized().x) * 400
	swoop_force_multiplier_y = abs((global_position - target_last_location).normalized().y) * 500
	
	reset_mnvr(p_mnvr)
	
	for mnvr in p_mnvr:
		mnvr.force_x = mnvr.force_x * swoop_force_multiplier_x
		mnvr.force_y = (mnvr.force_y * swoop_force_multiplier_y) * 1.5
		
func reset_mnvr(p_mnvr):
	for mnvr in p_mnvr:
		if mnvr.force_x != 0:
			mnvr.force_x = mnvr.force_x/abs(mnvr.force_x)
		if mnvr.force_y != 0:
			mnvr.force_y = mnvr.force_y/abs(mnvr.force_y)
