extends EnemyBaseMovement

var charging = false
var player_within_attack_range = false
var player_within_charging_range = false
var u_wall_detector
var m_wall_detector
var l_wall_detector
var charge_timer
var charge_wait_time = 5

func _ready() -> void:
	super()
	u_wall_detector = $Upper_Wall_Detector
	m_wall_detector = $Middle_Wall_Detector
	l_wall_detector = $Lower_Wall_Detector
	charge_timer = $Charge_Timer


func set_charging(p_charging : bool):
	charging = p_charging

func set_attack_range_enabled(enabled : bool):
	$Attack_Range/CollisionShape2D.set_deferred("disabled", !enabled)

func set_injured(p_injured : bool):
	injured = p_injured

func on_injured(health_remaining):
	super(health_remaining)
	charging = false
	running = false

func on_invincible_timeout():
	super()
	set_attack_enabled(true)

func on_attack_cooldown_started():
	super()
	charging = false

func on_can_attack():
	super()
	if player_target && player_target != null:
		direct_toward_player_h(player_target)

func on_player_lost():
	if (!charging && !attacking) || ($Upper_Wall_Detector.is_colliding() || $Middle_Wall_Detector.is_colliding() || $Lower_Wall_Detector.is_colliding()):
		player_detected = false

func on_knockback_force(p_knockback_force):
	super(p_knockback_force)
	charging = false
	set_velocity_x(0)

func shake_cam():
	if player_target && player_target != null:
		player_target.player_camera_2D.add_trauma(0.2)

func turn_toward_player():
	if player_target && player_target != null:
		direct_toward_player_h(player_target)

func idle_movement(p_delta):
	current_speed_x = SPEED
	velocity.x = move_toward(velocity.x, current_speed_x * current_direction_x, SPEED_COOLDOWN * p_delta)
	running = true
	if $Upper_Wall_Detector.is_colliding() || $Middle_Wall_Detector.is_colliding() || $Lower_Wall_Detector.is_colliding():
		current_direction_x *= -1
		set_h_facing(current_direction_x)

func move_toward_player_x(p_player_body, _p_delta):
	if !charging && !attacking:
		direct_toward_player_h(p_player_body)
		direct_toward_player_v(p_player_body)
	running = true
	if self.global_position != p_player_body.global_position:
		velocity.x = current_speed_x * current_direction_x


func _physics_process(delta: float) -> void:
	super(delta)
	if player_within_charging_range && !injured && can_move && !knocked_back && !dead:
		charging = true
	
	if u_wall_detector.is_colliding() || m_wall_detector.is_colliding() || l_wall_detector.is_colliding() && charging:
		charging = false
	
	if !injured && can_move && !knocked_back && !dead && mnvr_queue.size() <= 0:
		if player_detected:
			move_toward_player_x(player_target, delta)
		elif !charging && !attacking:
			idle_movement(delta)
	


func _on_charging_range_body_entered(body: Node2D) -> void:
	if player_target && player_target != null:
		if body.name == player_target.name && !injured && !dead:
			charging = true
			player_within_charging_range = true
			charge_timer.wait_time = charge_wait_time
			charge_timer.start()


func _on_attack_range_body_entered(body: Node2D) -> void:
	if player_target && player_target != null:
		if body.name == player_target.name:
			player_within_attack_range = true
			attacking = true
			charging = false


func _on_attack_range_body_exited(body: Node2D) -> void:
	if player_target && player_target != null:
		if body.name == player_target.name:
			player_within_attack_range = false
			attacking = false


func _on_charging_range_body_exited(body: Node2D) -> void:
	if player_target && player_target != null:
		if body.name == player_target.name:
			if !charging || !player_detected:
				player_within_charging_range = false


func _on_charge_timer_timeout() -> void:
	if !attacking && !player_within_attack_range:
		charging = false
